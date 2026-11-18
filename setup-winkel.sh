#!/bin/bash
# Richtet sandbox.lernknoten.ch auf HP-Winkel ein bzw. aktualisiert die Seite.
# Kann beliebig oft ausgeführt werden: Was schon da ist, wird übersprungen.
#
#   cd ~/docker/sandbox-lernknoten && ./setup-winkel.sh
#
# Einstellungen lassen sich per Umgebungsvariable überschreiben, z.B.
#   CADDYFILE=~/docker/caddy/Caddyfile CADDY_CONTAINER=caddy ./setup-winkel.sh

set -euo pipefail

DOMAIN="${DOMAIN:-sandbox.lernknoten.ch}"
SITE_CONTAINER="sandbox-lernknoten"
CADDYFILE="${CADDYFILE:-$HOME/docker/caddy/Caddyfile}"
CADDY_CONTAINER="${CADDY_CONTAINER:-caddy}"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"

ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
info() { printf '\033[36m→\033[0m %s\n' "$*"; }
warn() { printf '\033[33m!\033[0m %s\n' "$*"; }
fail() { printf '\033[31m✗\033[0m %s\n' "$*"; exit 1; }

command -v docker >/dev/null || fail "Docker nicht gefunden."
# Auf HP-Winkel braucht docker sudo (siehe dienste.md)
DOCKER="docker"
if ! docker ps >/dev/null 2>&1; then DOCKER="sudo docker"; fi
$DOCKER ps >/dev/null 2>&1 || fail "Docker läuft nicht oder keine Berechtigung."

# 1. DNS prüfen (nur Warnung, Caddy braucht den Eintrag für das Zertifikat)
WAN_IP="$(curl -fsS --max-time 5 https://api.ipify.org 2>/dev/null || true)"
info "Prüfe DNS für $DOMAIN"
DNS_IP="$(dig +short "$DOMAIN" A 2>/dev/null | tail -n1 || true)"
if [ -z "$DNS_IP" ]; then
  warn "Kein A Record für $DOMAIN gefunden. Bei Metanet anlegen (Ziel: ${WAN_IP:-öffentliche IP}), sonst scheitert das Zertifikat."
elif [ -n "$WAN_IP" ] && [ "$DNS_IP" != "$WAN_IP" ]; then
  warn "$DOMAIN zeigt auf $DNS_IP, die öffentliche IP ist aber $WAN_IP. Eintrag prüfen."
else
  ok "DNS für $DOMAIN zeigt auf $DNS_IP"
fi

# 2. Neuste Version holen
if [ -d "$REPO_DIR/.git" ]; then
  info "Hole neuste Version aus GitHub"
  git -C "$REPO_DIR" pull --ff-only && ok "Repo aktuell"
fi

# 3. Netzwerk und Container
$DOCKER network inspect proxy >/dev/null 2>&1 || fail "Docker Netzwerk 'proxy' fehlt (sollte auf HP-Winkel bestehen)."
info "Starte Container $SITE_CONTAINER"
# Immer neu erstellen: nginx.conf ist als einzelne Datei eingebunden. Nach einem git pull ist das
# eine neue Datei, der laufende Container sieht aber weiter die alte. Ein Reload genügt darum nicht.
(cd "$REPO_DIR" && $DOCKER compose up -d --force-recreate)
ok "Container läuft"

# 4. Caddy prüfen
$DOCKER inspect "$CADDY_CONTAINER" >/dev/null 2>&1 || fail "Caddy Container '$CADDY_CONTAINER' nicht gefunden. Name mit CADDY_CONTAINER=... angeben."
if ! $DOCKER inspect -f '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}' "$CADDY_CONTAINER" | grep -qw proxy; then
  fail "Caddy hängt nicht am Netzwerk 'proxy'."
fi
ok "Caddy Container: $CADDY_CONTAINER"

# 5. Caddyfile ergänzen (ein Block, falls er fehlt)
[ -f "$CADDYFILE" ] || fail "Caddyfile nicht gefunden: $CADDYFILE (Pfad mit CADDYFILE=... angeben)"
CHANGED=0
BACKUP=""
if grep -Eq "^[[:space:]]*$(printf '%s' "$DOMAIN" | sed 's/\./\\./g')([[:space:],{]|$)" "$CADDYFILE"; then
  ok "Block für $DOMAIN ist schon in der Caddyfile"
else
  BACKUP="$CADDYFILE.bak-$(date +%Y%m%d-%H%M%S)"
  cp "$CADDYFILE" "$BACKUP"
  info "Sicherung: $BACKUP"
  printf '\n%s {\n    reverse_proxy %s:80\n}\n' "$DOMAIN" "$SITE_CONTAINER" >> "$CADDYFILE"
  ok "Block für $DOMAIN ergänzt"
  CHANGED=1
fi

# 6. Caddy prüfen und neu laden
CONF_IN_CONTAINER="/etc/caddy/Caddyfile"
info "Prüfe Caddy Konfiguration"
if ! $DOCKER exec "$CADDY_CONTAINER" caddy validate --config "$CONF_IN_CONTAINER" --adapter caddyfile >/dev/null 2>&1; then
  if [ "$CHANGED" = 1 ]; then
    cp "$BACKUP" "$CADDYFILE"
    fail "Caddyfile ungültig, alte Version wiederhergestellt. Fehler anzeigen: $DOCKER exec $CADDY_CONTAINER caddy validate --config $CONF_IN_CONTAINER"
  fi
  fail "Caddyfile ungültig. Fehler anzeigen: $DOCKER exec $CADDY_CONTAINER caddy validate --config $CONF_IN_CONTAINER"
fi
$DOCKER exec "$CADDY_CONTAINER" caddy reload --config "$CONF_IN_CONTAINER" --adapter caddyfile >/dev/null
ok "Caddy neu geladen"

# 7. Testen (das erste Zertifikat kann ein paar Sekunden dauern)
info "Teste https://$DOMAIN"
CODE=""
for i in 1 2 3 4 5 6; do
  CODE="$(curl -s -o /dev/null -w '%{http_code}' --max-time 10 "https://$DOMAIN/" || true)"
  [ "$CODE" = "200" ] && break
  sleep 5
done
if [ "$CODE" = "200" ]; then
  ok "https://$DOMAIN ist online"
  HDR="$(curl -sI --max-time 10 "https://$DOMAIN/" | tr -d '\r' | grep -i '^cross-origin-' || true)"
  [ -n "$HDR" ] && ok "Header für die Live Eingabe vorhanden" || warn "COOP und COEP Header fehlen, die Live Eingabe fällt auf das Feld Eingaben zurück."
else
  LOCAL="$(curl -s -o /dev/null -w '%{http_code}' --max-time 5 "http://localhost:${SANDBOX_PORT:-8091}/" || true)"
  warn "https://$DOMAIN antwortet mit '$CODE' (lokal: '$LOCAL'). Logs: $DOCKER logs $CADDY_CONTAINER --tail 50"
  warn "Ist der Server im Heimnetz, kann es am NAT Loopback liegen: dann am Handy über Mobilfunk testen."
fi
