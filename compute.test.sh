#!/bin/bash

# Unit tests for compute.sh
# Tests the addition operation and error handling

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    local expected="$2"
    shift 2
    local actual=$("$@" 2>&1)
    
    TESTS_RUN=$((TESTS_RUN + 1))
    
    if [ "$actual" = "$expected" ]; then
        echo -e "${GREEN}✓${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} $test_name"
        echo "  Expected: $expected"
        echo "  Actual: $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Helper function to extract JSON field
extract_json_field() {
    local json="$1"
    local field="$2"
    echo "$json" | grep -o "\"$field\": [^,}]*" | cut -d':' -f2 | xargs
}

# Helper function to check if JSON is valid
is_valid_json() {
    local json="$1"
    echo "$json" | jq empty 2>/dev/null
    return $?
}

# Test 1: Addition with positive integers
test_add_positive_integers() {
    local output=$(./compute.sh add 2 3)
    local status=$(echo "$output" | jq -r '.status')
    local result=$(echo "$output" | jq -r '.result')
    
    if [ "$status" = "success" ] && [ "$result" = "5" ]; then
        echo -e "${GREEN}✓${NC} Test 1: Addition with positive integers (2 + 3 = 5)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 1: Addition with positive integers"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 2: Addition with negative numbers
test_add_negative_numbers() {
    local output=$(./compute.sh add -5 -3)
    local status=$(echo "$output" | jq -r '.status')
    local result=$(echo "$output" | jq -r '.result')
    
    if [ "$status" = "success" ] && [ "$result" = "-8" ]; then
        echo -e "${GREEN}✓${NC} Test 2: Addition with negative numbers (-5 + -3 = -8)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 2: Addition with negative numbers"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 3: Addition with floating-point numbers
test_add_floats() {
    local output=$(./compute.sh add 2.5 3.5)
    local status=$(echo "$output" | jq -r '.status')
    local result=$(echo "$output" | jq -r '.result')
    
    # bc may return 6 or 6.0, both are correct
    if [ "$status" = "success" ] && ([ "$result" = "6" ] || [ "$result" = "6.0" ]); then
        echo -e "${GREEN}✓${NC} Test 3: Addition with floating-point numbers (2.5 + 3.5 = 6)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 3: Addition with floating-point numbers"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 4: Invalid action handling
test_invalid_action() {
    local output=$(./compute.sh invalid 2 3)
    local status=$(echo "$output" | jq -r '.status')
    local error=$(echo "$output" | jq -r '.error')
    
    if [ "$status" = "error" ] && [[ "$error" == *"Unknown action"* ]]; then
        echo -e "${GREEN}✓${NC} Test 4: Invalid action handling"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 4: Invalid action handling"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 5: Non-numeric argument handling
test_non_numeric_argument() {
    local output=$(./compute.sh add 2 abc)
    local status=$(echo "$output" | jq -r '.status')
    local error=$(echo "$output" | jq -r '.error')
    
    if [ "$status" = "error" ] && [[ "$error" == *"not numeric"* ]]; then
        echo -e "${GREEN}✓${NC} Test 5: Non-numeric argument handling"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 5: Non-numeric argument handling"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 6: Missing argument handling
test_missing_argument() {
    local output=$(./compute.sh add 2)
    local status=$(echo "$output" | jq -r '.status')
    local error=$(echo "$output" | jq -r '.error')
    
    if [ "$status" = "error" ] && [[ "$error" == *"Missing arguments"* ]]; then
        echo -e "${GREEN}✓${NC} Test 6: Missing argument handling"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 6: Missing argument handling"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 7: Response contains valid JSON
test_valid_json_response() {
    local output=$(./compute.sh add 1 2)
    
    if is_valid_json "$output"; then
        echo -e "${GREEN}✓${NC} Test 7: Response contains valid JSON"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 7: Response contains valid JSON"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 8: Response has required fields
test_response_fields() {
    local output=$(./compute.sh add 1 2)
    local has_status=$(echo "$output" | jq 'has("status")')
    local has_data=$(echo "$output" | jq 'has("data")')
    local has_result=$(echo "$output" | jq 'has("result")')
    
    if [ "$has_status" = "true" ] && [ "$has_data" = "true" ] && [ "$has_result" = "true" ]; then
        echo -e "${GREEN}✓${NC} Test 8: Response has required fields (status, data, result)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 8: Response has required fields"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 9: Error response has error field
test_error_response_fields() {
    local output=$(./compute.sh add abc def)
    local has_error=$(echo "$output" | jq 'has("error")')
    
    if [ "$has_error" = "true" ]; then
        echo -e "${GREEN}✓${NC} Test 9: Error response has error field"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 9: Error response has error field"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Test 10: Mixed positive and negative
test_mixed_positive_negative() {
    local output=$(./compute.sh add 10 -3)
    local status=$(echo "$output" | jq -r '.status')
    local result=$(echo "$output" | jq -r '.result')
    
    if [ "$status" = "success" ] && [ "$result" = "7" ]; then
        echo -e "${GREEN}✓${NC} Test 10: Mixed positive and negative (10 + -3 = 7)"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}✗${NC} Test 10: Mixed positive and negative"
        echo "  Output: $output"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
    TESTS_RUN=$((TESTS_RUN + 1))
}

# Run all tests
echo "Running unit tests for compute.sh..."
echo ""

test_add_positive_integers
test_add_negative_numbers
test_add_floats
test_invalid_action
test_non_numeric_argument
test_missing_argument
test_valid_json_response
test_response_fields
test_error_response_fields
test_mixed_positive_negative

echo ""
echo "Test Results: $TESTS_PASSED/$TESTS_RUN passed"

if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}$TESTS_FAILED tests failed${NC}"
    exit 1
else
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi
