#!/usr/bin/env python3
"""
YOLO ???????????
?? ObjectBlurrer Solution ????????
"""
import cv2
import subprocess
import numpy as np
from ultralytics import YOLO
from ultralytics.solutions import ObjectBlurrer
import time
import sys

# ??
MODEL_PATH = "yolo11x.pt"  # ????????
SOURCE_RTMP = "rtmp://rtmp/live/cam"
OUTPUT_RTMP = "rtmp://rtmp/blur/cam"

def main():
    print(f"????: {MODEL_PATH}")
    try:
        model = YOLO(MODEL_PATH)
        print("? ??????")
    except Exception as e:
        print(f"? ??????: {e}")
        sys.exit(1)
    
    print(f"?????: {SOURCE_RTMP}")
    
    # ????
    max_retries = 10
    for retry in range(max_retries):
        cap = cv2.VideoCapture(SOURCE_RTMP)
        if cap.isOpened():
            break
        print(f"?????... ({retry+1}/{max_retries})")
        time.sleep(2)
    
    if not cap.isOpened():
        print(f"? ???????: {SOURCE_RTMP}")
        sys.exit(1)
    
    # ??????
    width = int(cap.get(cv2.CAP_PROP_FRAME_WIDTH))
    height = int(cap.get(cv2.CAP_PROP_FRAME_HEIGHT))
    fps = cap.get(cv2.CAP_PROP_FPS) or 30.0
    
    print(f"? ?????: {width}x{height} @ {fps:.1f}fps")
    
    # ??? ObjectBlurrer (???? 0.02)
    blurrer = ObjectBlurrer(model=model, blur_ratio=0.02, show=False)
    
    # ?? ffmpeg
    try:
        subprocess.run(['which', 'ffmpeg'], check=True, capture_output=True)
        print("? FFmpeg ??")
    except:
        print("?? FFmpeg ????????...")
        try:
            subprocess.run(['apt-get', 'update', '-qq'], check=True)
            subprocess.run(['apt-get', 'install', '-y', '-qq', 'ffmpeg'], check=True)
            print("? FFmpeg ????")
        except:
            print("? ???? FFmpeg")
    
    # ?? FFmpeg ????
    ffmpeg_cmd = [
        'ffmpeg',
        '-y',
        '-f', 'rawvideo',
        '-vcodec', 'rawvideo',
        '-s', f'{width}x{height}',
        '-pix_fmt', 'bgr24',
        '-r', str(int(fps)),
        '-i', '-',
        '-c:v', 'libx264',
        '-preset', 'veryfast',
        '-tune', 'zerolatency',
        '-pix_fmt', 'yuv420p',
        '-g', '60',
        '-b:v', '3M',
        '-maxrate', '3M',
        '-bufsize', '6M',
        '-f', 'flv',
        OUTPUT_RTMP
    ]
    
    print(f"?? FFmpeg ???: {OUTPUT_RTMP}")
    
    try:
        ffmpeg_process = subprocess.Popen(
            ffmpeg_cmd,
            stdin=subprocess.PIPE,
            stderr=subprocess.PIPE,
            stdout=subprocess.PIPE
        )
        
        frame_count = 0
        start_time = time.time()
        last_log_time = start_time
        
        print("? ?????????...")
        print("? Ctrl+C ??\n")
        
        while True:
            ret, frame = cap.read()
            if not ret:
                print("?? ????????...")
                time.sleep(0.5)
                cap.release()
                cap = cv2.VideoCapture(SOURCE_RTMP)
                continue
            
            # ?? ObjectBlurrer ???
            results = blurrer.process(frame)
            annotated_frame = results.plot_im
            
            # ???????? BGR ??
            if not annotated_frame.flags['C_CONTIGUOUS']:
                annotated_frame = np.ascontiguousarray(annotated_frame, dtype=np.uint8)
            
            # ??? BGR ??
            if annotated_frame.shape[2] != 3:
                annotated_frame = cv2.cvtColor(annotated_frame, cv2.COLOR_RGBA2BGR)
            
            # ??? FFmpeg
            try:
                frame_bytes = annotated_frame.astype(np.uint8).tobytes()
                ffmpeg_process.stdin.write(frame_bytes)
                ffmpeg_process.stdin.flush()
            except (BrokenPipeError, OSError) as e:
                print(f"? FFmpeg ????: {e}")
                break
            
            frame_count += 1
            
            # ? 5 ???????
            now = time.time()
            if now - last_log_time >= 5:
                elapsed = now - start_time
                fps_actual = frame_count / elapsed if elapsed > 0 else 0
                print(f"[{int(elapsed)}s] ??? {frame_count} ??FPS: {fps_actual:.1f}")
                last_log_time = now
    
    except KeyboardInterrupt:
        print("\n\n????...")
    except Exception as e:
        print(f"\n? ??: {e}")
        import traceback
        traceback.print_exc()
    finally:
        cap.release()
        if ffmpeg_process:
            try:
                ffmpeg_process.stdin.close()
                ffmpeg_process.wait(timeout=5)
            except:
                ffmpeg_process.kill()
        print("? ????")

if __name__ == "__main__":
    main()
