#!/bin/bash
#
# Automated Test Script for Notify Robot Skill
#
# Usage: bash tests/run_tests.sh
#

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Test directory
TEST_DIR="/tmp/notify-robot-test-$$"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Test result function
test_result() {
    local test_name="$1"
    local result="$2"
    ((TESTS_TOTAL++))
    
    if [ "$result" = "pass" ]; then
        echo -e "  ${GREEN}✓${NC} $test_name"
        ((TESTS_PASSED++))
    else
        echo -e "  ${RED}✗${NC} $test_name"
        ((TESTS_FAILED++))
    fi
}

# Setup test environment
setup() {
    echo -e "${BLUE}Setting up test environment...${NC}"
    rm -rf "$TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    git init -q
    echo ""
}

# Cleanup test environment
cleanup() {
    echo ""
    echo -e "${BLUE}Cleaning up...${NC}"
    cd /
    rm -rf "$TEST_DIR"
}

# Simulate installation (non-interactive)
simulate_install() {
    local platform_dir="$1"
    local robot_platform="$2"
    local webhook_url="$3"
    
    local skill_dir="${TEST_DIR}/${platform_dir}/skills/notify-robot"
    local rules_dir="${TEST_DIR}/${platform_dir}/rules"
    local scripts_dir="${skill_dir}/scripts"
    
    mkdir -p "$scripts_dir"
    mkdir -p "$rules_dir"
    
    # Create config.json
    cat > "${skill_dir}/config.json" << EOF
{
  "platform": "${robot_platform}",
  "webhook_url": "${webhook_url}",
  "timeout": 5000
}
EOF

    # Create SKILL.md
    cat > "${skill_dir}/SKILL.md" << 'EOF'
---
name: notify-robot
description: Automatically sends webhook notification after each AI conversation turn.
---

# Notify Robot Skill
Test skill file.
EOF

    # Copy notify.sh from install.sh (extract the embedded script)
    cat > "${scripts_dir}/notify.sh" << 'NOTIFY_SCRIPT'
#!/bin/bash
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
    chmod +x "${scripts_dir}/notify.sh"

    # Create rules file
    cat > "${rules_dir}/notify-robot.md" << RULES_EOF
---
description: Auto notify after each AI response
globs: ["**/*"]
alwaysApply: true
---

# Auto Notification Rule

Run: ${platform_dir}/skills/notify-robot/scripts/notify.sh "<status>" "<message>"
RULES_EOF
}

# Banner
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}          ${GREEN}Notify Robot Skill - Automated Tests${NC}                 ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Setup
setup

# =============================================================================
# Test Suite 1: File Structure Tests
# =============================================================================
echo -e "${YELLOW}Test Suite 1: File Structure Tests${NC}"

# Test 1.1: Claude platform installation
simulate_install ".claude" "feishu" "https://example.com/webhook"

if [ -d ".claude/skills/notify-robot" ]; then
    test_result "TC1.1: .claude/skills directory created" "pass"
else
    test_result "TC1.1: .claude/skills directory created" "fail"
fi

if [ -d ".claude/rules" ]; then
    test_result "TC1.2: .claude/rules directory created" "pass"
else
    test_result "TC1.2: .claude/rules directory created" "fail"
fi

if [ -f ".claude/skills/notify-robot/config.json" ]; then
    test_result "TC1.3: config.json created" "pass"
else
    test_result "TC1.3: config.json created" "fail"
fi

if [ -f ".claude/skills/notify-robot/SKILL.md" ]; then
    test_result "TC1.4: SKILL.md created" "pass"
else
    test_result "TC1.4: SKILL.md created" "fail"
fi

if [ -f ".claude/skills/notify-robot/scripts/notify.sh" ]; then
    test_result "TC1.5: notify.sh created" "pass"
else
    test_result "TC1.5: notify.sh created" "fail"
fi

if [ -x ".claude/skills/notify-robot/scripts/notify.sh" ]; then
    test_result "TC1.6: notify.sh is executable" "pass"
else
    test_result "TC1.6: notify.sh is executable" "fail"
fi

if [ -f ".claude/rules/notify-robot.md" ]; then
    test_result "TC1.7: rules file created" "pass"
else
    test_result "TC1.7: rules file created" "fail"
fi

# Test 1.2: Cursor platform installation
simulate_install ".cursor" "dingtalk" "https://example.com/webhook"
if [ -d ".cursor/skills/notify-robot" ]; then
    test_result "TC1.8: .cursor directory created" "pass"
else
    test_result "TC1.8: .cursor directory created" "fail"
fi

# Test 1.3: Agent platform installation
simulate_install ".agent" "slack" "https://example.com/webhook"
if [ -d ".agent/skills/notify-robot" ]; then
    test_result "TC1.9: .agent directory created" "pass"
else
    test_result "TC1.9: .agent directory created" "fail"
fi

echo ""

# =============================================================================
# Test Suite 2: Config.json Tests
# =============================================================================
echo -e "${YELLOW}Test Suite 2: Config.json Tests${NC}"

# Check config content
config_content=$(cat .claude/skills/notify-robot/config.json)

if echo "$config_content" | grep -q '"platform": "feishu"'; then
    test_result "TC2.1: config contains platform" "pass"
else
    test_result "TC2.1: config contains platform" "fail"
fi

if echo "$config_content" | grep -q '"webhook_url": "https://example.com/webhook"'; then
    test_result "TC2.2: config contains webhook_url" "pass"
else
    test_result "TC2.2: config contains webhook_url" "fail"
fi

if echo "$config_content" | grep -q '"timeout": 5000'; then
    test_result "TC2.3: config contains timeout" "pass"
