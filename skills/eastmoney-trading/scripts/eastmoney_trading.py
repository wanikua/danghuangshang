#!/usr/bin/env python3
"""
东方财富证券交易技能（CDP 连接版）

支持功能：
- 🔐 自动登录 + 验证码识别
- 📊 持仓查询
- 📈 持仓分析
- 📈 买入操作
- 📉 卖出操作
- ❌ 撤单操作
- 📋 委托查询
- 💰 资金查询

⚠️ 安全警告:
- 请勿将密码明文存储在脚本中
- 使用环境变量 EASTMONEY_ACCOUNT 和 EASTMONEY_PASSWORD
- 建议在本地运行，不要上传到云端
- 自动化登录和交易可能触发风控，请谨慎使用
- 交易操作涉及真实资金，务必谨慎

Usage:
    # 登录 + 持仓查询
    export EASTMONEY_ACCOUNT=your_account
    export EASTMONEY_PASSWORD=your_password
    python3 eastmoney_trading.py login
    
    # 买入
    python3 eastmoney_trading.py buy --stock-code 600519 --price 1850 --quantity 100
    
    # 卖出
    python3 eastmoney_trading.py sell --stock-code 600519 --price 1850 --quantity 100
    
    # 撤单（指定委托编号）
    python3 eastmoney_trading.py cancel --order-id 12345678
    
    # 撤单（指定股票）
    python3 eastmoney_trading.py cancel --stock-code 600519
    
    # 查询当日委托
    python3 eastmoney_trading.py orders
    
    # 查询历史委托
    python3 eastmoney_trading.py orders --type history
    
    # 查询资金
    python3 eastmoney_trading.py balance

CDP 配置:
    export EASTMONEY_CDP_URL=http://localhost:9222/  # 可选，默认使用 openclaw.json 配置
"""

import os
import sys
import json
import time
import base64
import io
import argparse
import logging
import re
import requests
from datetime import datetime
from pathlib import Path
from typing import Optional, Dict, List, Any

from playwright.sync_api import sync_playwright, TimeoutError as PlaywrightTimeout, Page

# ============================================================================
# 日志配置
# ============================================================================

# 技能根目录
SKILL_DIR = Path(__file__).parent.parent
LOGS_DIR = SKILL_DIR / "logs"

# 按天创建日志文件夹
TODAY = datetime.now().strftime("%Y-%m-%d")
TODAY_LOG_DIR = LOGS_DIR / TODAY
TODAY_LOG_DIR.mkdir(parents=True, exist_ok=True)

# 日志文件路径
LOG_FILE = TODAY_LOG_DIR / f"eastmoney_trading_{datetime.now().strftime('%H%M%S')}.log"

# 配置日志
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] [%(levelname)s] %(message)s',
    datefmt='%H:%M:%S',
    handlers=[
        logging.FileHandler(LOG_FILE, encoding='utf-8'),
        logging.StreamHandler(sys.stderr)
    ]
)
logger = logging.getLogger(__name__)

# 截图目录
SCREENSHOTS_DIR = TODAY_LOG_DIR / "screenshots"
SCREENSHOTS_DIR.mkdir(parents=True, exist_ok=True)


def save_screenshot(page: Page, name: str, description: str = "") -> str:
    """保存页面截图"""
    timestamp = datetime.now().strftime("%H%M%S")
    filename = f"{timestamp}_{name}.png"
    filepath = SCREENSHOTS_DIR / filename
    
    try:
        page.screenshot(path=str(filepath), full_page=False)
        logger.info(f"📸 已保存截图：{filename} - {description}")
        return str(filepath)
    except Exception as e:
        logger.error(f"截图失败：{filename} - {e}")
        return ""


# ============================================================================
# OCR 相关（可选）
# ============================================================================

try:
    from PIL import Image
    import pytesseract
    OCR_AVAILABLE = True
    logger.info("✓ PIL/pytesseract 已安装，OCR 功能可用")
except ImportError:
    OCR_AVAILABLE = False
    logger.warning("PIL/pytesseract 未安装，OCR 功能将禁用")

# 大模型验证码识别（可选）
try:
    import urllib.request
    import urllib.error
    
    BAILIAN_API_KEY = os.environ.get("BAILIAN_API_KEY", "")
    DASHSCOPE_API_KEY = os.environ.get("DASHSCOPE_API_KEY", "")
    ALIBABA_CLOUD_API_KEY = os.environ.get("ALIBABA_CLOUD_API_KEY", "")
    
    API_KEY = BAILIAN_API_KEY or DASHSCOPE_API_KEY or ALIBABA_CLOUD_API_KEY
    LLM_OCR_AVAILABLE = bool(API_KEY)
    
    if LLM_OCR_AVAILABLE:
        logger.info("✓ 大模型 API Key 已配置，LLM OCR 功能可用")
    else:
        logger.info("大模型 API Key 未设置，LLM OCR 功能禁用")
except ImportError:
    LLM_OCR_AVAILABLE = False
    logger.warning("LLM OCR 库未安装")

# ============================================================================
# CDP 配置
# ============================================================================

CDP_URL = os.environ.get("EASTMONEY_CDP_URL", "http://localhost:9222/")
LOGIN_URL = "https://jywg.18.cn/"
TIMEOUT = 30000  # 30 秒

# 交易相关 URL
BUY_URL = "https://jywg.18.cn/Trade/Buy"
SELL_URL = "https://jywg.18.cn/Trade/Sell"
CANCEL_URL = "https://jywg.18.cn/Trade/Cancel"
POSITION_URL = "https://jywg.18.cn/Stock/Position"
ORDERS_URL = "https://jywg.18.cn/Stock/Order"  # 委托查询
BALANCE_URL = "https://jywg.18.cn/Stock/Asset"  # 资金查询

# 条件选股 URL（无需登录）
XUANGU_URL = "https://xuangu.eastmoney.com/?color=w&type=stock"


# ============================================================================
# 辅助函数
# ============================================================================

def get_credentials():
    """从环境变量或.env 文件获取账号密码"""
    account = os.environ.get("EASTMONEY_ACCOUNT", "")
    password = os.environ.get("EASTMONEY_PASSWORD", "")
    
    if not account or not password:
        env_file = SKILL_DIR / '.env'
        if env_file.exists():
            logger.info(f"从 .env 文件加载配置...")
            try:
                with open(env_file, 'r') as f:
                    for line in f:
                        line = line.strip()
                        if line and not line.startswith('#') and '=' in line:
                            key, value = line.split('=', 1)
                            if key.strip() == 'EASTMONEY_ACCOUNT':
                                account = value.strip()
                            elif key.strip() == 'EASTMONEY_PASSWORD':
                                password = value.strip()
            except Exception as e:
                logger.error(f"读取.env 文件失败：{e}")
    
    if not account or not password:
        logger.error("❌ 未找到账号密码")
        logger.error("请设置环境变量:")
        logger.error("  export EASTMONEY_ACCOUNT=your_account")
        logger.error("  export EASTMONEY_PASSWORD=your_password")
        sys.exit(1)
    
    return account, password


def recognize_captcha_with_llm(image_bytes: bytes) -> str:
    """使用大模型 API 识别验证码图片（通义千问 VL）"""
    if not LLM_OCR_AVAILABLE:
        logger.warning("LLM OCR: API Key 未设置")
        return ""
    
    try:
        img_base64 = base64.b64encode(image_bytes).decode('utf-8')
        url = "https://dashscope.aliyuncs.com/api/v1/services/aigc/multimodal-generation/generation"
        
        payload = {
            "model": "qwen3-vl-plus-2025-12-19",
            "input": {
                "messages": [
                    {
                        "role": "user",
                        "content": [
                            {"image": f"data:image/png;base64,{img_base64}"},
                            {"text": "这是一张验证码图片，请识别图片中的字符。验证码只包含数字和大写英文字母。请直接输出识别结果，不要有任何解释或额外文字。"}
                        ]
                    }
                ]
            },
            "parameters": {"temperature": 0.01, "max_tokens": 10}
        }
        
        data = json.dumps(payload).encode('utf-8')
        req = urllib.request.Request(
            url, data=data,
            headers={'Content-Type': 'application/json', 'Authorization': f'Bearer {API_KEY}'}
        )
        
        logger.info("正在调用大模型识别验证码...")
        
        with urllib.request.urlopen(req, timeout=30) as response:
            result = json.loads(response.read().decode('utf-8'))
            content = None
            
            if 'output' in result and 'choices' in result.get('output', {}):
                content = result['output']['choices'][0].get('message', {}).get('content')
            elif 'output' in result and 'text' in result['output']:
                content = result['output']['text']
            elif 'choices' in result:
                content = result['choices'][0].get('message', {}).get('content')
            
            if content:
                if isinstance(content, list):
                    text_parts = [item if isinstance(item, str) else item.get('text', '') for item in content]
                    content = ' '.join(text_parts)
                
                captcha = str(content).strip().upper().replace(' ', '').replace('\n', '')
                logger.info(f"LLM OCR 识别结果：{captcha} (原始：{content})")
                
                if 3 <= len(captcha) <= 6:
                    logger.info("✓ LLM OCR 识别成功")
                    return captcha
                else:
                    logger.warning(f"识别结果长度异常：{len(captcha)}")
            else:
                logger.error(f"响应格式异常：{result}")
        
        return ""
    
    except urllib.error.HTTPError as e:
        error_body = e.read().decode() if hasattr(e, 'read') else ''
        logger.error(f"LLM OCR HTTP 错误：{e.code} - {e.reason} - {error_body}")
        return ""
    except Exception as e:
        logger.error(f"LLM OCR 识别失败：{type(e).__name__} - {e}")
        return ""


