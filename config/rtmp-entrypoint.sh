#!/bin/sh
# Enhanced RTMP entrypoint with authentication and multi-user support
# Remove any existing config first
rm -f /etc/nginx/nginx.conf

# Read authentication key from environment variable (default: yolo2025secret)
RTMP_PUSH_KEY="${RTMP_PUSH_KEY:-change_me_please}"

# Use unquoted heredoc to allow variable expansion
cat > /etc/nginx/nginx.conf << NGINX_EOF
error_log /dev/stdout info;
events { worker_connections 1024; }
rtmp {
    server {
        listen 1935;
        chunk_size 4000;
        
        # Live application with authentication (supports multiple users)
        # Usage: rtmp://<your-server-ip>:1935/live/{stream_name}
        # Note: Authentication is currently disabled for testing
        application live {
            live on;
            record off;
            
            # Authentication callback - verify push key
            # Note: RTMP protocol doesn't support URL query parameters
            # So we need to parse the stream name or use a different auth method
            # For now, authentication is disabled for easy testing
            # To enable: uncomment the line below and configure rtmp-auth endpoint
            # on_publish http://127.0.0.1:8081/rtmp-auth;
            
            # Generate HLS for each user
            hls on;
            hls_path /opt/data/hls;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;  # Enable nested directories for multi-user
            
            # Allow play from anywhere (you can restrict this)
            allow play all;
        }
        
        # Detected application (for YOLO detection results)
        # Supports multi-user: detected/{username}
        application detected {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_detected;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Pose application
        application pose {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_pose;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Segment application
        application segment {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_segment;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Classify application
        application classify {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_classify;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # OBB application
        application obb {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_obb;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Count application
        application count {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_count;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Heatmap application
        application heatmap {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_heatmap;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Workout application
        application workout {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_workout;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Speed application
        application speed {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_speed;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Blur application
        application blur {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_blur;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
        
        # Trackzone application
        application trackzone {
            live on;
            record off;
            hls on;
            hls_path /opt/data/hls_trackzone;
            hls_fragment 2s;
            hls_playlist_length 10s;
            hls_nested on;
            allow play all;
        }
    }
}
http {
    root /www/static;
    sendfile off;
    tcp_nopush on;
    server_tokens off;
    access_log /dev/stdout combined;
    
    # RTMP Authentication endpoint (internal only)
    # This is for future authentication support
    server {
        listen 8081;
        server_name localhost;
        
        location = /rtmp-auth {
            # Get query parameters
            set \$name \$arg_name;
            set \$key \$arg_key;
            
            # Check if key matches
            # Note: Currently disabled - authentication not active
            if (\$key = "${RTMP_PUSH_KEY}") {
                return 200;
            }
            return 403;
        }
    }
    
    # Main HTTP server for HLS playback
    server {
        listen 80;
        
        # HLS locations with nested support for multi-user
        location ~ ^/live/(.+)$ {
            alias /opt/data/hls/\$1/;
            try_files \$uri \$uri/index.m3u8 /\$1/index.m3u8;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/detected/(.+)$ {
            alias /opt/data/hls_detected/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/pose/(.+)$ {
            alias /opt/data/hls_pose/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/segment/(.+)$ {
            alias /opt/data/hls_segment/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/classify/(.+)$ {
            alias /opt/data/hls_classify/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/obb/(.+)$ {
            alias /opt/data/hls_obb/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/count/(.+)$ {
            alias /opt/data/hls_count/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/heatmap/(.+)$ {
            alias /opt/data/hls_heatmap/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/workout/(.+)$ {
            alias /opt/data/hls_workout/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/speed/(.+)$ {
            alias /opt/data/hls_speed/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/blur/(.+)$ {
            alias /opt/data/hls_blur/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        location ~ ^/trackzone/(.+)$ {
            alias /opt/data/hls_trackzone/\$1/;
            types { application/vnd.apple.mpegurl m3u8; video/mp2t ts; }
            add_header Cache-Control no-cache;
            add_header Access-Control-Allow-Origin *;
        }
        
        # RTMP statistics
        location /stat { rtmp_stat all; rtmp_stat_stylesheet stat.xsl; }
        location /stat.xsl { root /www/static; }
        location /crossdomain.xml { default_type text/xml; expires 24h; }
    }
}
NGINX_EOF
exec nginx -g 'daemon off;'
