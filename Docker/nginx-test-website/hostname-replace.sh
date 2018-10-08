#!/usr/bin/env bash
contName=$(hostname)
sed -i "s/#CONTAINER_NAME#/$contName/g" /usr/share/nginx/html/index.html