虾工具

ClawdHub精选：必装的Skills推荐

装上这些Skill，你的AI管家立刻开挂。

OpenClaw裸跑已经够强了——能聊天、能搜索、能读写文件、能执行代码。但真正让它从"能用"变成"神器"的，是它的Skills系统。

Skills就像给你的AI管家安装新技能。就像游戏里装备附魔一样，每多一个Skill，战斗力翻一倍。


🧠 Skills是什么？三句话讲清楚

每个Skill是一个文件夹，核心是一个 SKILL.md 文件，遵循AgentSkills开放标准。

Skills有三个来源，按优先级排列：Workspace（工作区目录下的skills文件夹）优先级最高，Managed（~/.clawdbot/skills）其次，Bundled（内置随安装包发布的）最低。同名时高优先级覆盖低优先级。

安装超简单：clawdhub install 交互式选择，clawdhub update --all 一键更新所有。


🏆 必装Skills推荐

🌐 Browser Control（浏览器控制）

类型：内置Skill，无需额外安装

这可能是OpenClaw最炸裂的能力。它给你的AI管家配了一个专属浏览器，运行在独立的Chrome Profile里，跟你的日常浏览器完全隔离。

AI可以打开网页阅读内容、点击按钮填写表单、截图生成PDF、自动化网页操作。

实际场景随便举几个：帮你查机票价格、登录GitHub看PR、在网站上填表提交。社区里有人纯靠这个能力自动在Tesco超市下单购物，全程没调任何API。

只要人类能在网页上做的操作，AI都能做。这句话的含金量，你细品。


📸 Nano Banana Pro（图片生成）

安装：clawdhub install nano-banana-pro
需要：Gemini API Key

用Gemini的图像生成能力，直接在聊天中生成和编辑图片。

想画一只穿西装的龙虾？一句话搞定。帮你做Logo草稿？发条消息就行。把照片背景换成海滩？直接发图过去。

因为基于Gemini，不仅能生成新图，还能编辑已有图片。在聊天软件里发条消息就出图，体验非常丝滑。


🗣️ SAG（ElevenLabs语音）

类型：内置Skill，需配置启用
需要：ElevenLabs API Key

把你的AI管家变成一个会说话的助手。文字转语音，可以发语音消息，多种声音选择，支持讲故事、念摘要、读新闻。

在Telegram或WhatsApp里收到一段AI用磁性嗓音讲的睡前故事，那感觉真的绝了。搭配Voice Wake语音唤醒功能，你甚至可以直接跟它说话，它直接语音回复。

在配置文件里设置 skills.entries.sag.enabled 为 true，填入你的ElevenLabs API Key就能用。


🖨️ Bambu 3D打印机控制

来源：ClawdHub社区 @tobiasbischoff
需要：BambuLab打印机

如果你有BambuLab 3D打印机，这个Skill让你通过聊天查看打印状态和进度、管理打印任务、查看摄像头画面、管理AMS材料系统、执行校准。

在手机上问一句"我的打印完成了吗？"AI查询打印机状态回复你"已完成95%，预计还有8分钟"。不用专门打开App，聊天里顺手就问了。


🏠 Home Assistant智能家居控制

来源：ClawdHub官方
需要：Home Assistant实例

通过自然语言控制和自动化你的Home Assistant设备。开灯关灯、调温度、查看设备状态，全部用聊天搞定。

社区里还有人做了Roborock扫地机器人的控制插件、Winix空气净化器的控制方案。只要你的智能家居有API，理论上都可以做成Skill。


📅 CalDAV日历

来源：ClawdHub官方
需要：khal和vdirsyncer

自托管的日历集成。查看日程、添加事件、提醒即将到来的会议。配合Cron定时任务，可以每天早上自动给你发当日日程摘要。


🛠️ 想自己做一个Skill？

受到启发了？自己做一个Skill其实很简单。最基础的Skill只需要一个 SKILL.md 文件，包含name和description的YAML frontmatter，加上使用说明。

放到 ~/.clawdbot/skills/你的skill名/ 目录下，OpenClaw会自动检测并加载。支持热重载，修改SKILL.md后自动刷新，不用重启。

还可以通过metadata设置环境依赖检查，比如需要什么命令行工具、什么环境变量、什么配置项才能启用。ClawdHub上有各种现成的例子可以参考。


💡 管理小贴士

安全第一：第三方Skill相当于外部代码，安装前先看看源码和SKILL.md内容。

Token开销：每个启用的Skill会占用一点系统提示空间。不用的Skill在配置里设置 enabled: false 禁用掉，省Token。

按需开关：工作日启用工作相关的Skill，周末切换到生活类Skill。灵活搭配。


🎯 总结

Skills系统是OpenClaw的核心竞争力之一。内置的浏览器控制和语音已经很强大，ClawdHub上社区贡献的各种Skills更是让它的能力边界不断扩展。

去 clawdhub.com 逛逛，总有一款适合你。

关注「虾说ClawTalk」，发现更多宝藏工具！🦞

下期预告：Canvas可视化功能深度解析——当AI不再只是回消息，而是直接在屏幕上画给你看。
