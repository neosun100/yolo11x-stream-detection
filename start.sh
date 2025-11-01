#!/bin/bash

################################################################################
# YOLO11x ???????????
# 
# ??:
# - ????? Docker, GPU, NVIDIA Container Toolkit ???
# - ??/?? Docker ??
# - ??????
# - ??????
# - ???? URL ??
#
# ??:
#   bash start.sh          # ????
#   bash start.sh --pull    # ?????????
#   bash start.sh --stop    # ????
#   bash start.sh --restart # ????
#   bash start.sh --status  # ????
################################################################################

set -e  # ????????

# ????
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ????
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ????
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ????
print_header() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   YOLO11x ???????${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
}

# ????????
check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_error "$1 ??????? PATH ??"
        return 1
    fi
    return 0
}

# ?? Docker ??
check_docker() {
    log_info "?? Docker ??..."
    
    if ! check_command docker; then
        log_error "Docker ???????? Docker"
        exit 1
    fi
    
    if ! docker info &> /dev/null; then
        log_error "Docker daemon ??????? Docker"
        exit 1
    fi
    
    log_success "Docker ????"
}

# ?? Docker Compose
check_docker_compose() {
    log_info "?? Docker Compose..."
    
    # ?? docker compose (v2) ? docker-compose (v1)
    if docker compose version &> /dev/null; then
        COMPOSE_CMD="docker compose"
        log_success "??? Docker Compose V2"
    elif check_command docker-compose; then
        COMPOSE_CMD="docker-compose"
        log_success "??? Docker Compose V1"
    else
        log_error "Docker Compose ???"
        log_info "??? Docker Compose ??? compose ???Docker ???"
        exit 1
    fi
}

# ?? NVIDIA Container Toolkit
check_nvidia_runtime() {
    log_info "?? NVIDIA Container Toolkit..."
    
    if ! docker info 2>/dev/null | grep -q nvidia; then
        log_warning "NVIDIA runtime ????"
        log_warning "?????? GPU ????????"
    else
        log_success "NVIDIA runtime ???"
    fi
    
    # ?? nvidia-smi
    if command -v nvidia-smi &> /dev/null; then
        GPU_INFO=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)
        if [ -n "$GPU_INFO" ]; then
            log_success "??? GPU: $GPU_INFO"
        else
            log_warning "???? GPU"
        fi
    else
        log_warning "nvidia-smi ???????? GPU ??"
    fi
}

# ????
check_files() {
    log_info "??????..."
    
    local files=("docker-compose.yml" "config/rtmp-entrypoint.sh")
    
    for file in "${files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "??????: $file"
            exit 1
        fi
    done
    
    # ??????
    local scripts_dir="scripts"
    if [ ! -d "$scripts_dir" ]; then
        log_warning "?????????: $scripts_dir"
    else
        local script_count=$(find "$scripts_dir" -name "yolo_*_detector.py" | wc -l)
        if [ "$script_count" -lt 11 ]; then
            log_warning "???????????? $script_count ??"
        else
            log_success "????????"
        fi
    fi
}

# ????
create_directories() {
    log_info "??????..."
    
    # ???????????????????????
    mkdir -p data
    
    # ????
    chmod -R 755 data/ 2>/dev/null || true
    
    log_success "??????"
}

# ?? Docker ??
pull_images() {
    log_info "??/?? Docker ??..."
    
    # ?? nginx-rtmp ??
    log_info "?? nginx-rtmp ??..."
    docker pull alfg/nginx-rtmp || log_warning "???? alfg/nginx-rtmp????????"
    
    # ?? ultralytics ??
    log_info "?? ultralytics ????????????..."
    docker pull ultralytics/ultralytics:latest || log_warning "???? ultralytics/ultralytics????????"
    
    log_success "??????"
}

# ????
stop_services() {
    log_info "??????..."
    
    if $COMPOSE_CMD ps -q | grep -q .; then
        $COMPOSE_CMD down
        log_success "???????"
    else
        log_info "???????"
    fi
}

# ????
start_services() {
    log_info "????..."
    
    # ???????????
    docker network inspect yolo_net &> /dev/null || docker network create yolo_net
    
    # ??
    log_info "?? 12 ????1 ? RTMP + 11 ??????..."
    $COMPOSE_CMD up -d
    
    log_success "???????????"
}

