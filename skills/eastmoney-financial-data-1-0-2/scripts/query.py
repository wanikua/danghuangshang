#!/usr/bin/env python3
"""
东方财富金融数据查询脚本
使用方式: python query.py <查询内容>
"""

import os
import sys
import json
import requests

def main():
    if len(sys.argv) < 2:
        print("使用方式: python query.py <查询内容>")
        sys.exit(1)
    
    query = " ".join(sys.argv[1:])
    api_key = os.getenv("EASTMONEY_APIKEY")
    
    if not api_key:
        print("错误: 请先设置EASTMONEY_APIKEY环境变量")
        print("你可以在东方财富Skills页面获取apikey，然后执行: export EASTMONEY_APIKEY='你的apikey'")
        sys.exit(1)
    
    url = "https://mkapi2.dfcfs.com/finskillshub/api/claw/query"
    headers = {
        "Content-Type": "application/json",
        "apikey": api_key
    }
    data = {
        "toolQuery": query
    }
    
    try:
        response = requests.post(url, headers=headers, json=data)
        response.raise_for_status()
        result = response.json()
        
        # 检查是否有数据返回
        if not result.get("data") or not result["data"].get("dataTableDTOList"):
            print("查询结果为空，建议到东方财富妙想AI查询更详细的信息。")
            sys.exit(0)
        
        # 格式化输出
        print(json.dumps(result, ensure_ascii=False, indent=2))
        
        # 可选: 保存到文件
        # with open(f"eastmoney_query_{query[:20]}.json", "w", encoding="utf-8") as f:
        #     json.dump(result, f, ensure_ascii=False, indent=2)
        # print(f"结果已保存到 eastmoney_query_{query[:20]}.json")
        
    except requests.exceptions.RequestException as e:
        print(f"请求失败: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
