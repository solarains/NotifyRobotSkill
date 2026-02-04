#!/bin/bash
#
# Notify Robot Skill - One-Click Installation Script
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/setup-notify-robot.sh | bash
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Interactive menu selection function
select_option() {
    local options=("$@")
    local selected=0
    local total=${#options[@]}
    
    printf "\033[?25l"
    trap 'printf "\033[?25h"' EXIT
    
    for i in "${!options[@]}"; do
        if [ $i -eq $selected ]; then
            echo -e "  ${GREEN}▸ ${options[$i]}${NC}"
        else
            echo -e "    ${options[$i]}"
        fi
    done
    
    while true; do
        read -rsn1 key
        
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case "$key" in
                '[A') ((selected--)) || true; [ $selected -lt 0 ] && selected=$((total - 1));;
                '[B') ((selected++)) || true; [ $selected -ge $total ] && selected=0;;
            esac
            
            printf "\033[${total}A"
            for i in "${!options[@]}"; do
                printf "\033[2K"
                if [ $i -eq $selected ]; then
                    echo -e "  ${GREEN}▸ ${options[$i]}${NC}"
                else
                    echo -e "    ${options[$i]}"
                fi
            done
        elif [[ $key == "" ]]; then
            break
        fi
    done
    
    printf "\033[?25h"
    trap - EXIT
    SELECTED_INDEX=$selected
}

# Banner
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}          ${GREEN}Notify Robot Skill - Installation${NC}                   ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if running in a project directory
if [ ! -d ".git" ] && [ ! -f "package.json" ] && [ ! -f "Cargo.toml" ] && [ ! -f "go.mod" ] && [ ! -f "pyproject.toml" ]; then
    echo -e "${YELLOW}Warning: This doesn't appear to be a project root directory.${NC}"
    echo ""
fi

# Step 1: Select target platform
echo -e "${BLUE}[1/4] Select target platform (使用上下键选择，回车确认):${NC}"
echo ""
select_option "Claude Code (安装到 .claude)" "Cursor (安装到 .cursor)" "Other (安装到 .agent)"

case $SELECTED_INDEX in
    0) TARGET_DIR=".claude";;
    1) TARGET_DIR=".cursor";;
    2) TARGET_DIR=".agent";;
esac

echo ""
echo -e "Selected: ${GREEN}${TARGET_DIR}${NC}"
echo ""

# Set paths
SKILL_DIR="${PWD}/${TARGET_DIR}/skills/notify-robot"
RULES_DIR="${PWD}/${TARGET_DIR}/rules"
SCRIPTS_DIR="${SKILL_DIR}/scripts"

# Step 2: Select robot platform
echo -e "${BLUE}[2/4] Select your robot platform (使用上下键选择):${NC}"
echo ""
select_option "Feishu (飞书)" "DingTalk (钉钉)" "WeCom (企业微信)" "Slack" "Custom webhook (自定义)"

case $SELECTED_INDEX in
    0) PLATFORM="feishu";;
    1) PLATFORM="dingtalk";;
    2) PLATFORM="wecom";;
    3) PLATFORM="slack";;
    4) PLATFORM="custom";;
esac

echo ""
echo -e "Selected: ${GREEN}${PLATFORM}${NC}"
echo ""

# Step 3: Enter webhook URL
echo -e "${BLUE}[3/4] Enter your webhook URL:${NC}"
case "$PLATFORM" in
    feishu)   echo "Example: https://open.feishu.cn/open-apis/bot/v2/hook/xxx";;
    dingtalk) echo "Example: https://oapi.dingtalk.com/robot/send?access_token=xxx";;
    wecom)    echo "Example: https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx";;
    slack)    echo "Example: https://hooks.slack.com/services/xxx/xxx/xxx";;
    custom)   echo "Example: https://your-server.com/webhook";;
esac
echo ""

