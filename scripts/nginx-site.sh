#!/usr/bin/env bash
# nginx-site — manage Nginx vhosts with shared permissions + local HTTPS (Valet-like)
# Fully automatic permissions, SSL, and colorful output

set -euo pipefail

# === COLORS ===
BOLD="\e[1m"; RED="\e[31m"; GREEN="\e[32m"; YELLOW="\e[33m"; BLUE="\e[34m"; RESET="\e[0m"

PROGRAM_NAME="nginx-site"
DEFAULT_WEBROOT_BASE="/srv/http"
SITES_AVAILABLE="/etc/nginx/sites-available"
SITES_ENABLED="/etc/nginx/sites-enabled"
SSL_DIR="/etc/nginx/ssl"
WEBGROUP="webshare"

log() { printf "${BLUE}[${PROGRAM_NAME}]${RESET} %s\n" "$*"; }
fail() { printf "${RED}[${PROGRAM_NAME} ERROR] %s${RESET}\n" "$*" >&2; exit 1; }

need_root() { [[ $EUID -eq 0 ]] || fail "Run with sudo."; }
cmd_exists() { command -v "$1" >/dev/null 2>&1; }

nginx_user() {
  local user
  user=$(awk '/^user\s+/{print $2; exit}' /etc/nginx/nginx.conf 2>/dev/null | sed 's/;//') || true
  [[ -z "${user:-}" ]] && { id -u http &>/dev/null && echo http || echo www-data; } || echo "$user"
}

ensure_dirs() { mkdir -p "$SITES_AVAILABLE" "$SITES_ENABLED" "$SSL_DIR"; }

ensure_include() {
  local conf=/etc/nginx/nginx.conf
  if ! grep -q "sites-enabled/\*\.conf" "$conf"; then
    log "Injecting include /etc/nginx/sites-enabled/*.conf into nginx.conf"
    cp -n "$conf" "$conf.bak.$(date +%Y%m%d%H%M%S)"
    awk '
      BEGIN{done=0}
      /http\s*\{/ {print; next}
      /\}$/ && done==0 {print "    include /etc/nginx/sites-enabled/*.conf;"; done=1; print; next}
      {print}
    ' "$conf" >"$conf.tmp" && mv "$conf.tmp" "$conf"
  fi
}

ensure_group() {
  local nguser=$(nginx_user)
  getent group "$WEBGROUP" >/dev/null || groupadd "$WEBGROUP"
  gpasswd -a ${SUDO_USER:-$USER} "$WEBGROUP" >/dev/null || true
  gpasswd -a "$nguser" "$WEBGROUP" >/dev/null || true
}

apply_shared_perms() {
  local path="$1"
  [[ -d "$path" ]] || fail "Path not found: $path"
  chown -R ${SUDO_USER:-$USER}:$WEBGROUP "$path"
  chmod -R g+rwX "$path"
  find "$path" -type d -exec chmod g+s {} +
  if cmd_exists setfacl; then
    setfacl -R -m g:$WEBGROUP:rwx "$path"
    setfacl -dR -m g:$WEBGROUP:rwx "$path"
  fi
}

reset_perms() {
  local path="$1"
  [[ -d "$path" ]] || return 0
  chown -R ${SUDO_USER:-$USER}:${SUDO_USER:-$USER} "$path"
  chmod -R 755 "$path"
  find "$path" -type f -exec chmod 644 {} +
  if cmd_exists setfacl; then setfacl -Rb "$path"; fi
}

write_server_block() {
  local domain="$1" root="$2" index="$3" php_fpm="$4"
  local conf="$SITES_AVAILABLE/$domain.conf"
  cat >"$conf" <<CONF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    root $root;
    index $index;

    access_log /var/log/nginx/${domain}.access.log;
    error_log  /var/log/nginx/${domain}.error.log warn;

    location / { try_files \$uri \$uri/ /index.php?\$query_string; }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass $php_fpm;
        fastcgi_index index.php;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff2?)$ { expires max; log_not_found off; }
}
CONF
}

