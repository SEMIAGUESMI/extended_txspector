#!/bin/bash
# Add headers to SimplifiedCrossFunctionReentrancy.csv after Soufflé generates it

CSV_FILE="${1:-SimplifiedCrossFunctionReentrancy.csv}"
HEADER="FunctionA_CallNumber	FunctionA_CallDepth	FunctionB_CallNumber	FunctionB_CallDepth	StorageAddress	SLOAD_Location	SSTORE_Location	CALL_Location"

# Check if file exists and has content
if [ ! -f "$CSV_FILE" ] || [ ! -s "$CSV_FILE" ]; then
    echo "Error: $CSV_FILE not found or is empty"
    exit 1
fi

# Check if header already exists
if head -1 "$CSV_FILE" | grep -q "FunctionA_CallNumber"; then
    echo "Headers already exist in $CSV_FILE"
    exit 0
fi

# Create temporary file with header
TMP_FILE=$(mktemp)
echo "$HEADER" > "$TMP_FILE"
cat "$CSV_FILE" >> "$TMP_FILE"

# Replace original file
mv "$TMP_FILE" "$CSV_FILE"
echo "Headers added to $CSV_FILE"


