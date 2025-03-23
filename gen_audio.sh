#!/bin/bash

# Script to generate audio files for haikus using OpenAI TTS-HD API
# This script processes haiku files and creates corresponding mp3 files

# Check if OPENAI_API_KEY is set
if [ -z "$OPENAI_API_KEY" ]; then
    echo "Error: OPENAI_API_KEY environment variable is not set" >&2
    exit 1
fi

# Set maximum concurrent jobs (default: 1)
MAX_CONCURRENT_JOBS=${MAX_CONCURRENT_JOBS:-1}
echo "Maximum concurrent jobs: $MAX_CONCURRENT_JOBS"

# Function to extract haiku for a specific day from a monthly file
extract_haiku() {
    local file="$1"
    local day="$2"
    local month_num="$3"
    local year="$4"
    
    # Format the day for pattern matching
    local day_pattern
    
    # Handle different day formats (1st, 2nd, 3rd, etc.)
    case "$day" in
        1|21|31) day_pattern="${day}st";;
        2|22) day_pattern="${day}nd";;
        3|23) day_pattern="${day}rd";;
        *) day_pattern="${day}th";;
    esac
    
    # Extract month name from file name pattern
    local month_name=$(basename "$file" | cut -d'-' -f2 | cut -d'.' -f1)
    
    # Find the haiku for the specified day
    local haiku=""
    local found=false
    local next_day_found=false
    
    while IFS= read -r line; do
        # Check if this is the start of the haiku for our day
        if [[ "$line" == *"$month_name $day_pattern"* ]] || [[ "$line" == *"$month_name $day"* ]]; then
            found=true
            continue
        fi
        
        # Check if we've reached the next day's haiku
        if [[ "$found" == true && "$line" == "**"* ]]; then
            break
        fi
        
        # Collect haiku lines
        if [[ "$found" == true && "$line" != "---" && -n "$line" ]]; then
            haiku="${haiku}${line} "
        fi
    done < "$file"
    
    # Clean up the haiku text
    haiku=$(echo "$haiku" | sed 's/  / /g' | sed 's/^ //g' | sed 's/ $//g')
    
    echo "$haiku"
}

# Process audio generation job
process_job() {
    local month_file="$1"
    local day="$2"
    local month_num="$3"
    local year="$4"
    local month_dir="$5"
    
    # Extract month name from filename
    local month_name=$(basename "$month_file" | cut -d'-' -f2 | cut -d'.' -f1)
    
    # Format day with leading zero
    day_padded=$(printf "%02d" $day)
    
    # Output audio file
    audio_file="$month_dir/$month_num-$day_padded.mp3"
    
    # Skip if file already exists
    if [ -f "$audio_file" ]; then
        echo "  Audio for $month_name $day already exists, skipping."
        return 0
    fi
    
    # Extract haiku for this day
    haiku=$(extract_haiku "$month_file" "$day" "$month_num" "$year")
    
    if [ -n "$haiku" ]; then
        echo "  Generating audio for $month_name $day: $haiku"
        
        # Call OpenAI TTS API to generate audio
        response=$(curl -s -X POST https://api.openai.com/v1/audio/speech \
            -H "Authorization: Bearer $OPENAI_API_KEY" \
            -H "Content-Type: application/json" \
            -d "{
                \"model\": \"tts-hd\",
                \"voice\": \"nova\",
                \"input\": \"$haiku\",
                \"response_format\": \"mp3\"
            }" \
            --output "$audio_file")
        
        # Check if file was created successfully
        if [ -f "$audio_file" ] && [ -s "$audio_file" ]; then
            echo "  Audio saved to $audio_file"
            
            # Format publishing date (YYYY-MM-DD)
            publishing_date="$year-$month_num-$day_padded"
            
            # Commit the new audio file
            git add "$audio_file"
            git commit -S -m "Added audio file for $publishing_date"
            echo "  Committed audio file for $publishing_date"
        else
            echo "  Error: Failed to generate audio for $month_name $day"
        fi
        
        # Sleep to avoid API rate limits
        sleep 1
    else
        echo "  Warning: No haiku found for $month_name $day"
    fi
}

# Function to wait for jobs to complete
wait_for_jobs() {
    while [ "$(jobs -r | wc -l)" -ge "$MAX_CONCURRENT_JOBS" ]; do
        sleep 1
    done
}

# Process all year directories
for decade_dir in 20*X; do
    if [ -d "$decade_dir" ]; then
        echo "Processing decade directory: $decade_dir"
        
        # Process each year directory
        for year_dir in "$decade_dir"/20*; do
            if [ -d "$year_dir" ]; then
                year=$(basename "$year_dir")
                echo "Processing year: $year"
                
                # Process each month file
                for month_file in "$year_dir"/*-*.md; do
                    if [ -f "$month_file" ]; then
                        # Extract month number from filename
                        month_name=$(basename "$month_file" | cut -d'-' -f2 | cut -d'.' -f1)
                        month_num=$(basename "$month_file" | cut -d'-' -f1)
                        
                        echo "Processing month: $month_name ($month_num)"
                        
                        # Create month directory if it doesn't exist
                        month_dir="$year_dir/$month_num-$month_name"
                        mkdir -p "$month_dir"
                        
                        # Process each day of the month
                        max_days=31
                        case "$month_num" in
                            "02")
                                # Check for leap year
                                if (( year % 4 == 0 && (year % 100 != 0 || year % 400 == 0) )); then
                                    max_days=29
                                else
                                    max_days=28
                                fi
                                ;;
                            "04"|"06"|"09"|"11")
                                max_days=30
                                ;;
                        esac
                        
                        for (( day=1; day<=max_days; day++ )); do
                            # Wait if we've reached max concurrent jobs
                            wait_for_jobs
                            
                            # Process job in background if MAX_CONCURRENT_JOBS > 1
                            if [ "$MAX_CONCURRENT_JOBS" -gt 1 ]; then
                                process_job "$month_file" "$day" "$month_num" "$year" "$month_dir" &
                            else
                                process_job "$month_file" "$day" "$month_num" "$year" "$month_dir"
                            fi
                        done
                        
                        # Wait for all jobs to complete before moving to next month
                        wait
                    fi
                done
            fi
        done
    fi
done

echo "Audio generation complete"
echo "Note: Audio files have been automatically committed. You still need to push the changes manually."
exit 0