write_ssl_block_mkcert() {
  local domain="$1" root="$2" index="$3" php_fpm="$4" crt="$5" key="$6"
  local conf="$SITES_AVAILABLE/$domain.conf"
  cat >"$conf" <<CONF
server {
    listen 80;
    listen [::]:80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}

server {
    listen 443 ssl;
    listen [::]:443 ssl;
    http2 on;
    server_name $domain;
    root $root;
    index $index;

    ssl_certificate     $crt;
    ssl_certificate_key $key;

    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

    access_log /var/log/nginx/${domain}.access.log;
    error_log  /var/log/nginx/${domain}.error.log warn;

    location / { try_files \$uri \$uri/ /index.php?\$query_string; }

    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        fastcgi_pass $php_fpm;
        fastcgi_index index.php;
    }

    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff2?)$ { expires max; log_not_found off; }
}
CONF
}

enable_site() { ln -sf "$SITES_AVAILABLE/$1.conf" "$SITES_ENABLED/$1.conf"; }
disable_site() { rm -f "$SITES_ENABLED/$1.conf"; }
reload_nginx() { nginx -t && systemctl reload nginx; }

mk_hosts_entry() {
  local domain="$1"
  if ! grep -qE "\s$domain(\s|$)" /etc/hosts; then
    echo -e "127.0.0.1\t$domain" >> /etc/hosts
    echo -e "::1\t$domain" >> /etc/hosts
  fi
}

issue_mkcert() {
  local domain="$1"
  mkdir -p "$SSL_DIR/$domain"
  local crt="$SSL_DIR/$domain/$domain.crt"
  local key="$SSL_DIR/$domain/$domain.key"
  mkcert -install
  mkcert -cert-file "$crt" -key-file "$key" "$domain"
  chmod 640 "$crt" "$key"
  chgrp $(nginx_user) "$key" || true
  echo "$crt|$key"
}

issue_letsencrypt() {
  local domain="$1" root="$2"
  certbot certonly --agree-tos --non-interactive --register-unsafely-without-email \
    --webroot -w "$root" -d "$domain"
  echo "/etc/letsencrypt/live/$domain/fullchain.pem|/etc/letsencrypt/live/$domain/privkey.pem"
}

usage() {
  echo -e "${BOLD}${GREEN}${PROGRAM_NAME} — Manage Nginx sites with SSL and shared permissions${RESET}"
  echo -e "\n${YELLOW}Usage:${RESET} sudo ${PROGRAM_NAME} <command> [options]\n"
  echo -e "${BLUE}Commands:${RESET}"
  echo -e "  ${GREEN}add${RESET}        <domain> [--root PATH]    → Create new site and auto perms"
  echo -e "  ${GREEN}secure${RESET}     <domain> [--mkcert]     → Enable HTTPS (auto root detect)"
  echo -e "  ${GREEN}remove${RESET}     <domain> [--purge-root] → Remove site + reset perms"
  echo -e "  ${GREEN}list${RESET}                           → Show all sites"
  echo -e "  ${GREEN}fix-perms${RESET}  <path>              → Reapply shared permissions"
  echo -e "\n${BLUE}Examples:${RESET}"
  echo -e "  sudo ${PROGRAM_NAME} ${GREEN}add${RESET} myapp.test --root ~/websites/myapp"
  echo -e "  sudo ${PROGRAM_NAME} ${GREEN}secure${RESET} myapp.test --mkcert"
  echo -e "  sudo ${PROGRAM_NAME} ${GREEN}remove${RESET} myapp.test --purge-root"
}

