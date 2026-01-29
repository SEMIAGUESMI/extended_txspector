#!/bin/bash

# Script to detect cross-function reentrancy using Soufflé Datalog

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <facts_directory> [output_file]"
    echo "Example: $0 facts/cross_function_example"
    exit 1
fi

FACTS_DIR=$1
OUTPUT_FILE=${2:-"cross_function_reentrancy_results.csv"}

# Check if Soufflé is installed
if ! command -v souffle &> /dev/null; then
    echo "Error: Soufflé is not installed or not in PATH"
    echo "Please install Soufflé from: https://souffle-lang.github.io/"
    exit 1
fi

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"
PROJECT_DIR="$( cd "$SCRIPT_DIR/.." >/dev/null && pwd )"

# Check if facts directory exists
if [ ! -d "$FACTS_DIR" ]; then
    echo "Error: Facts directory '$FACTS_DIR' does not exist"
    exit 1
fi

# Change to project directory
cd "$PROJECT_DIR"

# Create temporary directory for Soufflé output
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo "Running cross-function reentrancy detection..."
echo "Facts directory: $FACTS_DIR"
echo "Output file: $OUTPUT_FILE"
echo ""

# Run Soufflé with the cross-function reentrancy rules
souffle -F "$FACTS_DIR" -D "$TEMP_DIR" "$PROJECT_DIR/rules/9CrossFunctionReentrancy.dl"

# Check if Soufflé ran successfully
if [ $? -ne 0 ]; then
    echo "Error: Soufflé execution failed"
    exit 1
fi

# Check if results were generated
RESULT_FILE="$TEMP_DIR/CrossFunctionReentrancy.csv"
if [ -f "$RESULT_FILE" ]; then
    if [ -s "$RESULT_FILE" ]; then
        echo "✓ Cross-function reentrancy detected!"
        echo ""
        echo "Results:"
        echo "--------"
        # Copy results to output file
        cp "$RESULT_FILE" "$OUTPUT_FILE"
        # Display results
        cat "$RESULT_FILE" | column -t -s'	' || cat "$RESULT_FILE"
        echo ""
        echo "Full results saved to: $OUTPUT_FILE"
    else
        echo "✓ No cross-function reentrancy detected."
        echo "No vulnerabilities found in the trace."
    fi
else
    echo "Warning: Result file not found. Detection may have failed."
    exit 1
fi



