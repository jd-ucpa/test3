#!/bin/bash

# Property-Based Tests for compute.sh
# Tests universal properties that should hold for all inputs

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Test counters
PROPERTIES_TESTED=0
PROPERTIES_PASSED=0
PROPERTIES_FAILED=0

# Helper function to check if JSON is valid
is_valid_json() {
    local json="$1"
    echo "$json" | jq empty 2>/dev/null
    return $?
}

# Property 1: For any two numbers a and b, `add a b` returns a + b
# **Validates: Requirements 1.1**
test_property_1_addition_correctness() {
    echo "Testing Property 1: For any two numbers a and b, add a b returns a + b"
    
    local test_cases=(
        "0 0"
        "1 1"
        "5 3"
        "10 20"
        "-5 -3"
        "-10 5"
        "2.5 3.5"
        "0.1 0.2"
        "-2.5 1.5"
        "100 -50"
    )
    
    local property_passed=true
    
    for test_case in "${test_cases[@]}"; do
        local a=$(echo "$test_case" | cut -d' ' -f1)
        local b=$(echo "$test_case" | cut -d' ' -f2)
        
        local output=$(./compute.sh add "$a" "$b")
        local status=$(echo "$output" | jq -r '.status')
        local result=$(echo "$output" | jq -r '.result')
        
        # Calculate expected result using bc
        local expected=$(echo "$a + $b" | bc)
        
        # Normalize expected value: convert .3 to 0.3
        expected=$(echo "$expected" | sed 's/^\./0./')
        
        if [ "$status" != "success" ] || [ "$result" != "$expected" ]; then
            echo -e "${RED}  ✗ Failed for a=$a, b=$b: expected $expected, got $result${NC}"
            property_passed=false
        fi
    done
    
    if [ "$property_passed" = true ]; then
        echo -e "${GREEN}  ✓ Property 1 passed for all test cases${NC}"
        PROPERTIES_PASSED=$((PROPERTIES_PASSED + 1))
    else
        echo -e "${RED}  ✗ Property 1 failed${NC}"
        PROPERTIES_FAILED=$((PROPERTIES_FAILED + 1))
    fi
    PROPERTIES_TESTED=$((PROPERTIES_TESTED + 1))
}

# Property 2: Addition is commutative: `add a b` equals `add b a`
# **Validates: Requirements 1.1**
test_property_2_commutativity() {
    echo "Testing Property 2: Addition is commutative - add a b equals add b a"
    
    local test_cases=(
        "2 3"
        "5 10"
        "-3 7"
        "2.5 3.5"
        "-1.5 -2.5"
        "0 5"
        "100 -50"
    )
    
    local property_passed=true
    
    for test_case in "${test_cases[@]}"; do
        local a=$(echo "$test_case" | cut -d' ' -f1)
        local b=$(echo "$test_case" | cut -d' ' -f2)
        
        local output_ab=$(./compute.sh add "$a" "$b")
        local result_ab=$(echo "$output_ab" | jq -r '.result')
        
        local output_ba=$(./compute.sh add "$b" "$a")
        local result_ba=$(echo "$output_ba" | jq -r '.result')
        
        if [ "$result_ab" != "$result_ba" ]; then
            echo -e "${RED}  ✗ Failed for a=$a, b=$b: add $a $b = $result_ab, but add $b $a = $result_ba${NC}"
            property_passed=false
        fi
    done
    
    if [ "$property_passed" = true ]; then
        echo -e "${GREEN}  ✓ Property 2 passed for all test cases${NC}"
        PROPERTIES_PASSED=$((PROPERTIES_PASSED + 1))
    else
        echo -e "${RED}  ✗ Property 2 failed${NC}"
        PROPERTIES_FAILED=$((PROPERTIES_FAILED + 1))
    fi
    PROPERTIES_TESTED=$((PROPERTIES_TESTED + 1))
}

# Property 3: Response always contains valid JSON with required fields (status, data, result/error)
# **Validates: Requirements 1.2**
test_property_3_json_structure() {
    echo "Testing Property 3: Response always contains valid JSON with required fields"
    
    local test_cases=(
        "add 2 3"
        "add -5 10"
        "add 2.5 3.5"
        "add abc def"
        "invalid 1 2"
        "add 1"
    )
    
    local property_passed=true
    
    for test_case in $test_cases; do
        local output=$(./compute.sh $test_case 2>&1)
        
        # Check if JSON is valid
        if ! is_valid_json "$output"; then
            echo -e "${RED}  ✗ Invalid JSON for command: $test_case${NC}"
            echo "    Output: $output"
            property_passed=false
            continue
        fi
        
        # Check for required fields
        local has_status=$(echo "$output" | jq 'has("status")' 2>/dev/null)
        local has_data=$(echo "$output" | jq 'has("data")' 2>/dev/null)
        local status=$(echo "$output" | jq -r '.status' 2>/dev/null)
        
        if [ "$has_status" != "true" ] || [ "$has_data" != "true" ]; then
            echo -e "${RED}  ✗ Missing required fields for command: $test_case${NC}"
            property_passed=false
            continue
        fi
        
        # Check for result or error field based on status
        if [ "$status" = "success" ]; then
            local has_result=$(echo "$output" | jq 'has("result")' 2>/dev/null)
            if [ "$has_result" != "true" ]; then
                echo -e "${RED}  ✗ Success response missing 'result' field for command: $test_case${NC}"
                property_passed=false
            fi
        elif [ "$status" = "error" ]; then
            local has_error=$(echo "$output" | jq 'has("error")' 2>/dev/null)
            if [ "$has_error" != "true" ]; then
                echo -e "${RED}  ✗ Error response missing 'error' field for command: $test_case${NC}"
                property_passed=false
            fi
        else
            echo -e "${RED}  ✗ Invalid status value for command: $test_case${NC}"
            property_passed=false
        fi
    done
    
    if [ "$property_passed" = true ]; then
        echo -e "${GREEN}  ✓ Property 3 passed for all test cases${NC}"
        PROPERTIES_PASSED=$((PROPERTIES_PASSED + 1))
    else
        echo -e "${RED}  ✗ Property 3 failed${NC}"
        PROPERTIES_FAILED=$((PROPERTIES_FAILED + 1))
    fi
    PROPERTIES_TESTED=$((PROPERTIES_TESTED + 1))
}

# Run all property-based tests
echo "Running property-based tests for compute.sh..."
echo ""

test_property_1_addition_correctness
echo ""
test_property_2_commutativity
echo ""
test_property_3_json_structure

echo ""
echo "Property-Based Test Results: $PROPERTIES_PASSED/$PROPERTIES_TESTED properties passed"

if [ $PROPERTIES_FAILED -gt 0 ]; then
    echo -e "${RED}$PROPERTIES_FAILED properties failed${NC}"
    exit 1
else
    echo -e "${GREEN}All properties verified!${NC}"
    exit 0
fi