def recognize_captcha(image_bytes: bytes) -> str:
    """使用 OCR 识别验证码图片（优先使用大模型，降级到 Tesseract）"""
    # 优先使用大模型识别
    if LLM_OCR_AVAILABLE:
        captcha = recognize_captcha_with_llm(image_bytes)
        if captcha:
            return captcha
    
    # 大模型失败时，尝试 Tesseract
    if OCR_AVAILABLE:
        try:
            image = Image.open(io.BytesIO(image_bytes))
            image = image.convert('L')  # 转灰度
            image = image.point(lambda x: 0 if x < 128 else 255, '1')  # 二值化
            
            config = '--psm 6 -c tessedit_char_whitelist=0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            text = pytesseract.image_to_string(image, lang='eng', config=config)
            
            captcha = text.strip().replace(' ', '').replace('\n', '').upper()
            logger.info(f"Tesseract OCR 识别结果：{captcha} (原始：{text.strip()})")
            
            if 4 <= len(captcha) <= 6:
                logger.info("✓ Tesseract OCR 识别成功")
                return captcha
            else:
                logger.warning(f"识别结果长度异常：{len(captcha)}")
        except Exception as e:
            logger.error(f"Tesseract OCR 识别失败：{e}")
    
    logger.error("❌ 所有验证码识别方案都失败")
    return ""


def solve_captcha_with_ocr(page: Page) -> str:
    """检测并自动识别验证码（东方财富专用）"""
    captcha_img = None
    
    # 方式 1：查找验证码输入框附近的图片
    try:
        captcha_input = page.locator('#txtValidCode, input[placeholder*="验证码"]').first
        if captcha_input.is_visible(timeout=2000):
            parent = captcha_input.locator('..')
            images = parent.locator('img').all()
            if images:
                captcha_img = images[0]
                logger.info("找到验证码图片（父元素内）")
    except Exception as e:
        logger.debug(f"方式 1 失败：{e}")
    
    # 方式 2：使用通用选择器
    if not captcha_img:
        captcha_selectors = [
            'img[src*="YZM"]', 'img[src*="captcha"]', 'img[src*="code"]',
            'img[src*="validate"]', '.captcha-img', '#captchaImg', 'img.captcha',
        ]
        
        for selector in captcha_selectors:
            try:
                locator = page.locator(selector).first
                if locator.is_visible(timeout=2000):
                    captcha_img = locator
                    logger.info(f"找到验证码图片：{selector}")
                    break
            except:
                continue
    
    if not captcha_img:
        logger.warning("未找到验证码图片")
        return ""
    
    try:
        screenshot = captcha_img.screenshot()
        captcha_img.screenshot(path=str(SCREENSHOTS_DIR / "captcha_debug.png"))
        logger.info(f"验证码截图已保存：captcha_debug.png")
        
        captcha = recognize_captcha(screenshot)
        return captcha
    
    except Exception as e:
        logger.error(f"获取验证码失败：{e}")
        return ""


# ============================================================================
# 核心功能：登录
# ============================================================================

def connect_browser(cdp_url: str = None):
    """连接浏览器并返回 page 对象"""
    cdp_url = cdp_url or CDP_URL
    
    import re
    import urllib.request
    
    host_match = re.search(r'http://([^:/]+)', cdp_url)
    host = host_match.group(1) if host_match else "127.0.0.1"
    
    # 获取 WebSocket URL
    ws_url = None
    try:
        version_url = cdp_url.rstrip('/') + '/json/version'
        with urllib.request.urlopen(version_url, timeout=5) as resp:
            version_data = json.loads(resp.read().decode())
            ws_url = version_data.get('webSocketDebuggerUrl', '')
            ws_url = ws_url.replace('ws://127.0.0.1/', f'ws://{host}:9222/')
            logger.info(f"WebSocket URL: {ws_url}")
    except Exception as e:
        logger.warning(f"获取 WebSocket URL 失败：{e}")
    
    logger.info(f"正在连接远程浏览器...")
    
    playwright = sync_playwright().start()
    
    if ws_url:
        browser = playwright.chromium.connect_over_cdp(ws_url)
    else:
        browser = playwright.chromium.connect_over_cdp(cdp_url)
    
    logger.info("✓ 连接成功！")
    
    contexts = browser.contexts
    if contexts:
        context = contexts[0]
        logger.info("使用现有浏览器上下文")
    else:
        context = browser.new_context(
            viewport={'width': 1920, 'height': 1080},
            user_agent='Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/133.0.0.0 Safari/537.36'
        )
        logger.info("创建新浏览器上下文")
    
    pages = context.pages
    if pages:
        page = pages[0]
        logger.info("使用现有页面")
    else:
        page = context.new_page()
        logger.info("创建新页面")
    
    return playwright, browser, context, page


def login(page: Page, account: str, password: str) -> bool:
    """
    登录东方财富
    
    Returns:
        bool: 登录成功返回 True
    """
    logger.info(f"正在访问东方财富交易网站...")
    page.goto(LOGIN_URL, timeout=TIMEOUT)
    page.wait_for_load_state('networkidle')
    save_screenshot(page, "login_page", "登录页面")
    
    # 检查是否已经登录
    try:
        if page.locator('a:has-text("退出"), .logout-btn').is_visible(timeout=2000):
            logger.info("✓ 检测到已登录会话")
            return True
    except:
        pass
    
    logger.info("等待登录表单加载...")
    
    # 查找账号输入框
    account_selectors = [
        'input[placeholder="请输入资金账号"]', 'input[name="account"]',
        'input[placeholder="账号"]', '#account', '.input-account',
    ]
    
    account_input = None
    for selector in account_selectors:
        try:
            account_input = page.locator(selector).first
            if account_input.is_visible():
                logger.info(f"找到账号输入框：{selector}")
                break
        except:
            continue
    
    if not account_input:
        logger.error("❌ 未找到账号输入框")
        save_screenshot(page, "login_failed", "登录失败 - 未找到账号框")
        return False
    
    # 输入账号
    logger.info("输入账号...")
    account_input.fill(account)
    page.wait_for_timeout(500)
    
    # 查找密码输入框
    password_selectors = [
        'input[placeholder="请输入交易密码"]', 'input[type="password"]',
        'input[name="password"]', '#password',
    ]
    
    password_input = None
    for selector in password_selectors:
        try:
            password_input = page.locator(selector).first
            if password_input.is_visible():
                logger.info(f"找到密码输入框：{selector}")
                break
        except:
            continue
    
    if not password_input:
        logger.error("❌ 未找到密码输入框")
        return False
    
    # 输入密码
    logger.info("输入密码...")
    password_input.fill(password)
    page.wait_for_timeout(500)
    
    # 检查验证码
    captcha_input = page.locator('#txtValidCode, input[placeholder*="验证码"]').first
    if captcha_input.is_visible(timeout=3000):
        logger.warning("⚠️ 检测到验证码")
        captcha_code = solve_captcha_with_ocr(page)
        if captcha_code:
            logger.info(f"✓ 填写验证码：{captcha_code}")
            captcha_input.fill(captcha_code)
        else:
            logger.error("❌ 验证码识别失败")
            save_screenshot(page, "captcha_failed", "验证码识别失败")
            return False
    
    # 登录
    logger.info("点击登录...")
    login_button = page.locator('button[type="submit"], .login-btn').first
    if login_button.is_visible():
        login_button.click()
    else:
        password_input.press('Enter')
    page.wait_for_timeout(5000)
    
    # 验证登录
    if page.locator('a:has-text("退出")').is_visible(timeout=3000):
        logger.info("✓ 登录成功！")
        save_screenshot(page, "login_success", "登录成功")
        return True
    else:
        logger.error("❌ 登录可能失败")
        save_screenshot(page, "login_failed", "登录失败")
        return False


# ============================================================================
# 核心功能：持仓查询
# ============================================================================

def get_position(page: Page) -> Optional[Dict]:
    """获取持仓信息"""
    logger.info("正在获取持仓信息...")
    
    # 尝试导航到持仓页面
    position_found = False
    menu_selectors = ['a:has-text("资金持仓")', 'a:has-text("持仓")', 'div:has-text("资金持仓")']
    
    for selector in menu_selectors:
        try:
            locator = page.locator(selector).first
            if locator.is_visible(timeout=2000):
                logger.info(f"找到持仓菜单：{selector}")
                locator.click()
                page.wait_for_timeout(5000)
                page.wait_for_load_state('networkidle')
                position_found = True
                break
        except Exception as e:
            logger.debug(f"尝试 {selector} 失败：{e}")
    
    if not position_found:
        logger.warning("⚠️ 未找到持仓菜单")
    
    save_screenshot(page, "position_page", "持仓页面")
    
    # 提取持仓数据
    position_data = extract_position_data(page)
    
    if position_data and position_data.get('positions'):
        logger.info(f"✓ 成功获取 {len(position_data['positions'])} 条持仓记录")
    else:
        logger.warning("⚠️ 未获取到持仓数据")
    
    return position_data


