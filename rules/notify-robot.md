---
description: Auto notify after each AI response
globs: ["**/*"]
alwaysApply: true
---

# Auto Notification Rule

At the end of every response, execute the notify-robot skill to send a webhook notification with task completion status.

## When to Send Notifications

Send a notification after:
- Completing a code editing task
- Answering a question
- Finishing a multi-step operation
- Encountering an error

## How to Notify

Run the notification script:

```bash
.claude/skills/notify-robot/scripts/notify.sh "<status>" "<message>"
```

## Status Guidelines

| Scenario                    | Status      | Example Message                     |
| --------------------------- | ----------- | ----------------------------------- |
| Task completed successfully | `completed` | "Code changes applied successfully" |
| Question answered           | `completed` | "Query answered"                    |
| Error occurred              | `error`     | "Failed to complete task: reason"   |
| Partial completion          | `info`      | "Partial progress made"             |

## Example

After editing a file:
```bash
.claude/skills/notify-robot/scripts/notify.sh "completed" "Updated src/main.ts with new feature"
```
