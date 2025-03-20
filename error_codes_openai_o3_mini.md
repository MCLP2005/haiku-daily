# OpenAI API Script Error Codes

This document provides explanations for error codes that may be encountered when running the OpenAI API request script.

## Error Code List

| Code | Description | Troubleshooting |
|------|-------------|-----------------|
| 100  | Insufficient parameters provided | Ensure you provide both output file and prompt parameters when running the script. Usage: `./script.sh <output_file> <prompt>` |
| 101  | OpenAI API key not set | Set the OPENAI_API_KEY environment variable with your OpenAI API key before running the script. Use: `export OPENAI_API_KEY="your-api-key"` |
| 102  | Failed to create log directory | Ensure the script has write permissions in the current directory. Check disk space availability. |
| 103  | Failed to create output directory | Ensure the script has permissions to create directories in the specified path. Check if the path is valid. |
| 104  | Failed to connect to OpenAI API | Check your internet connection. Verify that the OpenAI API endpoint is accessible from your network. |
| 105  | API returned an error | Check the error message in the script output or log file. Verify that your API key is valid and has sufficient permissions. Make sure the model name is correct. |
| 106  | Failed to extract content from API response | The API response format may have changed or doesn't contain expected fields. Check the raw response in the log file. |
| 107  | Failed to write to output file | Ensure the script has write permissions for the specified output file location. Check disk space availability. |

## Additional Information

- All errors are logged to the `logs` directory with timestamps
- The script returns 0 on successful execution
- In case of an error, the specific error message is printed to stderr and the corresponding error code is returned as the exit status