def extract_position_data(page: Page) -> Dict:
    """从持仓页面提取数据"""
    import re
    
    result = {
        'total_asset': None,
        'available': None,
        'market_value': None,
        'profit': None,
        'positions': [],
    }
    
    try:
        logger.info("提取资金汇总信息...")
        
        # 总资产
        total_asset_locator = page.locator('text=总资产').first
        if total_asset_locator.is_visible(timeout=3000):
            parent = total_asset_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['total_asset'] = float(numbers[0].replace(',', ''))
                logger.info(f"总资产：{result['total_asset']}")
        
        # 可用资金
        available_locator = page.locator('text=可用资金').first
        if available_locator.is_visible(timeout=2000):
            parent = available_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['available'] = float(numbers[0].replace(',', ''))
                logger.info(f"可用资金：{result['available']}")
        
        # 证券市值
        market_value_locator = page.locator('text=证券市值').first
        if market_value_locator.is_visible(timeout=2000):
            parent = market_value_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['market_value'] = float(numbers[0].replace(',', ''))
                logger.info(f"证券市值：{result['market_value']}")
        
        # 持仓盈亏
        profit_locator = page.locator('text=持仓盈亏').first
        if profit_locator.is_visible(timeout=2000):
            parent = profit_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'-?[\d,]+\.?\d*', text)
            if numbers:
                result['profit'] = float(numbers[0].replace(',', ''))
                logger.info(f"持仓盈亏：{result['profit']}")
        
        # 提取持仓表格
        logger.info("提取持仓明细...")
        position_rows = page.locator('table tbody tr').all()
        
        for row in position_rows:
            try:
                cells = row.locator('td').all()
                if len(cells) >= 10:
                    code = cells[0].text_content().strip() if len(cells) > 0 else ''
                    name = cells[1].text_content().strip() if len(cells) > 1 else ''
                    
                    if not code or code == '证券代码' or not name:
                        continue
                    
                    if not re.match(r'^\d{5,6}$', code):
                        continue
                    
                    position = {
                        'code': code,
                        'name': name,
                        'volume': cells[2].text_content().strip() if len(cells) > 2 else '',
                        'available_volume': cells[3].text_content().strip() if len(cells) > 3 else '',
                        'cost_price': cells[4].text_content().strip() if len(cells) > 4 else '',
                        'current_price': cells[5].text_content().strip() if len(cells) > 5 else '',
                        'market_value': cells[6].text_content().strip() if len(cells) > 6 else '',
                        'profit': cells[7].text_content().strip() if len(cells) > 7 else '',
                        'profit_rate': cells[8].text_content().strip() if len(cells) > 8 else '',
                    }
                    
                    result['positions'].append(position)
                    logger.info(f"持仓：{code} {name}")
                    
            except Exception as e:
                logger.debug(f"解析行失败：{e}")
                continue
        
        logger.info(f"共提取 {len(result['positions'])} 条持仓记录")
        
    except Exception as e:
        logger.error(f"提取持仓数据失败：{type(e).__name__} - {e}")
    
    return result


def format_position_output(data: Dict) -> str:
    """格式化持仓信息输出"""
    if not data or not data.get('positions'):
        return "❌ 未获取到持仓数据"
    
    output = ["📊 东方财富持仓信息", "=" * 60]
    
    if data.get('total_asset'):
        output.append(f"💰 总资产：¥{data['total_asset']:,.2f}")
    if data.get('available'):
        output.append(f"💵 可用金额：¥{data['available']:,.2f}")
    if data.get('market_value'):
        output.append(f"📈 持仓市值：¥{data['market_value']:,.2f}")
    if data.get('profit'):
        profit_emoji = "🟢" if data['profit'] > 0 else "🔴"
        output.append(f"{profit_emoji} 总盈亏：¥{data['profit']:,.2f}")
    
    output.extend(["", "📋 持仓明细:", "-" * 60])
    
    for pos in data['positions']:
        profit_emoji = "🟢" if float(pos.get('profit', 0) or 0) > 0 else "🔴"
        output.append(f"\n{pos.get('code', '')} {pos.get('name', '')}")
        output.append(f"   持仓：{pos.get('volume', '')}股")
        output.append(f"   成本：¥{pos.get('cost_price', '')} | 现价：¥{pos.get('current_price', '')}")
        output.append(f"   市值：¥{pos.get('market_value', '')}")
        output.append(f"   {profit_emoji} 盈亏：¥{pos.get('profit', '')} ({pos.get('profit_rate', '')})")
    
    output.extend(["", "=" * 60, "💡 提示：数据仅供参考，请以实际账户为准"])
    
    return "\n".join(output)


# ============================================================================
# 持仓分析功能（从 eastmoney-portfolio 整合）
# ============================================================================

def get_secid(stock_code: str) -> str:
    """转换股票代码为东方财富 secid 格式"""
    code = stock_code.strip()
    if code.startswith('sh'):
        return f"1.{code.replace('sh', '')}"
    elif code.startswith('sz'):
        return f"0.{code.replace('sz', '')}"
    elif code.startswith('6') or code.startswith('5'):
        return f"1.{code}"  # 上海
    else:
        return f"0.{code}"  # 深圳


