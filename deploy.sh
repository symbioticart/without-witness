#!/usr/bin/env bash
# WITHOUT WITNESS — one-shot deploy to Render (symbioticart org).
# Repo committed already. Run this from Terminal:  bash deploy.sh
set -e
source ~/.zshrc >/dev/null 2>&1 || true

SLUG="without-witness"
OWNER="tea-d10qoks9c44c73e04sqg"   # kola's Render workspace

cd "$(dirname "$0")"

echo "→ 1/4  Pushing repo symbioticart/$SLUG (private)…"
if ! gh repo view "symbioticart/$SLUG" >/dev/null 2>&1; then
  gh repo create "symbioticart/$SLUG" --private --source=. --remote=origin --push \
    --description "WITHOUT WITNESS — open call site (MONOMO, Cicle I)"
else
  git remote get-url origin >/dev/null 2>&1 || git remote add origin "https://github.com/symbioticart/$SLUG.git"
  git push -u origin main
fi

echo "→ 2/4  Creating Render web service…"
RESP=$(curl -s -X POST "https://api.render.com/v1/services" \
  -H "Authorization: Bearer $RENDER_TOKEN" -H "Content-Type: application/json" \
  -d "{\"type\":\"web_service\",\"name\":\"$SLUG\",\"ownerId\":\"$OWNER\",\"repo\":\"https://github.com/symbioticart/$SLUG\",\"branch\":\"main\",\"autoDeploy\":\"yes\",\"serviceDetails\":{\"env\":\"node\",\"region\":\"frankfurt\",\"plan\":\"free\",\"envSpecificDetails\":{\"buildCommand\":\"echo ok\",\"startCommand\":\"node server.js\"}}}")
SERVICE_ID=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin)['service']['id'])" 2>/dev/null || true)
DEPLOY_ID=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('deployId',''))" 2>/dev/null || true)

if [ -z "$SERVICE_ID" ]; then echo "Render response:"; echo "$RESP"; exit 1; fi
echo "   service: $SERVICE_ID"

echo "→ 3/4  Waiting for live…"
until S=$(curl -s -H "Authorization: Bearer $RENDER_TOKEN" \
    "https://api.render.com/v1/services/$SERVICE_ID/deploys/$DEPLOY_ID" \
    | python3 -c "import json,sys; print(json.load(sys.stdin).get('status'))") && \
    [ "$S" != "build_in_progress" ] && [ "$S" != "update_in_progress" ] && [ "$S" != "created" ] && [ "$S" != "queued" ]; do
  printf '.'; sleep 20
done
echo " → $S"

echo "→ 4/4  Verifying…"
curl -s -o /dev/null -w "   https://$SLUG.onrender.com  →  HTTP %{http_code}\n" "https://$SLUG.onrender.com/"
echo "Done. Dashboard: https://dashboard.render.com/web/$SERVICE_ID"
