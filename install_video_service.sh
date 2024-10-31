#!/bin/zsh
echo "Starting video service installation..."
python3 -m venv ~/AI_Projects/venv
source ~/AI_Projects/venv/bin/activate
mkdir -p ~/Downloads/wild2
mkdir -p ~/AI_Projects/{temp,output,models}
mkdir -p ~/bin
mkdir -p ~/Library/LaunchAgents
pip install watchdog
cat > ~/AI_Projects/fast_process_rife.py << 'PYEOF'
#!/usr/bin/env python3
import os
import sys
import subprocess
import time
from pathlib import Path
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler
class VideoHandler(FileSystemEventHandler):
    def on_created(self, event):
        if not event.is_directory and event.src_path.lower().endswith((".mp4", ".mov", ".avi")):
            self.process_video(event.src_path)
    def process_video(self, input_path):
        try:
            base_name = os.path.splitext(os.path.basename(input_path))[0]
            output_path = os.path.expanduser(f"~/Downloads/{base_name}_processed.mov")
            print(f"Processing: {base_name}")
            time.sleep(2)
            subprocess.run([
                "ffmpeg", "-y",
                "-i", input_path,
                "-vf", "fps=24,unsharp=3:3:1.5",
                "-c:v", "prores_ks",
                "-profile:v", "3",
                "-vendor", "apl0",
                "-bits_per_mb", "8000",
                "-pix_fmt", "yuv422p10le",
                output_path
            ], check=True)
            print(f"Completed: {output_path}")
            os.remove(input_path)
            print(f"Removed original file: {input_path}")
        except Exception as e:
            print(f"Error: {str(e)}")
def main():
    watch_path = os.path.expanduser("~/Downloads/wild2")
    os.makedirs(watch_path, exist_ok=True)
    observer = Observer()
    observer.schedule(VideoHandler(), watch_path, recursive=False)
    observer.start()
    print(f"Monitoring: {watch_path}")
    print("Ready for video processing...")
    try:
        while True:
            time.sleep(1)
    except KeyboardInterrupt:
        observer.stop()
    observer.join()
if __name__ == "__main__":
    main()
PYEOF
chmod +x ~/AI_Projects/fast_process_rife.py
cat > ~/Library/LaunchAgents/com.ai.videoprocess.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ai.videoprocess</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>source ~/AI_Projects/venv/bin/activate && cd ~/AI_Projects && python3 fast_process_rife.py</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>~/Library/Logs/videoprocess.log</string>
    <key>StandardErrorPath</key>
    <string>~/Library/Logs/videoprocess.err</string>
    <key>WorkingDirectory</key>
    <string>~/AI_Projects</string>
</dict>
</plist>
cat > ~/bin/videocontrolindownload << 'CONTROLEOF'
#!/bin/bash
case "$1" in
    start)
        launchctl load ~/Library/LaunchAgents/com.ai.videoprocess.plist
        launchctl start com.ai.videoprocess
        echo "Service started"
        ;;
    stop)
        launchctl unload ~/Library/LaunchAgents/com.ai.videoprocess.plist
        pkill -f "fast_process_rife.py"
        echo "Service stopped"
        ;;
    restart)
        launchctl unload ~/Library/LaunchAgents/com.ai.videoprocess.plist
        pkill -f "fast_process_rife.py"
        sleep 2
        launchctl load ~/Library/LaunchAgents/com.ai.videoprocess.plist
        launchctl start com.ai.videoprocess
        echo "Service restarted"
        ;;
    status)
        if pgrep -f "fast_process_rife.py" > /dev/null; then
            echo "Service is running"
        else
            echo "Service is not running"
        fi
        ;;
    *)
        echo "Usage: videocontrolindownload {start|stop|restart|status}"
        exit 1
        ;;
esac
CONTROLEOF
chmod +x ~/bin/videocontrolindownload
[[ ":$PATH:" != *":$HOME/bin:"* ]] && echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc
launchctl load ~/Library/LaunchAgents/com.ai.videoprocess.plist
echo "✅ Installation completed successfully!"
echo "You can now:"
echo "1. Control the service with: videocontrolindownload {start|stop|restart|status}"
echo "2. Place videos in: ~/Downloads/wild2"
echo "3. Find processed videos in: ~/Downloads"
echo "4. View logs at: ~/Library/Logs/videoprocess.log"
