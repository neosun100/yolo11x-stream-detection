#!/bin/bash
# RTMP ??????
#
# ????:
#   1. ??????????
#   2. ???????????????
#   3. ????

# ========================================
# ????
# ========================================

# RTMP ????????????????
RTMP_SERVER="${RTMP_SERVER:-localhost}"
RTMP_PORT="${RTMP_PORT:-1935}"
STREAM_NAME="${STREAM_NAME:-cam}"

RTMP_URL="rtmp://${RTMP_SERVER}:${RTMP_PORT}/live/${STREAM_NAME}"

# ========================================
# Mac ????
# ========================================

push_mac() {
    echo "??? Mac ?????..."
    echo "????: ${RTMP_URL}"
    echo ""
    
    ffmpeg -f avfoundation -framerate 30 -pixel_format nv12 \
      -video_size 1280x720 -i "0:" \
      -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p \
      -g 60 -b:v 3M -maxrate 3M -bufsize 6M \
      -f flv "${RTMP_URL}"
}

# ========================================
# Linux ??????? v4l2?
# ========================================

push_linux() {
    echo "??? Linux ?????..."
    echo "????: ${RTMP_URL}"
    echo ""
    echo "??: ???????????????? /dev/video0?"
    echo ""
    
    CAMERA_DEVICE="${CAMERA_DEVICE:-/dev/video0}"
    
    ffmpeg -f v4l2 -framerate 30 -video_size 1280x720 \
      -i "${CAMERA_DEVICE}" \
      -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p \
      -g 60 -b:v 3M -maxrate 3M -bufsize 6M \
      -f flv "${RTMP_URL}"
}

# ========================================
# ?????
# ========================================

push_file() {
    if [ -z "$1" ]; then
        echo "??: ?????????"
        echo "??: $0 file <??????>"
        exit 1
    fi
    
    VIDEO_FILE="$1"
    
    if [ ! -f "$VIDEO_FILE" ]; then
        echo "??: ?????: $VIDEO_FILE"
        exit 1
    fi
    
    echo "?????: ${VIDEO_FILE}"
    echo "????: ${RTMP_URL}"
    echo ""
    
    ffmpeg -re -i "${VIDEO_FILE}" \
      -c:v libx264 -preset veryfast -tune zerolatency -pix_fmt yuv420p \
      -g 60 -b:v 3M -maxrate 3M -bufsize 6M \
      -f flv "${RTMP_URL}"
}

# ========================================
# ???
# ========================================

main() {
    case "${1:-mac}" in
        mac)
            push_mac
            ;;
        linux)
            push_linux
            ;;
        file)
            push_file "$2"
            ;;
        *)
            echo "??: $0 [mac|linux|file]"
            echo ""
            echo "??:"
            echo "  $0 mac              # Mac ?????"
            echo "  $0 linux            # Linux ?????"
            echo "  $0 file video.mp4   # ?????"
            echo ""
            echo "????:"
            echo "  RTMP_SERVER=your-server-ip $0 mac"
            echo "  STREAM_NAME=my-stream $0 mac"
            exit 1
            ;;
    esac
}

main "$@"
