#!/bin/zsh

WATCH_DIR="$HOME/Desktop/wild"
OUTPUT_DIR="$WATCH_DIR/completed"
PROCESSING_DIR="$WATCH_DIR/processing"
FAILED_DIR="$WATCH_DIR/failed"
LOG_DIR="$WATCH_DIR/logs"
MODELS_DIR="$WATCH_DIR/models"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_DIR/service.log"
}

process_video() {
    local input="$1"
    local filename=$(basename "$input")
    local base="${filename%.*}"
    local ext="${filename##*.}"
    
    log "Processing $filename"
    mv "$input" "$PROCESSING_DIR/"
    
    # Process with Real-ESRGAN
    python3 -m realesrgan.inference_realesrgan_video \
        -i "$PROCESSING_DIR/$filename" \
        -o "$PROCESSING_DIR/${base}_upscaled.$ext" \
        -n realesrgan-x4plus \
        -m "$MODELS_DIR/realesrgan-x4plus.pth" \
        --fps 24 \
        --face_enhance \
        --gpu-id 0 \
        --tile 512 \
        --half
        
    # Face enhancement
    python3 -m gfpgan.inference_gfpgan \
        -i "$PROCESSING_DIR/${base}_upscaled.$ext" \
        -o "$OUTPUT_DIR/${base}_final.$ext" \
        -v 1.3 \
        -m "$MODELS_DIR/GFPGANv1.3.pth" \
        --bg_upsampler realesrgan
        
    rm -f "$PROCESSING_DIR/$filename" 
"$PROCESSING_DIR/${base}_upscaled.$ext"
    log "Completed processing $filename"
}

# Watch directory
fswatch -0 "$WATCH_DIR" | while read -d "" path; do
    if [[ "$path" =~ \.(mp4|mov)$ ]]; then
        process_video "$path"
    fi
done
