#!/bin/bash
set -euo pipefail

repository="$1"
version="$2"

if [[ ! "$version" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "La versión debe tener el formato v1.0.0."
    exit 1
fi

# Prepara la versión mientras la API actual sigue corriendo.
install -d /opt/todo-list-releases
release_dir=$(mktemp -d "/opt/todo-list-releases/${version}.XXXXXX")
chmod 755 "$release_dir"

asset="to-do-list-api-${version}.zip"
curl -fsSL --retry 3 \
    "https://github.com/${repository}/releases/download/${version}/${asset}" \
    -o "$release_dir/$asset"

python3.12 -m zipfile -e "$release_dir/$asset" "$release_dir"
python3.12 -m venv "$release_dir/.venv"
"$release_dir/.venv/bin/python" -m pip install -r "$release_dir/requirements.txt"

# Cambia el código y conserva la configuración de RDS del servicio.
override_dir=/etc/systemd/system/todo-list-api.service.d
override="$override_dir/release.conf"
install -d "$override_dir"

if [[ -f "$override" ]]; then
    cp "$override" "$release_dir/previous.conf"
fi

cat > "$release_dir/release.conf" <<EOF
[Service]
WorkingDirectory=$release_dir
Environment=APP_VERSION=$version
ExecStart=
ExecStart=$release_dir/.venv/bin/python -m uvicorn main:app --host 0.0.0.0 --port 8000
EOF

install -m 644 "$release_dir/release.conf" "$override"

if systemctl daemon-reload && systemctl restart todo-list-api; then
    for attempt in {1..15}; do
        if curl -fs --max-time 2 http://127.0.0.1:8000/version |
            python3.12 -c 'import json, sys; sys.exit(json.load(sys.stdin)["version"] != sys.argv[1])' "$version" 2>/dev/null; then
            echo "Versión desplegada: $version"
            exit 0
        fi
        sleep 2
    done
fi

echo "La versión $version no respondió. Restaurando el servicio anterior."
if [[ -f "$release_dir/previous.conf" ]]; then
    install -m 644 "$release_dir/previous.conf" "$override"
else
    rm -f "$override"
fi
systemctl daemon-reload
systemctl restart todo-list-api
exit 1