def fetch_stock_price(stock_code: str, retry: int = 2) -> Optional[Dict]:
    """
    获取股票实时行情（东方财富 API）
    
    注意：东方财富 API 价格单位：
    - 股票（600xxx, 000xxx, 300xxx）：返回的是"分"，需要除以 100
    - ETF 基金（15xxxx, 51xxxx, 52xxxx）：返回的是"厘"，需要除以 1000
    
    Args:
        stock_code: 股票代码
        retry: 重试次数（默认 2 次）
    """
    secid = get_secid(stock_code)
    url = f"http://push2.eastmoney.com/api/qt/stock/get?secid={secid}&fields=f43,f44,f45,f46,f47,f48,f58,f60,f170,f171"
    
    # 判断证券类型，确定价格除数
    is_etf = stock_code.startswith('15') or stock_code.startswith('51') or stock_code.startswith('52')
    price_divisor = 1000 if is_etf else 100
    
    for attempt in range(retry + 1):
        try:
            response = requests.get(url, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            if data.get('data') and data['data'].get('f58'):
                result = data['data']
                return {
                    'code': secid.split('.')[1],
                    'name': result.get('f58', ''),
                    'price': result.get('f43', 0) / price_divisor,
                    'open': result.get('f46', 0) / price_divisor,
                    'high': result.get('f44', 0) / price_divisor,
                    'low': result.get('f45', 0) / price_divisor,
                    'pre_close': result.get('f60', 0) / price_divisor,
                    'change': result.get('f170', 0) / price_divisor,
                    'change_percent': result.get('f171', 0) / 100,
                    'volume': result.get('f47', 0),
                    'amount': result.get('f48', 0),
                }
            else:
                logger.warning(f"API 返回无数据：{stock_code}")
                return None
                
        except requests.exceptions.RequestException as e:
            if attempt < retry:
                logger.debug(f"获取行情失败 {stock_code}，重试 {attempt + 1}/{retry}: {e}")
                time.sleep(0.5 * (attempt + 1))  # 递增延迟
            else:
                logger.warning(f"获取行情失败 {stock_code}（已重试{retry}次）: {e}")
        except Exception as e:
            logger.warning(f"获取行情失败 {stock_code}: {e}")
            return None
    
    return None


def fetch_batch_stock_prices(stock_codes: List[str]) -> Dict[str, Dict]:
    """
    批量获取股票行情（串行请求，更可靠）
    
    Args:
        stock_codes: 股票代码列表
    
    Returns:
        Dict: 行情数据字典
    """
    results = {}
    
    # 串行请求，避免并发导致的网络问题
    for code in stock_codes[:50]:
        result = fetch_stock_price(code, retry=3)  # 增加重试次数到 3 次
        if result:
            results[code] = result
            logger.debug(f"✓ 获取行情成功：{code} - {result['name']} ¥{result['price']:.3f}")
        else:
            logger.warning(f"获取行情失败：{code}")
        time.sleep(0.3)  # 请求间隔，避免被封
    
    return results


def analyze_portfolio(positions: List[Dict], market_data: Dict[str, Dict]) -> Dict:
    """分析持仓结构"""
    total_market_value = 0
    total_cost = 0
    total_profit = 0
    stock_details = []
    
    for pos in positions:
        code = pos['code']
        volume = int(pos.get('volume', 0) or 0)
        cost_price = float(pos.get('cost_price', 0) or 0)
        
        market = market_data.get(code, {})
        current_price = market.get('price', 0)
        change_percent = market.get('change_percent', 0)
        name = market.get('name', pos.get('name', ''))
        
        market_value = current_price * volume
        cost = cost_price * volume
        profit = market_value - cost
        profit_percent = (profit / cost * 100) if cost > 0 else 0
        
        total_market_value += market_value
        total_cost += cost
        total_profit += profit
        
        stock_details.append({
            'code': code,
            'name': name,
            'volume': volume,
            'cost_price': cost_price,
            'current_price': current_price,
            'change_percent': change_percent,
            'market_value': market_value,
            'profit': profit,
            'profit_percent': profit_percent,
            'weight': 0,
        })
    
    # 计算权重
    for detail in stock_details:
        detail['weight'] = (detail['market_value'] / total_market_value * 100) if total_market_value > 0 else 0
    
    # 持仓集中度
    sorted_by_weight = sorted(stock_details, key=lambda x: x['weight'], reverse=True)
    top3_weight = sum(s['weight'] for s in sorted_by_weight[:3])
    
    return {
        'total_market_value': total_market_value,
        'total_cost': total_cost,
        'total_profit': total_profit,
        'total_profit_percent': (total_profit / total_cost * 100) if total_cost > 0 else 0,
        'stock_count': len(positions),
        'top3_weight': top3_weight,
        'stock_details': stock_details,
        'update_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    }


def generate_trading_suggestions(analysis: Dict) -> List[str]:
    """生成交易建议"""
    suggestions = []
    
    # 持仓集中度风险
    if analysis['top3_weight'] > 70:
        suggestions.append(f"⚠️ 持仓集中度过高：前 3 大持仓占比 {analysis['top3_weight']:.1f}%，建议适当分散风险")
    elif analysis['top3_weight'] < 30:
        suggestions.append("✅ 持仓分散度良好")
    
    # 整体盈亏
    if analysis['total_profit_percent'] > 20:
        suggestions.append("🎉 整体盈利超过 20%，考虑是否止盈部分仓位")
    elif analysis['total_profit_percent'] > 5:
        suggestions.append("📈 整体盈利，可继续持有观察")
    elif analysis['total_profit_percent'] > -10:
        suggestions.append("📊 小幅亏损，建议检查持仓逻辑是否改变")
    else:
        suggestions.append("⚠️ 亏损超过 10%，建议复盘买入逻辑，考虑止损或补仓")
    
    # 个股建议
    for stock in analysis['stock_details']:
        if stock['profit_percent'] > 30:
            suggestions.append(f"💰 {stock['name']}({stock['code']}) 盈利超 30%，可考虑分批止盈")
        elif stock['profit_percent'] < -20:
            suggestions.append(f"🛑 {stock['name']}({stock['code']}) 亏损超 20%，建议检查基本面是否恶化")
        
        if stock['weight'] > 40:
            suggestions.append(f"⚠️ {stock['name']}({stock['code']}) 单只持仓超 40%，风险集中")
    
    # 持仓数量
    if analysis['stock_count'] > 15:
        suggestions.append(f"📋 持仓数量 {analysis['stock_count']} 只，可能过于分散，建议聚焦核心标的")
    elif analysis['stock_count'] < 3:
        suggestions.append(f"🎯 持仓数量 {analysis['stock_count']} 只，集中度较高，注意风险")
    
    if not suggestions:
        suggestions.append("✅ 持仓结构健康，继续跟踪")
    
    return suggestions


def format_analysis_report(analysis: Dict, suggestions: List[str]) -> str:
    """格式化分析报告输出"""
    lines = []
    lines.append("📊 **东方财富持仓分析报告**")
    lines.append(f"📅 更新时间：{analysis['update_time']}")
    lines.append("")
    
    # 总体概览
    lines.append("## 📈 总体概览")
    lines.append(f"- 持仓数量：{analysis['stock_count']} 只")
    lines.append(f"- 总市值：¥{analysis['total_market_value']:,.2f}")
    lines.append(f"- 总成本：¥{analysis['total_cost']:,.2f}")
    profit_emoji = "🎉" if analysis['total_profit'] > 0 else "📉"
    lines.append(f"- 总盈亏：{profit_emoji} ¥{analysis['total_profit']:,.2f} ({analysis['total_profit_percent']:+.2f}%)")
    lines.append(f"- 前 3 大持仓占比：{analysis['top3_weight']:.1f}%")
    lines.append("")
    
    # 个股详情
    lines.append("## 📋 持仓明细")
    lines.append("")
    
    sorted_stocks = sorted(analysis['stock_details'], key=lambda x: x['market_value'], reverse=True)
    
    for i, stock in enumerate(sorted_stocks, 1):
        profit_emoji = "🟢" if stock['profit'] > 0 else "🔴" if stock['profit'] < 0 else "⚪"
        change_emoji = "📈" if stock['change_percent'] > 0 else "📉" if stock['change_percent'] < 0 else "➡️"
        
        lines.append(f"**{i}. {stock['name']}({stock['code']})**")
        lines.append(f"   - 持仓：{stock['volume']} 股 | 市值：¥{stock['market_value']:,.2f} | 占比：{stock['weight']:.1f}%")
        lines.append(f"   - 成本：¥{stock['cost_price']:.2f} | 现价：¥{stock['current_price']:.2f} | {change_emoji} {stock['change_percent']:+.2f}%")
        lines.append(f"   - 盈亏：{profit_emoji} ¥{stock['profit']:,.2f} ({stock['profit_percent']:+.2f}%)")
        lines.append("")
    
    # 交易建议
    lines.append("## 💡 交易建议")
    lines.append("")
    for sug in suggestions:
        lines.append(f"- {sug}")
    
    lines.append("")
    lines.append("---")
    lines.append("⚠️ **风险提示**：以上分析仅供参考，不构成投资建议。股市有风险，投资需谨慎。")
    
    return '\n'.join(lines)


def analyze_position(page: Page, position_data: Dict) -> Optional[Dict]:
    """
    对持仓进行深入分析（获取实时行情 + 生成建议）
    
    Args:
        page: Playwright page 对象
        position_data: 持仓数据
    
    Returns:
        分析结果字典
    """
    if not position_data or not position_data.get('positions'):
        logger.warning("⚠️ 无持仓数据可供分析")
        return None
    
    logger.info("📡 正在获取实时行情...")
    stock_codes = [pos['code'] for pos in position_data['positions']]
    market_data = fetch_batch_stock_prices(stock_codes)
    
    logger.info(f"✓ 成功获取 {len(market_data)}/{len(stock_codes)} 只股票行情")
    
    # 转换持仓数据格式
    positions_for_analysis = []
    for pos in position_data['positions']:
        positions_for_analysis.append({
            'code': pos['code'],
            'name': pos.get('name', ''),
            'volume': int(pos.get('volume', 0) or 0),
            'cost_price': float(pos.get('cost_price', 0) or 0),
        })
    
    # 分析持仓
    logger.info("🔍 正在分析持仓结构...")
    analysis = analyze_portfolio(positions_for_analysis, market_data)
    
    # 生成建议
    suggestions = generate_trading_suggestions(analysis)
    
    # 保存分析结果
    analysis_result = {
        'analysis': analysis,
        'suggestions': suggestions,
        'market_data': market_data,
    }
    
    # 保存 JSON 文件
    analysis_file = TODAY_LOG_DIR / f"analysis_{datetime.now().strftime('%H%M%S')}.json"
    with open(analysis_file, 'w', encoding='utf-8') as f:
        json.dump(analysis_result, f, ensure_ascii=False, indent=2)
    logger.info(f"📄 分析结果已保存：{analysis_file}")
    
    return analysis_result


# ============================================================================
# 核心功能：买入
# ============================================================================

def buy_stock(page: Page, stock_code: str, price: float, quantity: int, order_type: str = "limit") -> bool:
    """
    买入股票
    
    Args:
        page: Playwright page 对象
        stock_code: 股票代码
        price: 委托价格
        quantity: 委托数量
        order_type: 委托类型（limit=限价，market=市价）
    
    Returns:
        bool: 交易成功返回 True
    """
    logger.info(f"📈 开始买入操作：{stock_code} @ {price} x {quantity} ({order_type})")
    save_screenshot(page, "before_buy", "买入前页面")
    
    try:
        # 导航到买入页面
        logger.info("导航到买入页面...")
        page.goto(BUY_URL, timeout=TIMEOUT)
        page.wait_for_load_state('networkidle')
        save_screenshot(page, "buy_page", "买入页面")
        
        # 输入股票代码
        logger.info(f"输入股票代码：{stock_code}")
        stock_input = page.locator('input[placeholder*="代码"], #stockCode, input[name="stockCode"]').first
        stock_input.fill(stock_code)
        page.wait_for_timeout(1000)
        save_screenshot(page, "buy_stock_input", f"输入股票代码：{stock_code}")
        
        # 输入委托价格（限价委托）
        if order_type == "limit":
            logger.info(f"输入委托价格：{price}")
            price_input = page.locator('input[placeholder*="价格"], #price, input[name="price"]').first
            price_input.fill(str(price))
            page.wait_for_timeout(500)
        
        # 输入委托数量
        logger.info(f"输入委托数量：{quantity}")
        quantity_input = page.locator('input[placeholder*="数量"], #quantity, input[name="quantity"]').first
        quantity_input.fill(str(quantity))
        page.wait_for_timeout(500)
        save_screenshot(page, "buy_order_input", f"买入委托输入：{stock_code} @ {price} x {quantity}")
        
        # 确认买入
        logger.info("确认买入...")
        buy_button = page.locator('button:has-text("买入"), button:has-text("提交"), .buy-btn').first
        if buy_button.is_visible():
            buy_button.click()
            page.wait_for_timeout(3000)
            
            # 处理确认对话框
            try:
                confirm_button = page.locator('button:has-text("确定"), button:has-text("确认"), .confirm-btn').first
                if confirm_button.is_visible(timeout=2000):
                    logger.info("点击确认按钮...")
                    confirm_button.click()
                    page.wait_for_timeout(2000)
            except:
                logger.debug("无需确认对话框")
            
            save_screenshot(page, "buy_confirm", "买入确认")
            
            # 检查是否成功
            try:
                success_msg = page.locator('text=成功, text=已报，text=委托成功').first
                if success_msg.is_visible(timeout=3000):
                    logger.info(f"✓ 买入委托成功！")
                    save_screenshot(page, "buy_success", "买入成功")
                    return True
            except:
                pass
            
            # 检查错误信息
            try:
                error_msg = page.locator('.error, .alert, text=失败，text=错误').first
                if error_msg.is_visible(timeout=2000):
                    error_text = error_msg.text_content()
                    logger.error(f"❌ 买入失败：{error_text}")
                    save_screenshot(page, "buy_error", f"买入失败：{error_text}")
                    return False
            except:
                pass
            
            logger.warning("⚠️ 买入结果不明确，请检查委托记录")
            return True  # 假设成功，让用户检查委托记录
        else:
            logger.error("❌ 未找到买入按钮")
            return False
            
    except PlaywrightTimeout as e:
        logger.error(f"❌ 超时错误：{e}")
        save_screenshot(page, "buy_timeout", "买入超时")
        return False
    except Exception as e:
        logger.error(f"❌ 买入失败：{type(e).__name__} - {e}")
        save_screenshot(page, "buy_error", f"买入异常：{e}")
        return False


# ============================================================================
# 核心功能：卖出
# ============================================================================

def sell_stock(page: Page, stock_code: str, price: float, quantity: int, order_type: str = "limit") -> bool:
    """
    卖出股票
    
    Args:
        page: Playwright page 对象
        stock_code: 股票代码
        price: 委托价格
        quantity: 委托数量
        order_type: 委托类型（limit=限价，market=市价）
    
    Returns:
        bool: 交易成功返回 True
    """
    logger.info(f"📉 开始卖出操作：{stock_code} @ {price} x {quantity} ({order_type})")
    save_screenshot(page, "before_sell", "卖出前页面")
    
    try:
        # 导航到卖出页面
        logger.info("导航到卖出页面...")
        page.goto(SELL_URL, timeout=TIMEOUT)
        page.wait_for_load_state('networkidle')
        save_screenshot(page, "sell_page", "卖出页面")
        
        # 输入股票代码
        logger.info(f"输入股票代码：{stock_code}")
        stock_input = page.locator('input[placeholder*="代码"], #stockCode, input[name="stockCode"]').first
        stock_input.fill(stock_code)
        page.wait_for_timeout(1000)
        
        # 自动填充可卖数量（卖出页面通常会自动显示）
        page.wait_for_timeout(1000)
        save_screenshot(page, "sell_stock_input", f"输入股票代码：{stock_code}")
        
        # 输入委托价格（限价委托）
        if order_type == "limit":
            logger.info(f"输入委托价格：{price}")
            price_input = page.locator('input[placeholder*="价格"], #price, input[name="price"]').first
            price_input.fill(str(price))
            page.wait_for_timeout(500)
        
        # 输入委托数量
        logger.info(f"输入委托数量：{quantity}")
        quantity_input = page.locator('input[placeholder*="数量"], #quantity, input[name="quantity"]').first
        quantity_input.fill(str(quantity))
        page.wait_for_timeout(500)
        save_screenshot(page, "sell_order_input", f"卖出委托输入：{stock_code} @ {price} x {quantity}")
        
        # 确认卖出
        logger.info("确认卖出...")
        sell_button = page.locator('button:has-text("卖出"), button:has-text("提交"), .sell-btn').first
        if sell_button.is_visible():
            sell_button.click()
            page.wait_for_timeout(3000)
            
            # 处理确认对话框
            try:
                confirm_button = page.locator('button:has-text("确定"), button:has-text("确认"), .confirm-btn').first
                if confirm_button.is_visible(timeout=2000):
                    logger.info("点击确认按钮...")
                    confirm_button.click()
                    page.wait_for_timeout(2000)
            except:
                logger.debug("无需确认对话框")
            
            save_screenshot(page, "sell_confirm", "卖出确认")
            
            # 检查是否成功
            try:
                success_msg = page.locator('text=成功，text=已报，text=委托成功').first
                if success_msg.is_visible(timeout=3000):
                    logger.info(f"✓ 卖出委托成功！")
                    save_screenshot(page, "sell_success", "卖出成功")
                    return True
            except:
                pass
            
            # 检查错误信息
            try:
                error_msg = page.locator('.error, .alert, text=失败，text=错误').first
                if error_msg.is_visible(timeout=2000):
                    error_text = error_msg.text_content()
                    logger.error(f"❌ 卖出失败：{error_text}")
                    save_screenshot(page, "sell_error", f"卖出失败：{error_text}")
                    return False
            except:
                pass
            
            logger.warning("⚠️ 卖出结果不明确，请检查委托记录")
            return True  # 假设成功，让用户检查委托记录
        else:
            logger.error("❌ 未找到卖出按钮")
            return False
            
    except PlaywrightTimeout as e:
        logger.error(f"❌ 超时错误：{e}")
        save_screenshot(page, "sell_timeout", "卖出超时")
        return False
    except Exception as e:
        logger.error(f"❌ 卖出失败：{type(e).__name__} - {e}")
        save_screenshot(page, "sell_error", f"卖出异常：{e}")
        return False


# ============================================================================
# 核心功能：撤单
# ============================================================================

def cancel_order(page: Page, order_id: str = None, stock_code: str = None) -> bool:
    """
    撤销委托
    
    Args:
        page: Playwright page 对象
        order_id: 委托编号（可选，指定则撤销单笔）
        stock_code: 股票代码（可选，指定则撤销该股票所有未成交委托）
    
    Returns:
        bool: 撤单成功返回 True
    """
    logger.info(f"❌ 开始撤单操作：order_id={order_id}, stock_code={stock_code}")
    save_screenshot(page, "before_cancel", "撤单前页面")
    
    try:
        # 导航到撤单页面
        logger.info("导航到撤单页面...")
        page.goto(CANCEL_URL, timeout=TIMEOUT)
        page.wait_for_load_state('networkidle')
        save_screenshot(page, "cancel_page", "撤单页面")
        
        # 等待委托列表加载
        page.wait_for_timeout(3000)
        
        # 如果有委托编号，查找并撤销该笔委托
        if order_id:
            logger.info(f"查找委托编号：{order_id}")
            
            # 在表格中查找委托编号
            order_row = page.locator(f'text={order_id}').first
            if order_row.is_visible(timeout=3000):
                logger.info(f"找到委托：{order_id}")
                
                # 点击该行的撤单按钮
                cancel_btn = order_row.locator('button:has-text("撤单"), .cancel-btn').first
                if cancel_btn.is_visible():
                    logger.info("点击撤单按钮...")
                    cancel_btn.click()
                    page.wait_for_timeout(2000)
                    
                    # 处理确认对话框
                    try:
                        confirm_button = page.locator('button:has-text("确定"), button:has-text("确认"), .confirm-btn').first
                        if confirm_button.is_visible(timeout=2000):
                            logger.info("点击确认按钮...")
                            confirm_button.click()
                            page.wait_for_timeout(2000)
                    except:
                        logger.debug("无需确认对话框")
                    
                    save_screenshot(page, "cancel_confirm", "撤单确认")
                    
                    # 检查是否成功
                    try:
                        success_msg = page.locator('text=成功，text=已受理，text=撤单成功').first
                        if success_msg.is_visible(timeout=3000):
                            logger.info(f"✓ 撤单成功！")
                            save_screenshot(page, "cancel_success", "撤单成功")
                            return True
                    except:
                        pass
                    
                    logger.warning("⚠️ 撤单结果不明确，请检查委托状态")
                    return True
                else:
                    logger.error("❌ 未找到撤单按钮（可能已成交）")
                    return False
            else:
                logger.error(f"❌ 未找到委托编号：{order_id}")
                return False
        
        # 如果没有指定委托编号，列出所有可撤的委托
        else:
            logger.info("获取可撤销委托列表...")
            
            # 查找委托表格
            order_rows = page.locator('table tbody tr').all()
            cancellable_orders = []
            
            for row in order_rows:
                try:
                    cells = row.locator('td').all()
                    if len(cells) >= 8:
                        oid = cells[0].text_content().strip() if len(cells) > 0 else ''
                        code = cells[2].text_content().strip() if len(cells) > 2 else ''
                        name = cells[3].text_content().strip() if len(cells) > 3 else ''
                        status = cells[6].text_content().strip() if len(cells) > 6 else ''
                        
                        # 只处理未成交的委托
                        if oid and '已报' in status and '成交' not in status:
                            cancellable_orders.append({
                                'order_id': oid,
                                'stock_code': code,
                                'stock_name': name,
                                'status': status
                            })
                except Exception as e:
                    logger.debug(f"解析委托行失败：{e}")
            
            if cancellable_orders:
                logger.info(f"找到 {len(cancellable_orders)} 笔可撤销委托:")
                for order in cancellable_orders:
                    logger.info(f"  {order['order_id']} - {order['stock_code']} {order['stock_name']} ({order['status']})")
                
                # 如果指定了股票代码，只撤销该股票的委托
                if stock_code:
                    target_orders = [o for o in cancellable_orders if o['stock_code'] == stock_code]
                    if not target_orders:
                        logger.warning(f"⚠️ 未找到股票 {stock_code} 的可撤销委托")
                        return False
                    cancellable_orders = target_orders
                
                # 撤销所有可撤委托
                success_count = 0
                for order in cancellable_orders:
                    logger.info(f"正在撤销委托：{order['order_id']} - {order['stock_code']} {order['stock_name']}")
                    
                    try:
                        order_row = page.locator(f'text={order["order_id"]}').first
                        cancel_btn = order_row.locator('button:has-text("撤单"), .cancel-btn').first
                        
                        if cancel_btn.is_visible():
                            cancel_btn.click()
                            page.wait_for_timeout(1000)
                            
                            # 确认
                            try:
                                confirm_button = page.locator('button:has-text("确定"), button:has-text("确认")').first
                                if confirm_button.is_visible(timeout=2000):
                                    confirm_button.click()
                                    page.wait_for_timeout(1000)
                            except:
                                pass
                            
                            success_count += 1
                            logger.info(f"✓ 已撤销：{order['order_id']}")
                    except Exception as e:
                        logger.error(f"撤销失败 {order['order_id']}: {e}")
                
                save_screenshot(page, "cancel_batch", f"批量撤单完成 - 成功{success_count}笔")
                logger.info(f"✓ 撤单完成：成功 {success_count}/{len(cancellable_orders)} 笔")
                return success_count > 0
            else:
                logger.warning("⚠️ 当前无未成交委托")
                return False
            
    except PlaywrightTimeout as e:
        logger.error(f"❌ 超时错误：{e}")
        save_screenshot(page, "cancel_timeout", "撤单超时")
        return False
    except Exception as e:
        logger.error(f"❌ 撤单失败：{type(e).__name__} - {e}")
        save_screenshot(page, "cancel_error", f"撤单异常：{e}")
        return False


# ============================================================================
# 核心功能：委托查询
# ============================================================================

def get_orders(page: Page, query_type: str = "today") -> Optional[List[Dict]]:
    """
    查询委托记录
    
    Args:
        page: Playwright page 对象
        query_type: 查询类型（today=当日委托，history=历史委托）
    
    Returns:
        list: 委托记录列表，失败返回 None
    """
    logger.info(f"📋 查询委托记录：{query_type}")
    save_screenshot(page, "before_orders", "委托查询前页面")
    
    try:
        # 导航到委托查询页面
        logger.info("导航到委托查询页面...")
        page.goto(ORDERS_URL, timeout=TIMEOUT)
        page.wait_for_load_state('networkidle')
        save_screenshot(page, "orders_page", "委托查询页面")
        
        # 选择查询类型
        if query_type == "history":
            try:
                history_tab = page.locator('text=历史委托，a:has-text("历史委托")').first
                if history_tab.is_visible(timeout=2000):
                    history_tab.click()
                    page.wait_for_timeout(2000)
                    logger.info("切换到历史委托")
            except:
                logger.warning("未找到历史委托选项")
        
        # 等待表格加载
        page.wait_for_timeout(3000)
        
        # 提取委托记录
        orders = extract_orders_data(page)
        
        if orders:
            logger.info(f"✓ 成功获取 {len(orders)} 条委托记录")
            save_screenshot(page, "orders_result", f"委托查询结果 - {len(orders)}条")
        else:
            logger.warning("⚠️ 未获取到委托记录")
        
        return orders
        
    except Exception as e:
        logger.error(f"❌ 委托查询失败：{type(e).__name__} - {e}")
        save_screenshot(page, "orders_error", f"委托查询异常：{e}")
        return None


def extract_orders_data(page: Page) -> List[Dict]:
    """从委托查询页面提取数据"""
    orders = []
    
    try:
        logger.info("提取委托记录...")
        
        # 查找委托表格
        order_rows = page.locator('table tbody tr').all()
        
        for row in order_rows:
            try:
                cells = row.locator('td').all()
                if len(cells) >= 8:
                    # 列顺序可能为：委托编号 | 股票代码 | 股票名称 | 买卖方向 | 委托价格 | 委托数量 | 委托状态 | 委托时间
                    order = {
                        'order_id': cells[0].text_content().strip() if len(cells) > 0 else '',
                        'stock_code': cells[1].text_content().strip() if len(cells) > 1 else '',
                        'stock_name': cells[2].text_content().strip() if len(cells) > 2 else '',
                        'direction': cells[3].text_content().strip() if len(cells) > 3 else '',  # 买/卖
                        'price': cells[4].text_content().strip() if len(cells) > 4 else '',
                        'quantity': cells[5].text_content().strip() if len(cells) > 5 else '',
                        'status': cells[6].text_content().strip() if len(cells) > 6 else '',
                        'time': cells[7].text_content().strip() if len(cells) > 7 else '',
                    }
                    
                    # 跳过空行
                    if not order['order_id']:
                        continue
                    
                    orders.append(order)
                    
            except Exception as e:
                logger.debug(f"解析委托行失败：{e}")
                continue
        
        logger.info(f"共提取 {len(orders)} 条委托记录")
        
    except Exception as e:
        logger.error(f"提取委托数据失败：{type(e).__name__} - {e}")
    
    return orders


def format_orders_output(orders: List[Dict]) -> str:
    """格式化委托记录输出"""
    if not orders:
        return "📋 暂无委托记录"
    
    output = ["📋 委托记录", "=" * 80]
    
    # 表头
    output.append(f"{'委托编号':<12} {'股票代码':<8} {'股票名称':<10} {'方向':<4} {'价格':<8} {'数量':<8} {'状态':<10} {'时间':<12}")
    output.append("-" * 80)
    
    for order in orders:
        output.append(
            f"{order.get('order_id', ''):<12} "
            f"{order.get('stock_code', ''):<8} "
            f"{order.get('stock_name', ''):<10} "
            f"{order.get('direction', ''):<4} "
            f"{order.get('price', ''):<8} "
            f"{order.get('quantity', ''):<8} "
            f"{order.get('status', ''):<10} "
            f"{order.get('time', ''):<12}"
        )
    
    output.append("=" * 80)
    output.append(f"共 {len(orders)} 条委托记录")
    
    return "\n".join(output)


# ============================================================================
# 核心功能：资金查询
# ============================================================================

def get_balance(page: Page) -> Optional[Dict]:
    """
    查询账户资金
    
    Args:
        page: Playwright page 对象
    
    Returns:
        dict: 资金信息，失败返回 None
    """
    logger.info("💰 查询账户资金...")
    save_screenshot(page, "before_balance", "资金查询前页面")
    
    try:
        # 导航到资金查询页面
        logger.info("导航到资金查询页面...")
        page.goto(BALANCE_URL, timeout=TIMEOUT)
        page.wait_for_load_state('networkidle')
        save_screenshot(page, "balance_page", "资金查询页面")
        
        # 等待数据加载
        page.wait_for_timeout(3000)
        
        # 提取资金数据
        balance_data = extract_balance_data(page)
        
        if balance_data:
            logger.info(f"✓ 成功获取资金信息")
            save_screenshot(page, "balance_result", "资金查询结果")
        else:
            logger.warning("⚠️ 未获取到资金数据")
        
        return balance_data
        
    except Exception as e:
        logger.error(f"❌ 资金查询失败：{type(e).__name__} - {e}")
        save_screenshot(page, "balance_error", f"资金查询异常：{e}")
        return None


def extract_balance_data(page: Page) -> Dict:
    """从资金页面提取数据"""
    import re
    
    result = {
        'total_asset': None,       # 总资产
        'available': None,         # 可用资金
        'frozen': None,            # 冻结资金
        'market_value': None,      # 证券市值
        'profit': None,            # 持仓盈亏
        'daily_profit': None,      # 当日盈亏
    }
    
    try:
        logger.info("提取资金数据...")
        
        # 总资产
        total_asset_locator = page.locator('text=总资产').first
        if total_asset_locator.is_visible(timeout=3000):
            parent = total_asset_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['total_asset'] = float(numbers[0].replace(',', ''))
                logger.info(f"总资产：{result['total_asset']}")
        
        # 可用资金
        available_locator = page.locator('text=可用资金').first
        if available_locator.is_visible(timeout=2000):
            parent = available_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['available'] = float(numbers[0].replace(',', ''))
                logger.info(f"可用资金：{result['available']}")
        
        # 冻结资金
        frozen_locator = page.locator('text=冻结资金').first
        if frozen_locator.is_visible(timeout=2000):
            parent = frozen_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['frozen'] = float(numbers[0].replace(',', ''))
                logger.info(f"冻结资金：{result['frozen']}")
        
        # 证券市值
        market_value_locator = page.locator('text=证券市值').first
        if market_value_locator.is_visible(timeout=2000):
            parent = market_value_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'[\d,]+\.?\d*', text)
            if numbers:
                result['market_value'] = float(numbers[0].replace(',', ''))
                logger.info(f"证券市值：{result['market_value']}")
        
        # 持仓盈亏
        profit_locator = page.locator('text=持仓盈亏').first
        if profit_locator.is_visible(timeout=2000):
            parent = profit_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'-?[\d,]+\.?\d*', text)
            if numbers:
                result['profit'] = float(numbers[0].replace(',', ''))
                logger.info(f"持仓盈亏：{result['profit']}")
        
        # 当日盈亏
        daily_profit_locator = page.locator('text=当日盈亏').first
        if daily_profit_locator.is_visible(timeout=2000):
            parent = daily_profit_locator.locator('..')
            text = parent.text_content()
            numbers = re.findall(r'-?[\d,]+\.?\d*', text)
            if numbers:
                result['daily_profit'] = float(numbers[0].replace(',', ''))
                logger.info(f"当日盈亏：{result['daily_profit']}")
        
    except Exception as e:
        logger.error(f"提取资金数据失败：{type(e).__name__} - {e}")
    
    return result


