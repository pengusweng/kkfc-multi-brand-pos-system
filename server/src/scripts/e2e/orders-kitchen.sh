#!/usr/bin/env bash
set -Eeuo pipefail

# WSL cannot directly use Windows Node modules; use the installed Git Bash.
if ! command -v node >/dev/null && command -v node.exe >/dev/null && command -v wslpath >/dev/null && [[ -x '/mnt/c/Program Files/Git/bin/bash.exe' ]]; then
  exec '/mnt/c/Program Files/Git/bin/bash.exe' "$(wslpath -w "$(realpath "${BASH_SOURCE[0]}")")" "$@"
fi

if [[ ${1:-} == --help ]]; then
  cat <<'EOF'
Usage: bash src/scripts/e2e/orders-kitchen.sh [--check]

Requires a running API with seeded users and menu, configured S3 storage,
Node.js dependencies and curl. Set E2E_API_URL to override
http://127.0.0.1:3000/api. REJECTION_ROUNDS defaults to 1 and
REJECTIONS_PER_ROUND defaults to 2. The fixture users and their S3 uploads
are seeded accounts. Test orders and delivery images remain after the run.
EOF
  exit 0
fi
for tool in node curl; do command -v "$tool" >/dev/null || { printf 'Missing required command: %s\n' "$tool" >&2; exit 1; }; done
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$root"
api=${E2E_API_URL:-http://127.0.0.1:3000/api}
api=${api%/}
rounds=${REJECTION_ROUNDS:-1}
portions=${REJECTIONS_PER_ROUND:-2}
[[ $rounds =~ ^[1-9][0-9]*$ && $portions =~ ^[1-9][0-9]*$ ]] || { echo 'Rejection settings must be positive integers.' >&2; exit 1; }
(( portions <= 9999 )) || { echo 'REJECTIONS_PER_ROUND cannot exceed 9999.' >&2; exit 1; }
[[ -d node_modules ]] || { echo 'Install server dependencies first.' >&2; exit 1; }
S3_BUCKET=$(node -e 'require("dotenv").config({path:[".env.test", ".env."+(process.env.NODE_ENV || "development"), ".env", "../.env"], quiet:true}); process.stdout.write(process.env.S3_BUCKET || "")')
export S3_BUCKET
[[ -n $S3_BUCKET ]] || { echo 'Set S3_BUCKET in the environment or a server .env file.' >&2; exit 1; }
tmp=$(mktemp -d)
json_helper="$root/src/scripts/e2e/json.cjs"
json() { node "$json_helper" "$@"; }
response="$tmp/response.json"
cleanup() {
  local status=$?
  trap - EXIT
  for token in "${cashier:-}" "${head:-}" "${staff:-}" "${supervisor:-}"; do
    [[ -z $token ]] || curl -sS -o /dev/null -X POST -H "Authorization: Bearer $token" "$api/auth/logout" || true
  done
  rm -f "$tmp/response.json" "$tmp/image.png"
  rmdir "$tmp" 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
password=${E2E_PASSWORD:-Password123!}

call() {
  local expected=$1 method=$2 path=$3 token=$4 body=${5:-}
  local -a opts=(-sS -o "$response" -w '%{http_code}' -X "$method")
  [[ -z $token ]] || opts+=(-H "Authorization: Bearer $token")
  [[ -z $body ]] || opts+=(-H 'Content-Type: application/json' --data "$body")
  local status
  status=$(curl "${opts[@]}" "$api$path") || { echo "Request failed: $method $path" >&2; return 1; }
  if [[ $status != "$expected" ]]; then
    printf 'Expected %s, got %s: %s %s\n' "$expected" "$status" "$method" "$path" >&2
    cat "$response" >&2; printf '\n' >&2; return 1
  fi
}
check() { json check "$response" "$@" || { cat "$response" >&2; return 1; }; }
login() {
  local username=$1
  call 200 POST /auth/login '' "$(E2E_LOGIN_PASSWORD="$password" json login "$username")" || {
    printf 'Seeded user %s could not log in. Check the server seed and E2E_PASSWORD.\n' "$username" >&2
    return 1
  }
  json get "$response" token
}
cashier=$(login test_order_staff)
head=$(login test_chef)
staff=$(login test_kitchen)
supervisor=$(login test_owner)
call 200 GET /auth/me "$staff"
preparer=$(json get "$response" user_id)
call 200 GET /auth/me "$head"
checker=$(json get "$response" user_id)
call 200 GET "/menu-items/${E2E_MENU_ITEM_CODE:-GC-KIMCHI-FRIED-RICE}" "$cashier"
item=$(json get "$response" menu_item_id)
brand=$(json get "$response" brand_id)
if [[ ${1:-} == --check ]]; then
  echo 'Seeded users and menu are available.'
  exit 0
fi
echo 'Using seeded users and menu. Test orders and delivery images remain in the connected environment.'
node -e "require('sharp')({create:{width:1,height:1,channels:3,background:'#ffffff'}}).png().toFile(process.argv[1]).catch(error=>{console.error(error);process.exitCode=1})" "$tmp/image.png"
image_file=$tmp/image.png
if command -v cygpath >/dev/null; then image_file=$(cygpath -m "$image_file"); fi
[[ -f $tmp/image.png ]] || { echo 'Could not create the temporary handoff image.' >&2; exit 1; }

run_flow() {
  local mode=$1 order_id payload ticket_id line_id attempt_id round rejection_body status
  order_id=$(node -p "require('node:crypto').randomUUID()")
  printf 'Running %s: order %s\n' "$mode" "$order_id"
  payload=$(json order "$order_id" "$item" "$([[ $mode == delivery ]] && echo GRABFOOD || echo TAKEAWAY)" "$portions")
  call 201 POST "/brands/$brand/orders" "$cashier" "$payload"; check draft
  if [[ $mode == delivery ]]; then payload='{}'; else payload='{"payment_method":"CASH","payment_status":"UNPAID"}'; fi
  call 200 POST "/brands/$brand/orders/$order_id/confirm" "$cashier" "$payload"; check confirmed
  ticket_id=$(json get "$response" kitchen_tickets_order.kitchen_ticket_id)
  line_id=$(json get "$response" order_items_order.0.order_item_id)
  call 403 POST "/kitchen-fulfillment/$ticket_id/acknowledge" "$cashier"
  call 409 POST "/kitchen-fulfillment/$ticket_id/hand-over" "$staff"
  call 200 PATCH "/kitchen-ticket/$ticket_id/preparer" "$staff" "$(json assign preparer_id "$preparer")"; check preparer "$preparer"
  call 409 PATCH "/kitchen-ticket/$ticket_id/preparer" "$staff" "$(json assign preparer_id "$preparer")"
  call 200 PATCH "/kitchen-ticket/$ticket_id/checker" "$head" "$(json assign checker_id "$checker")"
  call 200 POST "/kitchen-fulfillment/$ticket_id/acknowledge" "$staff"; check status ACKNOWLEDGED
  call 403 POST "/kitchen-fulfillment/$ticket_id/prepare" "$head"
  call 200 POST "/kitchen-fulfillment/$ticket_id/prepare" "$staff"; check prepared
  call 200 POST "/kitchen-fulfillment/$ticket_id/for-checking" "$staff"; check status FOR_CHECKING
  call 200 POST "/kitchen-fulfillment/$ticket_id/check" "$head"; check checking 1
  attempt_id=$(json get "$response" attempt.qc_attempt_id)
  if [[ $mode == rejection ]]; then
    for ((round=1; round<=rounds; round++)); do
      rejection_body=$(json rejections "$line_id" "$portions" invalid)
      call 400 POST "/kitchen-fulfillment/qc-attempts/$attempt_id/reject" "$head" "$rejection_body"
      call 200 GET "/kitchen-qc/$attempt_id" "$head"; check status IN_PROGRESS
      rejection_body=$(json rejections "$line_id" "$portions")
      call 200 POST "/kitchen-fulfillment/qc-attempts/$attempt_id/reject" "$head" "$rejection_body"; check rejected "$portions"
      call 200 GET "/order-item-qc-rejection/attempt/$attempt_id" "$head"
      check rejections "$portions" "$line_id" "$attempt_id"
      call 200 POST "/kitchen-fulfillment/$ticket_id/for-checking" "$staff"; check status FOR_CHECKING
      call 200 POST "/kitchen-fulfillment/$ticket_id/check" "$head"; check checking "$((round+1))"
      attempt_id=$(json get "$response" attempt.qc_attempt_id)
    done
  fi
  call 200 POST "/kitchen-fulfillment/qc-attempts/$attempt_id/pass" "$head"; check ready
  if [[ $mode == delivery ]]; then
    call 400 POST "/kitchen-fulfillment/$ticket_id/hand-over" "$staff"; check code EMPTY_HANDOFF_IMAGES
    local -a uploads=()
    for ((i=0; i<6; i++)); do uploads+=(-F "files=@$image_file;type=image/png"); done
    status=$(curl -sS -o "$response" -w '%{http_code}' -X POST -H "Authorization: Bearer $staff" "${uploads[@]}" "$api/kitchen-fulfillment/$ticket_id/hand-over")
    [[ $status == 400 ]] || { printf 'Expected 400 for six images, got %s\n' "$status" >&2; return 1; }
    call 200 GET "/kitchen-ticket/$ticket_id" "$staff"; check status READY
    status=$(curl -sS -o "$response" -w '%{http_code}' -X POST -H "Authorization: Bearer $staff" -F "files=@$image_file;type=image/png" "$api/kitchen-fulfillment/$ticket_id/hand-over")
    [[ $status == 200 ]] || { printf 'Delivery handover failed (%s): ' "$status" >&2; cat "$response" >&2; return 1; }
  else
    call 200 POST "/kitchen-fulfillment/$ticket_id/hand-over" "$staff"
  fi
  check completed
  call 200 GET "/kitchen-ticket/$ticket_id" "$staff"; check status HANDED_OVER
  if [[ $mode == delivery ]]; then
    call 200 GET "/handoff/actor/$preparer" "$head"
    check handoff "$ticket_id"
  fi
  call 409 POST "/kitchen-fulfillment/brands/$brand/orders/$order_id/cancel" "$supervisor" '{"cancellation_reason":"Too late"}'
  printf 'PASS %s\n' "$mode"
}

call 401 POST '/kitchen-fulfillment/00000000-0000-4000-8000-000000000001/acknowledge' ''
run_flow normal
run_flow rejection
run_flow delivery
echo 'All orders–kitchen E2E scenarios passed.'
