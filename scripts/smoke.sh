#!/usr/bin/env bash
# Smoke test for the composed platform: waits for every published endpoint.
set -u

TIMEOUT=${TIMEOUT:-180}
FAILED=0

# check <name> <url> [want] — want=any accepts any HTTP status (service is up)
check() {
  local name=$1 url=$2 want=${3:-200}
  local deadline=$((SECONDS + TIMEOUT)) code=000
  while ((SECONDS < deadline)); do
    code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" || true)
    if [[ "$want" == "any" && "$code" != "000" ]] || [[ "$code" == "$want" ]]; then
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
check "cs-mngr"          http://localhost:8081/ any
check "theater-mngr"     http://localhost:8085/ any
check "nc-mngr"          http://localhost:8086/ any
check "physics-mngr"     http://localhost:8087/ any
check "or-mngr"          http://localhost:8088/ any
check "os-mngr"          http://localhost:8089/ any
check "ai-mngr"          http://localhost:8090/ any
check "programming-mngr" http://localhost:8091/ any
check "finance-api"      http://localhost:8080/ any
check "mailhog UI"       http://localhost:8025/ 200

exit $FAILED