def format_balance_output(data: Dict) -> str:
    """格式化资金信息输出"""
    if not data:
        return "❌ 未获取到资金数据"
    
    output = ["💰 账户资金信息", "=" * 60]
    
    if data.get('total_asset'):
        output.append(f"💎 总资产：¥{data['total_asset']:,.2f}")
    if data.get('available'):
        output.append(f"💵 可用资金：¥{data['available']:,.2f}")
    if data.get('frozen'):
        output.append(f"🧊 冻结资金：¥{data['frozen']:,.2f}")
    if data.get('market_value'):
        output.append(f"📈 证券市值：¥{data['market_value']:,.2f}")
    
    output.append("")
    
    if data.get('profit'):
        profit_emoji = "🟢" if data['profit'] > 0 else "🔴"
        output.append(f"{profit_emoji} 持仓盈亏：¥{data['profit']:,.2f}")
    if data.get('daily_profit'):
        daily_emoji = "🟢" if data['daily_profit'] > 0 else "🔴"
        output.append(f"{daily_emoji} 当日盈亏：¥{data['daily_profit']:,.2f}")
    
    # 计算仓位
    if data.get('total_asset') and data.get('market_value'):
        position_rate = data['market_value'] / data['total_asset'] * 100
        output.append(f"📊 仓位：{position_rate:.1f}%")
    
    output.append("")
    output.append("=" * 60)
    output.append("💡 提示：数据仅供参考，请以实际账户为准")
    
    return "\n".join(output)


