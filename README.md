# HaproxyWatcher

HaproxyWatcher affianca una istanza di HAProxy a una di Caddy che si occupa della gestione automatica dei certificati TLS. Caddy ottiene e rinnova i certificati (es. tramite ACME), mentre HaproxyWatcher monitora la directory dei certificati, genera i file PEM combinando chiave e certificato e notifica HAProxy per ricaricare la configurazione.

**Caratteristiche principali**
- **Monitoraggio:** osserva la directory dei certificati e ricrea i file `.pem` quando chiave o certificato cambiano.
- **Generazione PEM:** concatena la chiave privata e il certificato in un singolo file `.pem` leggibile da HAProxy.
- **Ricarica HAProxy:** invia al container di HAProxy il segnale `HUP` per ricaricare i certificati senza downtime.
- **Healthcheck Docker:** il Dockerfile include un `HEALTHCHECK` che verifica che il processo di monitoraggio sia attivo.

**Variabili d'ambiente richieste**
- `CERT_DIR`: directory montata dove Caddy salva i certificati.
- `HAPROXY_CFG`: path al file `haproxy.cfg` (usato per estrarre i percorsi dei certificati).
- `HAPROXY_CONTAINER`: nome o id del container HAProxy da notificare.

**Come usarlo (esempio)**
Montare la directory dei certificati e il file di configurazione di HAProxy nel container, e impostare le variabili d'ambiente:

```bash
docker run -d --name haproxy-watcher \
	-e CERT_DIR=/certs \
	-e HAPROXY_CFG=/etc/haproxy/haproxy.cfg \
	-e HAPROXY_CONTAINER=haproxy \
	-v /path/to/caddy/certdir:/certs \
	-v /path/to/haproxy.cfg:/etc/haproxy/haproxy.cfg \
	your-registry/haproxy-watcher:latest
```

**Comportamento**
- All'avvio il watcher analizza il `haproxy.cfg` per trovare le direttive `crt` e determina i nomi base dei certificati.
- Per ciascun certificato, attende che siano presenti sia la chiave (`.key`) che il certificato (`.crt`), quindi concatena i due file in un `.pem` con permessi corretti.
- In modalità monitor (`inotifywait -m`) ricrea i `.pem` quando vengono create o modificate le chiavi/certificati e invia `docker kill -s HUP <HAPROXY_CONTAINER>` per ricaricare HAProxy.

**File rilevanti**
- [entrypoint.sh](entrypoint.sh): entrypoint che valida le variabili d'ambiente e avvia il watcher.
- [watcher.sh](watcher.sh): script principale che effettua parsing, genera PEM e notifica HAProxy.
- [Dockerfile](Dockerfile): immagine base e `HEALTHCHECK` per il container.

**Licenza**
Questo progetto è distribuito sotto GNU GPL v3. Vedi il file LICENSE per i dettagli.


