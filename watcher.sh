#!/bin/bash

CERT_DIR="$1"
HAPROXY_CFG="$2"
HAPROXY_CONTAINER="$3"

echo "[WATCHER] Avvio watcher..."
echo "[WATCHER] Directory certificati: $CERT_DIR"

# --- 1. Parsing haproxy.cfg ---
echo "[WATCHER] Parsing HAProxy config: $HAPROXY_CFG"

CERT_PATHS=$(grep -oP 'crt\s+\K\S+' "$HAPROXY_CFG")

if [ -z "$CERT_PATHS" ]; then
    echo "[WATCHER] Nessun certificato trovato in haproxy.cfg"
    exit 1
fi

echo "[WATCHER] Certificati trovati:"
echo "$CERT_PATHS"

# --- 2. Funzione per generare PEM ---
generate_pem() {
    local base="$1"
    local key="$base.key"
    local crt="$base.crt"
    local pem="$base.pem"

    echo "[WATCHER] Genero PEM per $base"

    while [ ! -f "$key" ] || [ ! -f "$crt" ]; do
        sleep 1
    done

    cat "$key" "$crt" > "$pem"
    chmod 644 "$pem"
}

# --- 3. Generazione iniziale ---
for cert in $CERT_PATHS; do
    base="$CERT_DIR/$(basename "$cert" .pem)"
    generate_pem "$base"
done

# --- 4. Monitoraggio ---
echo "[WATCHER] In ascolto modifiche..."

inotifywait -m -e modify,create,delete "$CERT_DIR" | while read -r path event file; do
    echo "[WATCHER] Modifica rilevata: $file"

    for cert in $CERT_PATHS; do
        base="$CERT_DIR/$(basename "$cert" .pem)"
        generate_pem "$base"
    done

    echo "[WATCHER] Ricarico HAProxy..."
    docker kill -s HUP "$HAPROXY_CONTAINER"
done