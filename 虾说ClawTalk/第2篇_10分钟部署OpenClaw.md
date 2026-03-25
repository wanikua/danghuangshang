虾折腾

10分钟部署你的OpenClaw：从零到AI管家

别被"自托管"吓到，真的只要10分钟。

"自托管AI助手"这六个字，是不是听着就头大？Docker、服务器、端口转发、配置文件……光想想就觉得麻烦。

但OpenClaw可能是你遇到过的最简单的自托管项目之一。它的onboarding流程设计得非常贴心，一个交互式向导帮你搞定一切。不信？跟我走一遍。


📋 开始之前，你需要准备什么

一台电脑。Mac、Linux、Windows都行。Windows用户强烈推荐先装WSL2（Windows Subsystem for Linux），然后在WSL2里操作。原生Windows不推荐，工具兼容性差。

Node.js 22或更新版本。Mac用户终端输入 brew install node 一行搞定。Linux用户可以用nvm。Windows WSL2用户也是同理。

一个AI模型的认证方式。推荐用Anthropic的API Key，Claude系列模型在长上下文和抗注入方面表现最好。也支持OpenAI的OAuth订阅。

可选但推荐：一个Brave Search API Key，用于网页搜索能力。

10分钟空闲时间。

齐活了，开干。


🚀 第一步：安装OpenClaw

打开终端，输入一行命令。

最推荐的方式是用官方安装脚本：

curl -fsSL https://clawd.bot/install.sh | bash

Windows PowerShell用户：

iwr -useb https://clawd.bot/install.ps1 | iex

也可以用npm全局安装：

npm install -g clawdbot@latest

或者你喜欢pnpm：

pnpm add -g clawdbot@latest

就一行命令的事。


🧙 第二步：运行Onboard向导

这是OpenClaw最贴心的设计——一个交互式引导向导，帮你搞定所有配置：

clawdbot onboard --install-daemon

向导会一步一步引导你做这些选择：

本地Gateway还是远程Gateway。个人使用选本地就行。

认证方式。可以用Anthropic API Key（推荐），也可以用OpenAI的OAuth订阅，或者Claude的setup-token。向导会帮你把凭证存好。

连接聊天渠道。WhatsApp需要扫QR码，Telegram填Bot Token，Discord填Bot Token。可以同时配多个，也可以先跳过，之后再加。

安装推荐的Skills。向导会列出可用的Skill让你选择安装。

安装守护进程。macOS用launchd，Linux用systemd用户服务。装了之后OpenClaw开机自启，24/7待命。

Gateway Token。向导会自动生成一个安全令牌，即使只在本地运行也会默认开启认证。

跟着提示走就行，不需要手动编辑任何配置文件。对新手非常友好。不确定选什么的时候，选默认选项就对了。


💬 第三步：发送第一条消息

向导完成后，Gateway已经在后台运行了。现在你有三种方式跟它聊天：

方式一：命令行直接聊。

clawdbot agent --message "你好，介绍一下你自己"

方式二：打开Web界面。浏览器访问 http://127.0.0.1:18789/ 你会看到Gateway自带的Control UI和WebChat界面。什么都不用配，直接在浏览器里聊。这是体验最快的方式。

方式三：通过你的聊天软件。如果在向导中配置了Telegram、Discord或WhatsApp等渠道，直接在那边发消息就行。AI会在几秒内回复你。

恭喜，你的私人AI管家已经上线了。🎉


🔍 出问题了？用Doctor检查

OpenClaw内置了一个诊断工具：

clawdbot doctor

它会全面检查你的配置、渠道连接状态、安全设置、Skills加载情况等，帮你快速发现和定位问题。输出里会明确告诉你哪里有问题、怎么修。

遇到什么不对劲的，先跑一下doctor，八成能找到原因。


🏃 后台管理命令

日常管理很简单，四个命令搞定一切：

clawdbot gateway start    启动Gateway
clawdbot gateway stop     停止Gateway
clawdbot gateway restart  重启Gateway
clawdbot gateway status   查看运行状态

如果你用了 --install-daemon，电脑重启后OpenClaw会自动启动。你的AI管家全天候待命。


💡 进阶小贴士

配置文件在哪？所有配置存在 ~/.clawdbot/clawdbot.json。通常不需要手动编辑，clawdbot onboard 和 clawdbot configure 命令可以搞定大部分事情。但如果你喜欢直接改配置文件，也完全可以。

远程访问？配置Tailscale Serve（仅内网访问）或Funnel（公网访问），可以安全地从外面访问你的Gateway面板。支持token认证和密码认证。这样你出门在外也能用WebChat跟AI聊天。

更新？一行搞定：clawdbot update。支持切换到stable、beta或dev频道。平滑升级，原有配置不受影响。更新后跑一下 clawdbot doctor 确认一切正常。

多Agent路由？可以配置多个Agent，不同渠道的消息路由到不同Agent处理。工作Slack走专业Agent，私人Telegram走贴心助手。每个Agent有独立的Workspace和人设。

想用Docker？OpenClaw也提供Docker部署方案，官方文档有详细指南。还有社区做的Nix包和Home Assistant Add-on。不过对个人使用来说，npm直接装是最简单的。

Web搜索配置？推荐配置Brave Search API Key让AI能搜索网页。运行 clawdbot configure --section web 就能设置。


🎯 回顾一下

整个过程就三步：

第一步：安装。一行命令。
第二步：clawdbot onboard --install-daemon。向导引导配置。
第三步：开始聊天！

真的不到10分钟。你得到的，是一个跑在自己设备上、连接你所有聊天软件、有记忆有工具有手脚的私人AI管家。

如果你卡在任何一步，OpenClaw的Discord社区非常活跃，随时可以去问。

关注「虾说ClawTalk」，下期带你解锁OpenClaw的全平台连接能力！🦞

下期预告：OpenClaw支持17个聊天渠道！WhatsApp、Telegram、Discord全打通——看看你日常用的软件在不在列。
