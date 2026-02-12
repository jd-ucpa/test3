#!/bin/bash

# Compute Feature - Bash executable for arithmetic operations
# Returns results in JSON format

# Function to format success response
format_success_response() {
    local action="$1"
    local arg1="$2"
    local arg2="$3"
    local result="$4"
    
    cat <<EOF
{
  "status": "success",
  "data": {
    "params": {
      "action": "$action",
      "arguments": [$arg1, $arg2]
    }
  },
  "result": $result
}
EOF
}

# Function to format error response
format_error_response() {
    local action="$1"
    local arg1="$2"
    local arg2="$3"
    local error_msg="$4"
    
    # Handle cases where arguments might be empty
    local args_json=""
    if [ -z "$arg1" ] && [ -z "$arg2" ]; then
        args_json="[]"
    elif [ -z "$arg2" ]; then
        args_json="[\"$arg1\"]"
    else
        args_json="[\"$arg1\", \"$arg2\"]"
    fi
    
    cat <<EOF
{
  "status": "error",
  "data": {
    "params": {
      "action": "$action",
      "arguments": $args_json
    }
  },
  "error": "$error_msg"
}
EOF
}

# Function to check if a value is numeric
is_numeric() {
    local value="$1"
    # Check if value matches integer or float pattern
    if [[ $value =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
        return 0
    else
        return 1
    fi
}

# Function to handle add operation
handle_add() {
    local arg1="$1"
    local arg2="$2"
    
    # Check if both arguments are provided
    if [ -z "$arg1" ] || [ -z "$arg2" ]; then
        format_error_response "add" "$arg1" "$arg2" "Missing arguments. Usage: compute.sh add <number1> <number2>"
        return 1
    fi
    
    # Check if arguments are numeric
    if ! is_numeric "$arg1"; then
        format_error_response "add" "$arg1" "$arg2" "First argument is not numeric: $arg1"
        return 1
    fi
    
    if ! is_numeric "$arg2"; then
        format_error_response "add" "$arg1" "$arg2" "Second argument is not numeric: $arg2"
        return 1
    fi
    
    # Perform addition using bc for floating point support
    local result=$(echo "$arg1 + $arg2" | bc)
    
    # Normalize result: convert .3 to 0.3 for valid JSON
    result=$(echo "$result" | sed 's/^\./0./')
    
    format_success_response "add" "$arg1" "$arg2" "$result"
    return 0
}

# Main script logic
main() {
    local action="$1"
    local arg1="$2"
    local arg2="$3"
    
    # Check if action is provided
    if [ -z "$action" ]; then
        format_error_response "" "" "" "No action provided. Usage: compute.sh <action> <arg1> <arg2>"
        return 1
    fi
    
    # Route to appropriate handler based on action
    case "$action" in
        add)
            handle_add "$arg1" "$arg2"
            ;;
        *)
            format_error_response "$action" "$arg1" "$arg2" "Unknown action: $action. Supported actions: add"
            return 1
            ;;
    esac
}

# Execute main function with all arguments
main "$@"
