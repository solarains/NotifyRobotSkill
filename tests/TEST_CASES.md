# Test Cases for Notify Robot Skill

This document contains test cases for verifying the Notify Robot Skill functionality.

## Test Environment Setup

Before running tests, ensure you have:
1. A test webhook endpoint (use https://webhook.site for testing)
2. curl installed
3. bash shell

## Automated Tests

Run the automated test script:

```bash
bash tests/run_tests.sh
```

---

## Test Case 1: Installation Script Tests

### TC1.1: Fresh Installation

**Precondition**: Clean test directory

**Steps**:
1. Run `install.sh` in a test directory
2. Select platform (Claude/Cursor/Other)
3. Select robot platform
4. Enter a valid webhook URL

**Expected Result**:
- Directory `.<platform>/skills/notify-robot/` is created
- Directory `.<platform>/rules/` is created
- Files exist: `SKILL.md`, `scripts/notify.sh`, `config.json`
- `scripts/notify.sh` has execute permission
- `config.json` contains the entered webhook URL and platform
- Rules file contains correct path references
- install.sh is deleted after completion

**Verification**:
```bash
ls -la .<platform>/skills/notify-robot/
cat .<platform>/skills/notify-robot/config.json
cat .<platform>/rules/notify-robot.md
```

---

### TC1.2: Installation with Invalid URL

**Steps**:
1. Run the install script
2. Enter an invalid URL (e.g., `not-a-url`)

**Expected Result**:
- Error message: "Invalid URL format. URL must start with http:// or https://"
- Script prompts for URL again

---

### TC1.3: Platform Selection - Claude

**Steps**:
1. Run install script
2. Select "Claude Code"

**Expected Result**:
- Files created in `.claude/skills/notify-robot/`
- Rules created in `.claude/rules/`
- Rules file references `.claude/skills/...`

---

### TC1.4: Platform Selection - Cursor

**Steps**:
1. Run install script
2. Select "Cursor"

**Expected Result**:
- Files created in `.cursor/skills/notify-robot/`
- Rules created in `.cursor/rules/`
- Rules file references `.cursor/skills/...`

---

### TC1.5: Platform Selection - Other

**Steps**:
1. Run install script
2. Select "Other"

**Expected Result**:
- Files created in `.agent/skills/notify-robot/`
- Rules created in `.agent/rules/`
- Rules file references `.agent/skills/...`

---

## Test Case 2: Notification Script Tests

### TC2.1: Successful Notification (Feishu)

**Precondition**: Valid `config.json` with feishu platform

**Steps**:
1. Run: `.<platform>/skills/notify-robot/scripts/notify.sh "completed" "Test message"`

**Expected Result**:
- Output: "Notification sent successfully"
- JSON payload format: `{"msg_type":"text","content":{"text":"[completed] Test message"}}`

---

### TC2.2: Successful Notification (DingTalk)

**Precondition**: Valid `config.json` with dingtalk platform

**Expected Result**:
- JSON payload format: `{"msgtype":"text","text":{"content":"[completed] Test message"}}`

---

### TC2.3: Successful Notification (WeCom)

**Precondition**: Valid `config.json` with wecom platform

**Expected Result**:
- JSON payload format: `{"msgtype":"text","text":{"content":"[completed] Test message"}}`

---

### TC2.4: Successful Notification (Slack)

**Precondition**: Valid `config.json` with slack platform

**Expected Result**:
- JSON payload format: `{"text":"[completed] Test message"}`

---

### TC2.5: Successful Notification (Custom)

**Precondition**: Valid `config.json` with custom platform

**Expected Result**:
- JSON payload format: `{"status":"completed","message":"Test message","timestamp":"..."}`

---

### TC2.6: Notification with Invalid Webhook URL

**Precondition**: `config.json` with invalid/unreachable webhook URL

**Steps**:
1. Edit `config.json` to use `https://invalid.example.com/webhook`
2. Run: `.<platform>/skills/notify-robot/scripts/notify.sh "test" "Test"`

**Expected Result**:
- Error message displayed
- Script exits with non-zero code

---

### TC2.7: Notification without config.json

**Precondition**: No `config.json` file exists

**Steps**:
1. Remove `config.json`
2. Run: `.<platform>/skills/notify-robot/scripts/notify.sh "test" "Test"`

**Expected Result**:
- Error: "config.json not found"
- Exit code: 1

---

### TC2.8: Notification with Default Parameters

**Precondition**: Valid configuration

**Steps**:
1. Run: `.<platform>/skills/notify-robot/scripts/notify.sh`

**Expected Result**:
- Notification sent with default status "info"
- Default message "AI task notification"

---

### TC2.9: Notification with jq Available

**Precondition**: jq is installed

**Steps**:
1. Ensure jq is in PATH
2. Run notification

**Expected Result**:
- Config parsed using jq
- Notification sent successfully

---

### TC2.10: Notification without jq (Fallback)

**Precondition**: jq is not available

**Steps**:
1. Run notification with jq removed from PATH

**Expected Result**:
- Config parsed using grep/sed fallback
- Notification sent successfully

---

## Test Case 3: File Structure Tests

### TC3.1: SKILL.md Content

**Expected Content**:
- YAML frontmatter with name and description
- Documentation for manual notification
- Configuration example
- Status types table

---

### TC3.2: Rules File Content

**Expected Content**:
- YAML frontmatter with globs and alwaysApply
- Correct platform path references
- Status guidelines table
- Example usage

---

### TC3.3: Config.json Structure

**Expected Content**:
```json
{
  "platform": "<selected_platform>",
  "webhook_url": "<entered_url>",
  "timeout": 5000
}
```

---

## Test Case 4: Self-Delete Tests

### TC4.1: Installer Self-Delete

**Steps**:
1. Copy install.sh to test directory as `install.sh`
2. Run the installer
3. Complete installation

**Expected Result**:
- install.sh is deleted after successful installation
- Message: "Installer script removed."

---

### TC4.2: Installer Not Self-Delete on Different Name

**Steps**:
1. Rename install.sh to `setup.sh`
2. Run `bash setup.sh`

**Expected Result**:
- setup.sh is NOT deleted (only deletes if named install.sh in current directory)

---

## Test Webhook Endpoints

For testing, you can use these services:

1. **webhook.site** - https://webhook.site (free, temporary endpoints)
2. **RequestBin** - https://pipedream.com/requestbin (free, inspect requests)
3. **Beeceptor** - https://beeceptor.com (free, mock APIs)

---

## Quick Manual Test

```bash
# 1. Create test directory
mkdir -p /tmp/test-notify-robot && cd /tmp/test-notify-robot
git init

# 2. Download and run installer
curl -sSO https://raw.githubusercontent.com/solarains/NotifyRobotSkill/main/install.sh
bash install.sh

# 3. Test notification (after selecting platform, use webhook.site URL)
# Get your test URL from https://webhook.site first

# 4. Verify files
ls -la .claude/skills/notify-robot/  # or .cursor/ or .agent/
cat .claude/rules/notify-robot.md

# 5. Clean up
cd ~ && rm -rf /tmp/test-notify-robot
```