while true; do
    read -p "Webhook URL: " WEBHOOK_URL
    if [[ "$WEBHOOK_URL" =~ ^https?:// ]]; then
        break
    else
        echo -e "${RED}Invalid URL format. URL must start with http:// or https://${NC}"
    fi
done

echo ""

# Step 4: Create files
echo -e "${BLUE}[4/4] Installing files...${NC}"
echo ""

# Create directories
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$RULES_DIR"

# Create config.json
cat > "${SKILL_DIR}/config.json" << EOF
{
  "platform": "${PLATFORM}",
  "webhook_url": "${WEBHOOK_URL}",
  "timeout": 5000
}
EOF
echo "  ✓ ${TARGET_DIR}/skills/notify-robot/config.json"

# Create SKILL.md
cat > "${SKILL_DIR}/SKILL.md" << 'EOF'
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
./scripts/notify.sh "completed" "Task finished successfully"
```

## Configuration

The configuration file `config.json`:

```json
{
  "webhook_url": "https://your-webhook-url.com/endpoint",
  "timeout": 5000
}
```

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
EOF
echo "  ✓ ${TARGET_DIR}/skills/notify-robot/SKILL.md"

# Create notify.sh
cat > "${SCRIPTS_DIR}/notify.sh" << 'NOTIFY_SCRIPT'
#!/bin/bash
#
# Notify Robot - Send webhook notification
# Usage: ./notify.sh <status> <message>
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(dirname "$SCRIPT_DIR")"
CONFIG_FILE="${SKILL_DIR}/config.json"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ ! -f "$CONFIG_FILE" ]; then
    echo -e "${RED}Error: config.json not found${NC}"
    exit 1
fi

STATUS="${1:-info}"
MESSAGE="${2:-AI task notification}"

if command -v jq &> /dev/null; then
    WEBHOOK_URL=$(jq -r '.webhook_url' "$CONFIG_FILE")
    PLATFORM=$(jq -r '.platform // "custom"' "$CONFIG_FILE")
    TIMEOUT=$(jq -r '.timeout // 5000' "$CONFIG_FILE")
else
    WEBHOOK_URL=$(grep -o '"webhook_url"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*: *"\([^"]*\)"/\1/')
    PLATFORM=$(grep -o '"platform"[[:space:]]*:[[:space:]]*"[^"]*"' "$CONFIG_FILE" | sed 's/.*: *"\([^"]*\)"/\1/')
    TIMEOUT=5000
fi

[ -z "$PLATFORM" ] && PLATFORM="custom"

if [ -z "$WEBHOOK_URL" ] || [ "$WEBHOOK_URL" = "null" ]; then
    echo -e "${RED}Error: webhook_url not configured${NC}"
    exit 1
fi

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
FULL_MESSAGE="[${STATUS}] ${MESSAGE}"

case "$PLATFORM" in
    feishu)
        JSON_PAYLOAD="{\"msg_type\":\"text\",\"content\":{\"text\":\"${FULL_MESSAGE}\"}}"
        ;;
    dingtalk)
        JSON_PAYLOAD="{\"msgtype\":\"text\",\"text\":{\"content\":\"${FULL_MESSAGE}\"}}"
        ;;
    wecom)
        JSON_PAYLOAD="{\"msgtype\":\"text\",\"text\":{\"content\":\"${FULL_MESSAGE}\"}}"
        ;;
    slack)
        JSON_PAYLOAD="{\"text\":\"${FULL_MESSAGE}\"}"
        ;;
    *)
        JSON_PAYLOAD="{\"status\":\"${STATUS}\",\"message\":\"${MESSAGE}\",\"timestamp\":\"${TIMESTAMP}\"}"
        ;;
esac

TIMEOUT_SECONDS=$((TIMEOUT / 1000))
[ "$TIMEOUT_SECONDS" -lt 1 ] && TIMEOUT_SECONDS=5

HTTP_RESPONSE=$(curl -s -w "\n%{http_code}" \
    --max-time "$TIMEOUT_SECONDS" \
    -X POST "$WEBHOOK_URL" \
    -H "Content-Type: application/json" \
    -d "$JSON_PAYLOAD" 2>&1) || {
    echo -e "${RED}Error: Failed to send notification${NC}"
    exit 1
}

HTTP_BODY=$(echo "$HTTP_RESPONSE" | sed '$d')
HTTP_CODE=$(echo "$HTTP_RESPONSE" | tail -n 1)

if [[ "$HTTP_CODE" =~ ^2[0-9][0-9]$ ]]; then
    echo -e "${GREEN}Notification sent successfully${NC}"
    echo "  Status: $STATUS"
    echo "  Message: $MESSAGE"
else
    echo -e "${YELLOW}Warning: Webhook returned HTTP $HTTP_CODE${NC}"
    [ -n "$HTTP_BODY" ] && echo "  Response: $HTTP_BODY"
fi
NOTIFY_SCRIPT
chmod +x "${SCRIPTS_DIR}/notify.sh"
echo "  ✓ ${TARGET_DIR}/skills/notify-robot/scripts/notify.sh"

# Create rules file with correct path
cat > "${RULES_DIR}/notify-robot.md" << RULES_EOF
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

\`\`\`bash
${TARGET_DIR}/skills/notify-robot/scripts/notify.sh "<status>" "<message>"
\`\`\`

## Status Guidelines

| Scenario                    | Status      | Example Message                     |
| --------------------------- | ----------- | ----------------------------------- |
| Task completed successfully | \`completed\` | "Code changes applied successfully" |
| Question answered           | \`completed\` | "Query answered"                    |
| Error occurred              | \`error\`     | "Failed to complete task: reason"   |
| Partial completion          | \`info\`      | "Partial progress made"             |

## Example

After editing a file:
\`\`\`bash
${TARGET_DIR}/skills/notify-robot/scripts/notify.sh "completed" "Updated src/main.ts with new feature"
\`\`\`
RULES_EOF
echo "  ✓ ${TARGET_DIR}/rules/notify-robot.md"

# Installation complete
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║${NC}              Installation Complete!                          ${GREEN}║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Test notification
read -p "Send a test notification now? (Y/n): " SEND_TEST
if [[ ! "$SEND_TEST" =~ ^[Nn]$ ]]; then
    echo ""
    echo -e "${BLUE}Sending test notification...${NC}"
    if "${SCRIPTS_DIR}/notify.sh" "test" "Hello from NotifyRobotSkill! Installation successful."; then
        echo ""
        echo -e "${GREEN}Test notification sent successfully!${NC}"
    else
        echo ""
        echo -e "${YELLOW}Test notification may have failed. Please check your webhook URL.${NC}"
    fi
fi

echo ""
echo -e "${BLUE}Usage:${NC}"
echo "  Manual:  ${TARGET_DIR}/skills/notify-robot/scripts/notify.sh \"completed\" \"Your message\""
echo "  Auto:    Rules installed, notifications will be sent automatically"
echo ""

# Self-delete
SCRIPT_NAME="$(basename "$0")"
if [ -f "./${SCRIPT_NAME}" ]; then
    rm -f "./${SCRIPT_NAME}"
    echo -e "${GREEN}Installer script removed.${NC}"
fi
echo ""
