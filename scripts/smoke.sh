#!/usr/bin/env bash
# Smoke test for the composed platform: waits for every published endpoint.
set -u

TIMEOUT=${TIMEOUT:-180}
FAILED=0

check() {
  local name=$1 url=$2 want=${3:-200}
  local deadline=$((SECONDS + TIMEOUT))
  while ((SECONDS < deadline)); do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" || true)
    if [[ "$code" == "$want" ]]; then
      echo "OK   $name ($url → $code)"
      return 0
    fi
    sleep 3
  done
  echo "FAIL $name ($url → last=$code, wanted $want)"
  FAILED=1
}

echo "── frontends ──"
check "shell /"                 http://localhost:3000/
check "shell SPA fallback"      http://localhost:3000/slab/ud/computer-science-1
for port in 3001 3002 3003 3004 3005 3006; do
  check "remoteEntry :$port"    "http://localhost:$port/remoteEntry.js"
done

echo "── backends ──"
check "cs-mngr"          http://localhost:8081/ 404
check "theater-mngr"     http://localhost:8085/ 404
check "nc-mngr"          http://localhost:8086/ 200
check "physics-mngr"     http://localhost:8087/ 404
check "or-mngr"          http://localhost:8088/ 404
check "os-mngr"          http://localhost:8089/ 404
check "ai-mngr"          http://localhost:8090/ 404
check "programming-mngr" http://localhost:8091/ 404
check "finance-api"      http://localhost:8080/ 404
check "mailhog UI"       http://localhost:8025/ 200

exit $FAILED