cmd_add() {
  need_root; ensure_dirs; ensure_include; ensure_group
  local domain="$1"; shift || true
  local root="$DEFAULT_WEBROOT_BASE/$domain"
  local php_fpm="unix:/run/php-fpm/php-fpm.sock"
  local index="index.php index.html"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --root) root="$2"; shift 2;;
      --php-fpm) php_fpm="$2"; shift 2;;
      --index) index="$2"; shift 2;;
      *) fail "Unknown option: $1";;
    esac
  done
  root=$(realpath "$root"); mkdir -p "$root"
  apply_shared_perms "$root"
  write_server_block "$domain" "$root" "$index" "$php_fpm" >/dev/null
  enable_site "$domain"; mk_hosts_entry "$domain"; reload_nginx
  log "✅ Site added: $domain"
  log "📂 Root: $root"
}

cmd_secure() {
  need_root; ensure_dirs; ensure_include
  local domain="$1"; shift || true
  local mode="mkcert" root=""
  local php_fpm="unix:/run/php-fpm/php-fpm.sock"
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --mkcert) mode="mkcert"; shift;;
      --letsencrypt) mode="letsencrypt"; shift;;
      --root) root="$2"; shift 2;;
      --php-fpm) php_fpm="$2"; shift 2;;
      *) fail "Unknown option: $1";;
    esac
  done

  # 🔍 Detect root automatically if not provided
  if [[ -z "$root" ]]; then
    root=$(awk '/root\s+/{print $2; exit}' "$SITES_AVAILABLE/$domain.conf" 2>/dev/null | sed 's/;//' || true)
    [[ -z "$root" ]] && root="$DEFAULT_WEBROOT_BASE/$domain"
  fi
  root=$(realpath -m "$root")

  local crt key
  if [[ "$mode" == "mkcert" ]]; then
    IFS='|' read -r crt key < <(issue_mkcert "$domain"); mk_hosts_entry "$domain"
  else
    IFS='|' read -r crt key < <(issue_letsencrypt "$domain" "$root")
  fi
  write_ssl_block_mkcert "$domain" "$root" "index.php index.html" "$php_fpm" "$crt" "$key" >/dev/null
  enable_site "$domain"; reload_nginx
  log "🔒 HTTPS enabled ($mode) for $domain"
}

cmd_remove() {
  need_root
  local domain="$1"; shift || true
  local purge_root=0
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --purge-root) purge_root=1; shift;;
      *) fail "Unknown option: $1";;
    esac
  done
  local conf="$SITES_AVAILABLE/$domain.conf"
  local root_guess=""
  [[ -f "$conf" ]] && root_guess=$(awk '/root\s+/{print $2}' "$conf" | sed 's/;//' | head -n1)
  disable_site "$domain"; rm -f "$conf"
  reload_nginx
  [[ -n "$root_guess" ]] && reset_perms "$root_guess"
  if (( purge_root )); then rm -rf "$root_guess" "$SSL_DIR/$domain"; fi
  log "🗑️ Site removed: $domain"
}

cmd_list() {
  printf "%-35s %-8s %s\n" "DOMAIN" "ENABLED" "ROOT"
  for f in "$SITES_AVAILABLE"/*.conf; do
    [[ -e "$f" ]] || continue
    local domain root enabled
    domain=$(basename "$f" .conf)
    enabled="no"
    [[ -L "$SITES_ENABLED/$domain.conf" ]] && enabled="yes"
    root=$(awk '/root\s+/{print $2; exit}' "$f" | sed 's/;//')
    printf "%-35s %-8s %s\n" "$domain" "$enabled" "$root"
  done
}

cmd_fix_perms() {
  need_root; ensure_group
  local path="$1"; [[ -d "$path" ]] || fail "Path not found: $path"
  apply_shared_perms "$path"
  log "🔧 Permissions fixed for $path"
}

main() {
  local cmd="${1:-}"; shift || true
  case "$cmd" in
    add) cmd_add "$@";;
    secure) cmd_secure "$@";;
    remove) cmd_remove "$@";;
    list) cmd_list;;
    fix-perms|perms) cmd_fix_perms "$@";;
    -h|--help|help|"") usage;;
    *) fail "Unknown command: $cmd";;
  esac
}

main "$@"
