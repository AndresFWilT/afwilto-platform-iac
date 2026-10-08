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
for port in 3001 3002 3003 3004 3005 3006 3007; do
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
check "certifications"   http://localhost:8082/healthz 200
check "love-points-mngr" http://localhost:8083/healthz 200
check "studies-mngr"     http://localhost:8084/healthz 200
check "mailhog UI"       http://localhost:8025/ 200

echo "── static cache policy ──"
# A missing Cache-Control on the unhashed entry points lets browsers apply
# heuristic freshness, so a rebuilt MFE never reaches an open tab (Spec 14 §10).
for port in 3000 3001 3002 3003 3004 3005 3006 3007; do
  cc=$(curl -sI "http://localhost:$port/" | tr -d '\r' | sed -n 's/^[Cc]ache-[Cc]ontrol: //p')
  if [[ "$cc" == *"no-cache"* || "$cc" == *"no-store"* ]]; then
    echo "OK   :$port index.html revalidates ($cc)"
  else
    echo "FAIL :$port index.html has no revalidating Cache-Control (got '${cc:-none}')"
    FAILED=1
  fi
done
for port in 3001 3002 3003 3004 3005 3006 3007; do
  cc=$(curl -sI "http://localhost:$port/remoteEntry.js" | tr -d '\r' | sed -n 's/^[Cc]ache-[Cc]ontrol: //p')
  if [[ "$cc" == *"no-cache"* || "$cc" == *"no-store"* ]]; then
    echo "OK   :$port remoteEntry.js revalidates ($cc)"
  else
    echo "FAIL :$port remoteEntry.js has no revalidating Cache-Control (got '${cc:-none}')"
    FAILED=1
  fi
done

# Certifications round-trip: create → get → patch → delete (GH-I1)
CERT_API=http://localhost:8082/api/v1
# NOTE: the response embeds a nested category object that also has an "id", so
# the id must be read from the first match — a greedy regex returns the wrong one.
cert_id=$(curl -s -X POST "$CERT_API/certifications" \
  -H 'Content-Type: application/json' \
  -d '{"name":"Smoke Test Cert '"$RANDOM"'","category":"Smoke / Test"}' |
  grep -o '"id":"[^"]*"' | head -1 | cut -d'"' -f4)
if [[ -n "$cert_id" ]]; then
  get_code=$(curl -s -o /dev/null -w "%{http_code}" "$CERT_API/certifications/$cert_id")
  # Spec 14: editing one field of a NON-achieved certification must succeed. The
  # pre-fix client sent every field, and the null credlyUrl tripped BR-EV1 (422).
  patch_code=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$CERT_API/certifications/$cert_id" \
    -H 'Content-Type: application/json' -d '{"expectedExamDate":"2027-03-01"}')
  del_code=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$CERT_API/certifications/$cert_id")
  if [[ "$get_code" == "200" && "$patch_code" == "200" && "$del_code" == "204" ]]; then
    echo "OK   certifications round-trip (POST→GET→PATCH→DELETE)"
  else
    echo "FAIL certifications round-trip (GET=$get_code PATCH=$patch_code DELETE=$del_code)"
    FAILED=1
  fi
else
  echo "FAIL certifications round-trip (create returned no id)"
  FAILED=1
fi

exit $FAILED
