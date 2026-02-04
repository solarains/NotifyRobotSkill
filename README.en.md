# Notify Robot Skill

> A Cursor AI skill that automatically sends webhook notifications after each AI conversation turn.

[中文文档](./README.md)

## Features

- 🤖 **Automatic Notifications** - Sends webhook notification after every AI response
- 🌐 **Universal Support** - Works with Feishu, DingTalk, WeCom, Slack, and any custom webhook
- ⚡ **Easy Setup** - Two-line installation
- 🎯 **Smart Rules** - Optional auto-trigger rules for hands-free operation
- 🔒 **Secure** - Config files stay local (automatically ignored by git)

## Quick Install

```bash
if [ -f /usr/bin/curl ]; then
    curl -sSO https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/setup-notify-robot.sh
else
    wget -O setup-notify-robot.sh https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/setup-notify-robot.sh
fi && bash setup-notify-robot.sh
```

The setup wizard will guide you through:
1. Selecting target platform (Claude Code / Cursor / Other)
2. Selecting robot platform (Feishu/DingTalk/WeCom/Slack/Custom)
3. Entering webhook URL
4. Testing notification

## How It Works

Once installed with rules enabled:

1. You ask AI to do something
2. AI completes the task
3. Webhook notification is automatically sent
4. You get notified on your robot platform

## Configuration

The installer creates `config.json` in your chosen platform directory:

```json
{
  "platform": "feishu",
  "webhook_url": "https://open.feishu.cn/open-apis/bot/v2/hook/xxx",
  "timeout": 5000
}
```

### Supported Platforms

| Platform     | URL Format                                                 |
| ------------ | ---------------------------------------------------------- |
| **Feishu**   | `https://open.feishu.cn/open-apis/bot/v2/hook/xxx`         |
| **DingTalk** | `https://oapi.dingtalk.com/robot/send?access_token=xxx`    |
| **WeCom**    | `https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx` |
| **Slack**    | `https://hooks.slack.com/services/xxx/xxx/xxx`             |
| **Custom**   | Any webhook endpoint accepting POST requests               |

## Manual Notification

You can also trigger notifications manually (replace `<platform>` with your chosen platform directory):

```bash
.<platform>/skills/notify-robot/scripts/notify.sh "completed" "Task finished"
```

## Reconfigure

To change webhook URL, edit the config file directly or re-run the installer:

```bash
# Edit config
vim .<platform>/skills/notify-robot/config.json

# Or reinstall
if [ -f /usr/bin/curl ];then curl -sSO https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/install.sh;else wget -O install.sh https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/install.sh;fi;bash install.sh
```

## Uninstall

```bash
# Based on your chosen platform directory
rm -rf .<platform>/skills/notify-robot
rm -f .<platform>/rules/notify-robot.md
```

## Troubleshooting

**Notifications not working?**

1. Check config exists: `cat .<platform>/skills/notify-robot/config.json`
2. Test manually: `.<platform>/skills/notify-robot/scripts/notify.sh "test" "Hello"`
3. Verify rules installed: `ls .<platform>/rules/notify-robot.md`
4. Start a new AI conversation (rules take effect in new conversations)

**Permission denied?**

```bash
chmod +x .<platform>/skills/notify-robot/scripts/*.sh
```

## Project Structure

```
NotifyRobotSkill/
├── setup-notify-robot.sh   # One-click installation script
├── SKILL.md                # Skill definition document
├── config.example.json     # Config template
└── rules/
    └── notify-robot.md     # Auto-notification rules template
```

## License

MIT License

## Related

- [Cursor AI](https://cursor.sh/) - AI-first code editor
- [Claude](https://claude.ai/) - Anthropic's AI assistant