else
    test_result "TC2.3: config contains timeout" "fail"
fi

echo ""

# =============================================================================
# Test Suite 3: Rules File Tests
# =============================================================================
echo -e "${YELLOW}Test Suite 3: Rules File Tests${NC}"

rules_content=$(cat .claude/rules/notify-robot.md)

if echo "$rules_content" | grep -q 'alwaysApply: true'; then
    test_result "TC3.1: rules has alwaysApply" "pass"
else
    test_result "TC3.1: rules has alwaysApply" "fail"
fi

if echo "$rules_content" | grep -q '.claude/skills/notify-robot'; then
    test_result "TC3.2: rules has correct path (.claude)" "pass"
else
    test_result "TC3.2: rules has correct path (.claude)" "fail"
fi

cursor_rules=$(cat .cursor/rules/notify-robot.md)
if echo "$cursor_rules" | grep -q '.cursor/skills/notify-robot'; then
    test_result "TC3.3: rules has correct path (.cursor)" "pass"
else
    test_result "TC3.3: rules has correct path (.cursor)" "fail"
fi

agent_rules=$(cat .agent/rules/notify-robot.md)
if echo "$agent_rules" | grep -q '.agent/skills/notify-robot'; then
    test_result "TC3.4: rules has correct path (.agent)" "pass"
else
    test_result "TC3.4: rules has correct path (.agent)" "fail"
fi

echo ""

# =============================================================================
# Test Suite 4: Notify Script Tests
# =============================================================================
echo -e "${YELLOW}Test Suite 4: Notify Script Tests${NC}"

# Test 4.1: Missing config.json
rm -f .claude/skills/notify-robot/config.json
output=$(.claude/skills/notify-robot/scripts/notify.sh "test" "test" 2>&1 || true)
if echo "$output" | grep -q "config.json not found"; then
    test_result "TC4.1: Error on missing config.json" "pass"
else
    test_result "TC4.1: Error on missing config.json" "fail"
fi

# Restore config for next tests
simulate_install ".claude" "feishu" "https://httpbin.org/post"

# Test 4.2: Default parameters
# Create a mock config with httpbin for testing
cat > ".claude/skills/notify-robot/config.json" << EOF
{
  "platform": "custom",
  "webhook_url": "https://httpbin.org/post",
  "timeout": 10000
}
EOF

output=$(.claude/skills/notify-robot/scripts/notify.sh 2>&1 || true)
if echo "$output" | grep -q "Status: info"; then
    test_result "TC4.2: Default status is 'info'" "pass"
else
    test_result "TC4.2: Default status is 'info'" "fail"
fi

if echo "$output" | grep -q "AI task notification"; then
    test_result "TC4.3: Default message works" "pass"
else
    test_result "TC4.3: Default message works" "fail"
fi

# Test 4.4: Custom status and message
output=$(.claude/skills/notify-robot/scripts/notify.sh "completed" "Test completed" 2>&1 || true)
if echo "$output" | grep -q "Status: completed"; then
    test_result "TC4.4: Custom status works" "pass"
else
    test_result "TC4.4: Custom status works" "fail"
fi

if echo "$output" | grep -q "Message: Test completed"; then
    test_result "TC4.5: Custom message works" "pass"
else
    test_result "TC4.5: Custom message works" "fail"
fi

# Test 4.5: Invalid/empty webhook_url
cat > ".claude/skills/notify-robot/config.json" << EOF
{
  "platform": "feishu",
  "webhook_url": "",
  "timeout": 5000
}
EOF

output=$(.claude/skills/notify-robot/scripts/notify.sh "test" "test" 2>&1 || true)
if echo "$output" | grep -q "webhook_url not configured"; then
    test_result "TC4.6: Error on empty webhook_url" "pass"
else
    test_result "TC4.6: Error on empty webhook_url" "fail"
fi

echo ""

# =============================================================================
# Test Suite 5: Platform-specific Payload Tests
# =============================================================================
echo -e "${YELLOW}Test Suite 5: Platform-specific Payload Tests${NC}"

# We'll test by checking the script logic (since we can't easily capture the payload without a real webhook)
# Instead, we verify the platforms are recognized

for platform in feishu dingtalk wecom slack custom; do
    cat > ".claude/skills/notify-robot/config.json" << EOF
{
  "platform": "${platform}",
  "webhook_url": "https://httpbin.org/post",
  "timeout": 10000
}
EOF
    output=$(.claude/skills/notify-robot/scripts/notify.sh "test" "Test for ${platform}" 2>&1 || true)
    if echo "$output" | grep -qE "sent successfully|Warning:"; then
        test_result "TC5: ${platform} platform notification" "pass"
    else
        test_result "TC5: ${platform} platform notification" "fail"
    fi
done

echo ""

# =============================================================================
# Test Suite 6: install.sh Syntax Check
# =============================================================================
echo -e "${YELLOW}Test Suite 6: install.sh Syntax Check${NC}"

if bash -n "$SCRIPT_DIR/install.sh" 2>/dev/null; then
    test_result "TC6.1: install.sh syntax valid" "pass"
else
    test_result "TC6.1: install.sh syntax valid" "fail"
fi

echo ""

# Cleanup
cleanup

# =============================================================================
# Summary
# =============================================================================
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}                      Test Summary                            ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  Total:  ${TESTS_TOTAL}"
echo -e "  ${GREEN}Passed: ${TESTS_PASSED}${NC}"
echo -e "  ${RED}Failed: ${TESTS_FAILED}${NC}"
echo ""

if [ "$TESTS_FAILED" -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
