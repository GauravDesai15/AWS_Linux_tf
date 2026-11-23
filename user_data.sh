#!/bin/bash
set -euxo pipefail
dnf install -y nginx
systemctl enable --now nginx
cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en"><head><meta charset="utf-8"><title>Terraform EC2 Lab</title></head>
<body><h1>Terraform EC2 Lab is running!</h1><p>Amazon Linux 2023 + Nginx</p></body></html>
HTML