# ??????
wait_for_services() {
    log_info "??????..."
    
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local running=$($COMPOSE_CMD ps -q | wc -l)
        local expected=12
        
        if [ "$running" -eq "$expected" ]; then
            log_success "??????? ($running/$expected)"
            return 0
        fi
        
        if [ $((attempt % 5)) -eq 0 ]; then
            log_info "???... ($running/$expected ????)"
        fi
        
        sleep 2
        attempt=$((attempt + 1))
    done
    
    log_warning "?????????????????"
}

# ????
show_status() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   ????${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    $COMPOSE_CMD ps
    
    echo ""
    echo -e "${BLUE}????${NC}"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep -E "NAME|rtmp|yolo"
}

# ?? URL
show_urls() {
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   ?? URL ??${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # ????? IP ??? localhost
    SERVER_HOST="${HLS_SERVER_HOST:-localhost}"
    SERVER_PORT="${HLS_SERVER_PORT:-8080}"
    
    echo -e "${BLUE}??${NC}"
    echo "  - ???????????????????? ${SERVER_HOST}"
    echo "  - ????: ${SERVER_PORT}"
    echo ""
    echo -e "${BLUE}????? URL:${NC}"
    echo ""
    
    local stream_name="${STREAM_NAME:-cam}"
    
    local urls=(
        "???:       http://${SERVER_HOST}:${SERVER_PORT}/live/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/detected/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/pose/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/segment/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/classify/${stream_name}/index.m3u8"
        "?????:   http://${SERVER_HOST}:${SERVER_PORT}/obb/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/count/${stream_name}/index.m3u8"
        "???:       http://${SERVER_HOST}:${SERVER_PORT}/heatmap/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/workout/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/speed/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/blur/${stream_name}/index.m3u8"
        "????:     http://${SERVER_HOST}:${SERVER_PORT}/trackzone/${stream_name}/index.m3u8"
    )
    
    for url in "${urls[@]}"; do
        echo "  $url"
    done
    
    echo ""
    echo -e "${BLUE}????????? ffplay?:${NC}"
    echo "  ffplay \"http://${SERVER_HOST}:${SERVER_PORT}/detected/${stream_name}/index.m3u8\""
    echo ""
    echo -e "${BLUE}RTMP ????:${NC}"
    echo "  rtmp://${RTMP_SERVER_HOST:-localhost}:1935/live/${stream_name}"
    echo ""
    echo -e "${YELLOW}??${NC}"
    echo "  - ????????? IP ?????????"
    echo "  - ???????: README.md"
    echo ""
}

# ??????
show_logs_commands() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}   ????${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}??????:${NC}"
    echo "  $COMPOSE_CMD logs -f"
    echo ""
    echo -e "${BLUE}????????:${NC}"
    echo "  docker logs -f rtmp"
    echo "  docker logs -f yolo-detect"
    echo "  docker logs -f yolo-pose"
    echo ""
    echo -e "${BLUE}????:${NC}"
    echo "  $COMPOSE_CMD restart"
    echo ""
    echo -e "${BLUE}????:${NC}"
    echo "  $COMPOSE_CMD down"
    echo ""
    echo -e "${BLUE}????:${NC}"
    echo "  $COMPOSE_CMD ps"
    echo ""
    echo -e "${BLUE}?? RTMP ??:${NC}"
    echo "  curl http://localhost:8080/stat"
    echo ""
}

# ???
main() {
    print_header
    
    local command="${1:-start}"
    
    case "$command" in
        --stop|stop)
            check_docker
            check_docker_compose
            stop_services
            exit 0
            ;;
        --restart|restart)
            check_docker
            check_docker_compose
            stop_services
            sleep 2
            start_services
            wait_for_services
            show_status
            show_urls
            ;;
        --status|status)
            check_docker
            check_docker_compose
            show_status
            exit 0
            ;;
        --pull|pull)
            FORCE_PULL=true
            ;;
        --start|start|*)
            # ????
            ;;
    esac
    
    # ????
    check_docker
    check_docker_compose
    check_nvidia_runtime
    check_files
    create_directories
    
    if [ "${FORCE_PULL:-false}" = "true" ] || [ "$command" = "--pull" ]; then
        pull_images
    fi
    
    # ????????????
    if $COMPOSE_CMD ps -q | grep -q .; then
        log_info "??????????????..."
        stop_services
        sleep 2
    fi
    
    start_services
    wait_for_services
    
    # ????
    show_status
    echo ""
    show_urls
    show_logs_commands
    
    echo ""
    log_success "???????"
    echo ""
}

# ?????
main "$@"
