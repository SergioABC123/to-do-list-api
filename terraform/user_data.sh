#!/bin/bash
set -euxo pipefail

dnf install -y git python3.12 python3.12-pip

git clone --branch main --single-branch "${repository_url}" /opt/todo-list-api

cd /opt/todo-list-api
python3.12 -m venv .venv
.venv/bin/python -m pip install -r requirements.txt

# Registra la API como servicio para que vuelva a arrancar tras un reinicio.
cat > /etc/systemd/system/todo-list-api.service <<'EOF'
[Unit]
Description=To-do List API
Wants=network-online.target
After=network-online.target

[Service]
User=ec2-user
WorkingDirectory=/opt/todo-list-api
ExecStart=/opt/todo-list-api/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now todo-list-api.service