# ============================================================================
# 命令行入口
# ============================================================================

def cmd_login(args):
    """登录 + 持仓查询命令"""
    logger.info("=" * 60)
    logger.info("东方财富 - 登录 + 持仓查询")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 获取持仓
        position_data = get_position(page)
        
        if position_data:
            print("\n" + format_position_output(position_data))
            print("\n---JSON_START---")
            print(json.dumps(position_data, ensure_ascii=False, indent=2))
            print("---JSON_END---")
            return True
        else:
            logger.error("获取持仓失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_buy(args):
    """买入命令"""
    logger.info("=" * 60)
    logger.info("东方财富 - 买入操作")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    logger.info(f"买入：{args.stock_code} @ {args.price} x {args.quantity} ({args.order_type})")
    
    # 安全确认
    if not args.confirm:
        total = args.price * args.quantity
        logger.warning(f"⚠️ 交易确认：总金额 ¥{total:,.2f}")
        response = input("确认买入？(yes/no): ").strip().lower()
        if response not in ['yes', 'y']:
            logger.info("已取消")
            return False
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 买入
        success = buy_stock(page, args.stock_code, args.price, args.quantity, args.order_type)
        
        if success:
            logger.info("✓ 买入操作完成")
            return True
        else:
            logger.error("❌ 买入操作失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_sell(args):
    """卖出命令"""
    logger.info("=" * 60)
    logger.info("东方财富 - 卖出操作")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    logger.info(f"卖出：{args.stock_code} @ {args.price} x {args.quantity} ({args.order_type})")
    
    # 安全确认
    if not args.confirm:
        total = args.price * args.quantity
        logger.warning(f"⚠️ 交易确认：总金额 ¥{total:,.2f}")
        response = input("确认卖出？(yes/no): ").strip().lower()
        if response not in ['yes', 'y']:
            logger.info("已取消")
            return False
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 卖出
        success = sell_stock(page, args.stock_code, args.price, args.quantity, args.order_type)
        
        if success:
            logger.info("✓ 卖出操作完成")
            return True
        else:
            logger.error("❌ 卖出操作失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_cancel(args):
    """撤单命令"""
    logger.info("=" * 60)
    logger.info("东方财富 - 撤单操作")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    
    if args.order_id:
        logger.info(f"撤销委托编号：{args.order_id}")
    elif args.stock_code:
        logger.info(f"撤销股票 {args.stock_code} 的所有未成交委托")
    else:
        logger.info("撤销所有未成交委托")
    
    # 安全确认
    if not args.confirm:
        logger.warning("⚠️ 撤单确认：此操作将撤销未成交的委托")
        response = input("确认撤单？(yes/no): ").strip().lower()
        if response not in ['yes', 'y']:
            logger.info("已取消")
            return False
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 撤单
        success = cancel_order(page, args.order_id, args.stock_code)
        
        if success:
            logger.info("✓ 撤单操作完成")
            return True
        else:
            logger.error("❌ 撤单操作失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_orders(args):
    """委托查询命令"""
    logger.info("=" * 60)
    logger.info("东方财富 - 委托查询")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    logger.info(f"查询类型：{args.type} (today=当日，history=历史)")
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 查询委托
        orders = get_orders(page, args.type)
        
        if orders is not None:
            print("\n" + format_orders_output(orders))
            print("\n---JSON_START---")
            print(json.dumps(orders, ensure_ascii=False, indent=2))
            print("---JSON_END---")
            return True
        else:
            logger.error("委托查询失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_balance(args):
    """资金查询命令"""
    logger.info("=" * 60)
    logger.info("东方财富 - 资金查询")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 查询资金
        balance_data = get_balance(page)
        
        if balance_data:
            print("\n" + format_balance_output(balance_data))
            print("\n---JSON_START---")
            print(json.dumps(balance_data, ensure_ascii=False, indent=2))
            print("---JSON_END---")
            return True
        else:
            logger.error("资金查询失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_analyze(args):
    """持仓分析命令（整合 eastmoney-portfolio 功能）"""
    logger.info("=" * 60)
    logger.info("东方财富 - 持仓分析")
    logger.info("=" * 60)
    
    account, password = get_credentials()
    logger.info(f"账号：{account[:3]}***{account[-4:]}")
    
    playwright, browser, context, page = connect_browser()
    
    try:
        # 登录
        if not login(page, account, password):
            logger.error("登录失败")
            return False
        
        # 获取持仓
        position_data = get_position(page)
        
        if not position_data or not position_data.get('positions'):
            logger.error("获取持仓失败")
            return False
        
        # 分析持仓
        analysis_result = analyze_position(page, position_data)
        
        if analysis_result:
            analysis = analysis_result['analysis']
            suggestions = analysis_result['suggestions']
            
            # 输出分析报告
            print("\n" + format_analysis_report(analysis, suggestions))
            
            # 输出 JSON
            print("\n---JSON_START---")
            print(json.dumps(analysis_result, ensure_ascii=False, indent=2))
            print("---JSON_END---")
            
            return True
        else:
            logger.error("持仓分析失败")
            return False
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def cmd_select(args):
    """
    条件选股命令（无需登录）
    
    使用东方财富条件选股功能，支持多种选股条件：
    - 技术指标（MACD、KDJ、RSI 等）
    - 基本面指标（市盈率、市净率、ROE 等）
    - 行情指标（涨跌幅、成交量、换手率等）
    - 板块概念
    
    注意：条件选股页面为动态加载，建议在浏览器中查看完整功能。
    """
    logger.info("=" * 60)
    logger.info("东方财富 - 条件选股")
    logger.info("=" * 60)
    
    # 条件选股无需登录，直接连接浏览器
    playwright, browser, context, page = connect_browser()
    
    try:
        # 访问条件选股页面
        logger.info(f"正在访问东方财富条件选股页面...")
        page.goto(XUANGU_URL, timeout=TIMEOUT)
        page.wait_for_load_state('networkidle')
        save_screenshot(page, "xuangu_home", "条件选股首页")
        
        # 等待页面加载
        page.wait_for_timeout(5000)
        
        # 输出页面信息
        print("\n" + "=" * 70)
        print("📊 东方财富条件选股")
        print("=" * 70)
        print(f"📅 访问时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        print(f"🔗 页面地址：{XUANGU_URL}")
        print()
        print("✅ 功能说明:")
        print("  - 技术指标选股（MACD、KDJ、RSI 等）")
        print("  - 基本面选股（市盈率、市净率、ROE 等）")
        print("  - 行情选股（涨跌幅、成交量、换手率等）")
        print("  - 板块概念选股（行业、概念、地区等）")
        print()
        print("💡 使用建议:")
        print("  1. 在浏览器中打开条件选股页面进行可视化操作")
        print("  2. 使用预设条件或自定义选股策略")
        print("  3. 导出选股结果到 Excel 或自选股")
        print()
        print("📸 截图已保存到日志文件夹")
        print("=" * 70)
        
        return True
            
    finally:
        logger.info("关闭 CDP 连接...")
        browser.close()


def extract_stock_selection(page: Page, args) -> Dict:
    """
    从条件选股页面提取结果
    
    Args:
        page: Playwright page 对象
        args: 命令行参数
    
    Returns:
        选股结果字典
    """
    result = {
        'total_count': 0,
        'stocks': [],
        'conditions': [],
        'update_time': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
    }
    
    try:
        logger.info("提取选股结果...")
        
        # 保存页面截图以便调试
        save_screenshot(page, "xuangu_result", "选股结果页面")
        
        # 获取选股条件（从页面顶部）
        condition_elements = page.locator('.condition-item, .tag-item, [class*="condition"], [class*="tag"]').all()
        for cond in condition_elements[:10]:
            try:
                text = cond.text_content().strip()
                if text and len(text) < 200:  # 过滤太长的文本
                    result['conditions'].append(text)
            except:
                continue
        
        # 尝试多种选择器查找股票表格
        table_selectors = [
            'table',
            '.stock-table',
            '.result-table',
            '[class*="table"]',
            '.data-grid',
        ]
        
        stock_table = None
        for selector in table_selectors:
            try:
                stock_table = page.locator(selector).first
                if stock_table.is_visible(timeout=2000):
                    logger.info(f"找到股票表格：{selector}")
                    break
            except:
                continue
        
        if stock_table:
            # 获取表格行
            rows = stock_table.locator('tr').all()
            logger.info(f"找到 {len(rows)} 行")
            
            # 跳过表头，提取数据行
            for i, row in enumerate(rows[1:51], 1):  # 跳过表头，最多 50 行
                try:
                    cells = row.locator('td, th').all()
                    if len(cells) >= 4:
                        # 提取股票代码和名称（通常在第 1-2 列）
                        code_name = cells[0].text_content().strip() if len(cells) > 0 else ''
                        # 尝试分离代码和名称
                        code_match = re.search(r'(\d{6})', code_name)
                        if code_match:
                            code = code_match.group(1)
                            name = code_name.replace(code, '').strip()
                        else:
                            code = code_name
                            name = cells[1].text_content().strip() if len(cells) > 1 else ''
                        
                        stock = {
                            'code': code,
                            'name': name,
                            'price': cells[2].text_content().strip() if len(cells) > 2 else '',
                            'change_percent': cells[3].text_content().strip() if len(cells) > 3 else '',
                            'volume': cells[4].text_content().strip() if len(cells) > 4 else '',
                        }
                        
                        if stock['code'] and re.match(r'\d{6}', stock['code']):
                            result['stocks'].append(stock)
                            if len(result['stocks']) <= 5:
                                logger.info(f"股票：{stock['code']} {stock['name']}")
                except Exception as e:
                    logger.debug(f"解析行失败：{e}")
                    continue
        
        result['total_count'] = len(result['stocks'])
        logger.info(f"共提取 {len(result['stocks'])} 条股票记录")
        
    except Exception as e:
        logger.error(f"提取选股数据失败：{type(e).__name__} - {e}")
    
    return result


def format_stock_selection_output(data: Dict) -> str:
    """格式化选股结果输出"""
    if not data or not data.get('stocks'):
        return "❌ 未获取到选股结果"
    
    output = ["📊 东方财富条件选股结果", "=" * 70]
    output.append(f"📅 更新时间：{data.get('update_time', '')}")
    output.append(f"📋 选股条件：{', '.join(data.get('conditions', ['默认条件']))}")
    output.append(f"📈 符合条件股票数：{data.get('total_count', 0)} 只")
    output.extend(["", "📋 股票列表:", "-" * 70])
    
    # 表头
    output.append(f"{'序号':<4} {'代码':<8} {'名称':<12} {'现价':>10} {'涨跌幅':>10} {'成交量':>12}")
    output.append("-" * 70)
    
    for i, stock in enumerate(data['stocks'][:20], 1):
        change_pct = stock.get('change_percent', '')
        change_emoji = "📈" if '+' in str(change_pct) or (change_pct.replace('%', '').replace('.', '').replace('-', '').isdigit() and float(change_pct.replace('%', '')) > 0) else "📉" if '-' in str(change_pct) else "➡️"
        
        output.append(
            f"{i:<4} {stock.get('code', ''):<8} {stock.get('name', ''):<12} "
            f"{stock.get('price', ''):>10} {change_emoji}{stock.get('change_percent', ''):>8} "
            f"{stock.get('volume', ''):>12}"
        )
    
    if len(data['stocks']) > 20:
        output.append(f"... 还有 {len(data['stocks']) - 20} 只股票，请查看完整 JSON 输出")
    
    output.extend(["", "=" * 70, "💡 提示：选股结果仅供参考，不构成投资建议"])
    
    return "\n".join(output)


def main():
    """主函数 - 命令行解析"""
    parser = argparse.ArgumentParser(description='东方财富证券交易技能', formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
示例:
  # 登录 + 持仓查询
  python3 eastmoney_trading.py login
  
  # 持仓分析 ⭐
  python3 eastmoney_trading.py analyze
  
  # 买入
  python3 eastmoney_trading.py buy --stock-code 600519 --price 1850 --quantity 100
  
  # 卖出
  python3 eastmoney_trading.py sell --stock-code 600519 --price 1900 --quantity 100
  
  # 撤单（指定委托编号）
  python3 eastmoney_trading.py cancel --order-id 12345678
  
  # 撤单（指定股票）
  python3 eastmoney_trading.py cancel --stock-code 600519
  
  # 撤单（所有未成交）
  python3 eastmoney_trading.py cancel
  
  # 查询当日委托
  python3 eastmoney_trading.py orders
  
  # 查询历史委托
  python3 eastmoney_trading.py orders --type history
  
  # 查询资金
  python3 eastmoney_trading.py balance
  
  # 条件选股（无需登录）⭐
  python3 eastmoney_trading.py select
  
  # 按行业选股
  python3 eastmoney_trading.py select --industry 半导体
  
  # 按概念选股
  python3 eastmoney_trading.py select --concept 人工智能
  
  # 指定市场
  python3 eastmoney_trading.py select --market sh
        """)
    
    subparsers = parser.add_subparsers(dest='command', help='命令')
    
    # login 命令
    login_parser = subparsers.add_parser('login', help='登录 + 持仓查询')
    login_parser.set_defaults(func=cmd_login)
    
    # buy 命令
    buy_parser = subparsers.add_parser('buy', help='买入股票')
    buy_parser.add_argument('--stock-code', required=True, help='股票代码')
    buy_parser.add_argument('--price', type=float, required=True, help='委托价格')
    buy_parser.add_argument('--quantity', type=int, required=True, help='委托数量')
    buy_parser.add_argument('--order-type', choices=['limit', 'market'], default='limit', help='委托类型')
    buy_parser.add_argument('--confirm', action='store_true', help='跳过确认')
    buy_parser.set_defaults(func=cmd_buy)
    
    # sell 命令
    sell_parser = subparsers.add_parser('sell', help='卖出股票')
    sell_parser.add_argument('--stock-code', required=True, help='股票代码')
    sell_parser.add_argument('--price', type=float, required=True, help='委托价格')
    sell_parser.add_argument('--quantity', type=int, required=True, help='委托数量')
    sell_parser.add_argument('--order-type', choices=['limit', 'market'], default='limit', help='委托类型')
    sell_parser.add_argument('--confirm', action='store_true', help='跳过确认')
    sell_parser.set_defaults(func=cmd_sell)
    
    # cancel 命令
    cancel_parser = subparsers.add_parser('cancel', help='撤销委托')
    cancel_parser.add_argument('--order-id', help='委托编号（指定则撤销单笔）')
    cancel_parser.add_argument('--stock-code', help='股票代码（指定则撤销该股票所有未成交委托）')
    cancel_parser.add_argument('--confirm', action='store_true', help='跳过确认')
    cancel_parser.set_defaults(func=cmd_cancel)
    
    # orders 命令
    orders_parser = subparsers.add_parser('orders', help='委托查询')
    orders_parser.add_argument('--type', choices=['today', 'history'], default='today', help='查询类型')
    orders_parser.set_defaults(func=cmd_orders)
    
    # balance 命令
    balance_parser = subparsers.add_parser('balance', help='资金查询')
    balance_parser.set_defaults(func=cmd_balance)
    
    # analyze 命令
    analyze_parser = subparsers.add_parser('analyze', help='持仓分析')
    analyze_parser.set_defaults(func=cmd_analyze)
    
    # select 命令（条件选股）
    select_parser = subparsers.add_parser('select', help='条件选股（无需登录）')
    select_parser.add_argument('--condition', '-c', action='append', help='选股条件（可多次指定）')
    select_parser.add_argument('--market', choices=['sh', 'sz', 'bj', 'all'], default='all', help='市场选择')
    select_parser.add_argument('--industry', help='行业板块')
    select_parser.add_argument('--concept', help='概念板块')
    select_parser.set_defaults(func=cmd_select)
    
    args = parser.parse_args()
    
    if args.command is None:
        parser.print_help()
        sys.exit(1)
    
    args.func(args)


if __name__ == "__main__":
    main()
