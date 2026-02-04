---
name: notify-robot
description: Automatically sends webhook notification after each AI conversation turn. Use at the end of every response to notify external robots about task completion status.
---

# Notify Robot Skill

This skill sends a webhook notification to external robots (DingTalk, Slack, Feishu, custom webhook, etc.) after each AI conversation turn.

## Quick Start

After installation, the AI will automatically send notifications at the end of each response.

## How It Works

1. AI completes a task or responds to a question
2. This skill is triggered automatically
3. A POST request is sent to your configured webhook URL
4. The notification includes task status and summary

## Manual Notification

To manually send a notification:

```bash
# From the skill directory
./scripts/notify.sh "completed" "Task finished successfully"
```

## Configuration

The configuration file `config.json` is created during installation:

```json
{
  "webhook_url": "https://your-webhook-url.com/endpoint",
  "headers": {},
  "timeout": 5000
}
```

### Configuration Options

| Option        | Type   | Description                                     |
| ------------- | ------ | ----------------------------------------------- |
| `webhook_url` | string | Your webhook endpoint URL                       |
| `headers`     | object | Custom HTTP headers (optional)                  |
| `timeout`     | number | Request timeout in milliseconds (default: 5000) |

## Notification Format

The webhook receives a POST request with JSON body:

```json
{
  "status": "completed",
  "message": "AI task completed successfully",
  "timestamp": "2025-02-04T12:00:00Z"
}
```

### Status Types

| Status      | Description                |
| ----------- | -------------------------- |
| `completed` | Task finished successfully |
| `error`     | An error occurred          |
| `info`      | Informational message      |

## Updating Webhook URL

To change your webhook URL, either:

1. Edit `config.json` directly
2. Re-run the install script: `curl -fsSL https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/install.sh | bash`

## Troubleshooting

**Notification not sent?**
- Check if `config.json` exists and contains valid webhook URL
- Verify network connectivity to webhook endpoint
- Check webhook service is running and accessible

**Permission denied?**
- Run: `chmod +x scripts/notify.sh`
