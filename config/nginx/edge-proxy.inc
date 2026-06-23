proxy_http_version 1.1;
proxy_set_header Host $host;
proxy_set_header X-Real-IP $remote_addr;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_set_header X-Forwarded-Proto $edge_scheme;
proxy_set_header X-Forwarded-Host $host;
proxy_set_header Upgrade $http_upgrade;
proxy_set_header Connection $connection_upgrade;
proxy_connect_timeout 60s;
proxy_send_timeout 600s;
proxy_buffering off;

# Browser H5 may still hit api.* / chat-api.* from cached older bundles.
# Answer CORS preflight at the edge so the request is not rejected before it
# reaches OpenIM/chat API.
add_header Access-Control-Allow-Origin $http_origin always;
add_header Access-Control-Allow-Credentials true always;
add_header Access-Control-Allow-Methods "GET, POST, PUT, PATCH, DELETE, OPTIONS" always;
add_header Access-Control-Allow-Headers $http_access_control_request_headers always;
add_header Access-Control-Max-Age 86400 always;

if ($request_method = OPTIONS) {
    return 204;
}
