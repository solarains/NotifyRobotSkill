# Notify Robot Skill

> 一个 Cursor AI 技能，在每次 AI 对话结束后自动发送 Webhook 通知。

[English](./README.en.md)

## 特性

- 🤖 **自动通知** - 每次 AI 回复后自动发送 Webhook 通知
- 🌐 **通用支持** - 支持飞书、钉钉、企业微信、Slack 及任何自定义 Webhook
- ⚡ **简单安装** - 两行命令完成安装
- 🎯 **智能规则** - 可选的自动触发规则，实现免手动操作
- 🔒 **安全** - 配置文件保留在本地（自动被 git 忽略）

## 快速安装

```bash
if [ -f /usr/bin/curl ]; then
    curl -sSO https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/setup-notify-robot.sh
else
    wget -O setup-notify-robot.sh https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/setup-notify-robot.sh
fi && bash setup-notify-robot.sh
```

安装向导将引导你完成：
1. 选择目标平台 (Claude Code / Cursor / Other)
2. 选择机器人平台 (飞书/钉钉/企业微信/Slack/自定义)
3. 输入 Webhook URL
4. 测试通知

## 工作原理

安装并启用规则后：

1. 你向 AI 提出任务
2. AI 完成任务
3. 自动发送 Webhook 通知
4. 你在机器人平台收到通知

## 配置

安装脚本会在你选择的平台目录下创建 `config.json`：

```json
{
  "platform": "feishu",
  "webhook_url": "https://open.feishu.cn/open-apis/bot/v2/hook/xxx",
  "timeout": 5000
}
```

### 支持的平台

| 平台         | URL 格式                                                   |
| ------------ | ---------------------------------------------------------- |
| **飞书**     | `https://open.feishu.cn/open-apis/bot/v2/hook/xxx`         |
| **钉钉**     | `https://oapi.dingtalk.com/robot/send?access_token=xxx`    |
| **企业微信** | `https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx` |
| **Slack**    | `https://hooks.slack.com/services/xxx/xxx/xxx`             |
| **自定义**   | 任何接受 POST 请求的 Webhook 端点                          |

## 手动通知

也可以手动触发通知（将 `<platform>` 替换为你选择的平台目录）：

```bash
.<platform>/skills/notify-robot/scripts/notify.sh "completed" "任务完成"
```

## 重新配置

要更改 Webhook URL，直接编辑配置文件或重新运行安装脚本：

```bash
# 编辑配置
vim .<platform>/skills/notify-robot/config.json

# 或重新安装
if [ -f /usr/bin/curl ];then curl -sSO https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/install.sh;else wget -O install.sh https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/install.sh;fi;bash install.sh
```

## 卸载

```bash
# 根据你安装时选择的平台目录
rm -rf .<platform>/skills/notify-robot
rm -f .<platform>/rules/notify-robot.md
```

## 故障排查

**通知不工作？**

1. 检查配置文件是否存在：`cat .<platform>/skills/notify-robot/config.json`
2. 手动测试：`.<platform>/skills/notify-robot/scripts/notify.sh "test" "你好"`
3. 验证规则已安装：`ls .<platform>/rules/notify-robot.md`
4. 开始新的 AI 对话（规则在新对话中生效）

**权限被拒绝？**

```bash
chmod +x .<platform>/skills/notify-robot/scripts/*.sh
```

## 项目结构

```
NotifyRobotSkill/
├── setup-notify-robot.sh   # 一键安装脚本
├── SKILL.md                # 技能定义文档
├── config.example.json     # 配置模板
└── rules/
    └── notify-robot.md     # 自动通知规则模板
```

## 许可证

MIT License

## 相关链接

- [Cursor AI](https://cursor.sh/) - AI 优先的代码编辑器
- [Claude](https://claude.ai/) - Anthropic 的 AI 助手
