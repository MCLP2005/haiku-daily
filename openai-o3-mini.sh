#!/bin/bash

# Script to send API request to OpenAI and save the response to a file
# Usage: ./script.sh <output_file> <prompt>

# Check if required parameters are provided
if [ $# -lt 2 ]; then
    echo "Error: Insufficient parameters provided" >&2
    echo "Usage: $0 <output_file> <prompt>" >&2
    exit 100
fi

# Store parameters
OUTPUT_FILE="$1"
PROMPT="$2"
LOG_DIR="./logs"
LOG_FILE="${LOG_DIR}/openai_api_$(date +%Y%m%d_%H%M%S).log"
API_KEY="${OPENAI_API_KEY}"

# Check if API key is set
if [ -z "$API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set" >&2
    exit 101
fi

# Create logs directory if it doesn't exist
if [ ! -d "$LOG_DIR" ]; then
    mkdir -p "$LOG_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create log directory" >&2
        exit 102
    fi
fi

# Log start of execution
echo "$(date): Starting API request with prompt: $PROMPT" >> "$LOG_FILE"

# Check if output directory exists
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [ "$OUTPUT_DIR" != "." ] && [ ! -d "$OUTPUT_DIR" ]; then
    mkdir -p "$OUTPUT_DIR"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to create output directory" >&2
        echo "$(date): Error: Failed to create output directory for $OUTPUT_FILE" >> "$LOG_FILE"
        exit 103
    fi
fi

# Make API request to OpenAI
echo "$(date): Sending request to OpenAI API..." >> "$LOG_FILE"
response=$(curl -s -X POST https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $API_KEY" \
    -d "{
        \"model\": \"o3-mini\",
        \"messages\": [{\"role\": \"user\", \"content\": \"$PROMPT\"}]
    }")

# Check if curl command was successful
if [ $? -ne 0 ]; then
    echo "Error: Failed to connect to OpenAI API" >&2
    echo "$(date): Error: Failed to connect to OpenAI API" >> "$LOG_FILE"
    exit 104
fi

# Check if response contains an error
if echo "$response" | grep -q "\"error\""; then
    error_message=$(echo "$response" | grep -o '\"message\":\"[^\"]*\"' | cut -d'"' -f4)
    echo "Error: API returned an error: $error_message" >&2
    echo "$(date): Error: API returned: $error_message" >> "$LOG_FILE"
    exit 105
fi

# Log raw response for debugging
echo "$(date): Raw response received:" >> "$LOG_FILE"
echo "$response" >> "$LOG_FILE"

# Use jq if available for reliable JSON parsing, otherwise fall back to grep pattern
if command -v jq &> /dev/null; then
    content=$(echo "$response" | jq -r '.choices[0].message.content // empty')
    if [ $? -ne 0 ] || [ -z "$content" ]; then
        echo "Error: Failed to extract content using jq" >&2
        echo "$(date): Error: Failed to extract content using jq" >> "$LOG_FILE"
        exit 106
    fi
else
    # Extract content from the nested structure using grep & sed
    content=$(echo "$response" | grep -o '"message":{[^}]*}' | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//')
    
    # Check if content was successfully extracted
    if [ -z "$content" ]; then
        echo "Error: Failed to extract content from API response" >&2
        echo "$(date): Error: Failed to extract content from API response" >> "$LOG_FILE"
        echo "Raw response: $response" >> "$LOG_FILE"
        exit 106
    fi
fi

# Save the response to the output file
echo "$content" > "$OUTPUT_FILE"
if [ $? -ne 0 ]; then
    echo "Error: Failed to write to output file" >&2
    echo "$(date): Error: Failed to write to output file $OUTPUT_FILE" >> "$LOG_FILE"
    exit 107
fi

echo "$(date): Successfully saved API response to $OUTPUT_FILE" >> "$LOG_FILE"
echo "API response saved to $OUTPUT_FILE"
exit 0
