# Integration

Kit version: `VERSION` file.

---

## 1. Inputs (from operator)

| Variable | Staging | Production |
|----------|---------|------------|
| `TRACKER_ORIGIN` | `https://ads-staging.datavela.io` | `https://ads.datavela.io` |
| `S2S_API_KEY` | `s2s_…` (36 chars) | separate key |
| Endpoint | `{TRACKER_ORIGIN}/api/v1/s2s/event` | same |
| Test URL | `https://…/c/{campaign_id}?source=meta&crid={crid}` | operator supplies |
| PWA bundle | `{slug}-pwa-bundle.json` | `files` object in JSON |

---

## 2. Server env

```bash
TRACKER_ORIGIN=https://ads-staging.datavela.io
S2S_API_KEY=s2s_xxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

Server only. Not in git. Not in frontend.

---

## 3. Static files (money site root)

From PWA bundle JSON `files` + kit `frontend/clk-capture.js`:

| Deploy path |
|-------------|
| `/manifest.webmanifest` |
| `/sw.js` |
| `/clk-capture.js` |

```html
<link rel="manifest" href="/manifest.webmanifest" />
<script src="/clk-capture.js"></script>
```

```js
if ('serviceWorker' in navigator) navigator.serviceWorker.register('/sw.js');
```

Funnel lands on `target_url?clk_id=clk_…` → `clk-capture.js` sets `localStorage.clk_id`.

---

## 4. Database

```sql
ALTER TABLE users ADD COLUMN clk_id VARCHAR(64) NULL;
```

Persist on registration. Reuse for all S2S calls for that user.

---

## 5. Backend hooks

| Event | Call |
|-------|------|
| Account created | `postRegistration(clk_id, { user_id })` |
| Payment webhook success | `postDeposit(clk_id, value, currency, { order_id })` |

```ts
import { postRegistration, postDeposit } from './s2s-client';

await postRegistration(user.clk_id, { user_id: String(user.id) });

await postDeposit(user.clk_id, amount, currency, { order_id: payment.id });
```

Reference: `server/s2s-client.ts`

---

## 6. API

```http
POST {TRACKER_ORIGIN}/api/v1/s2s/event
Authorization: Bearer {S2S_API_KEY}
Content-Type: application/json
```

**Registration**

```json
{"event":"registration","clk_id":"clk_…","properties":{"user_id":"12345"}}
```

**Deposit**

```json
{"event":"deposit","clk_id":"clk_…","value":50,"currency":"USD","properties":{"order_id":"ord_98765"}}
```

**200**

```json
{"attributed":true,"clk_id":"clk_…","crid":"cr88992","campaign_id":"meta01","source":"meta"}
```

| HTTP | |
|------|--|
| `200` + `attributed: true` | OK |
| `200` + `attributed: false` | No click session for `clk_id` |
| `401` | Key / environment mismatch |
| `400` | Invalid body |
| `5xx` | Retry 1s, 5s, 30s |

---

## 7. Test

```bash
BASE="https://ads-staging.datavela.io"
CAMP="{campaign_id}"
CRID="{crid}"
UA="Mozilla/5.0 (Linux; Android 14) AppleWebKit/537.36 Chrome/120.0.0.0 Mobile Safari/537.36"

curl -sS -D - -o /dev/null -A "$UA" \
  "${BASE}/c/${CAMP}?source=meta&crid=${CRID}&fbclid=test" \
  | grep -i 'set-cookie: clk_id'
```

```bash
S2S_KEY="s2s_…"
CLK="clk_…"

curl -sS -X POST "${BASE}/api/v1/s2s/event" \
  -H "Authorization: Bearer ${S2S_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"event\":\"registration\",\"clk_id\":\"${CLK}\",\"properties\":{\"user_id\":\"test_1\"}}"

curl -sS -X POST "${BASE}/api/v1/s2s/event" \
  -H "Authorization: Bearer ${S2S_KEY}" \
  -H "Content-Type: application/json" \
  -d "{\"event\":\"deposit\",\"clk_id\":\"${CLK}\",\"value\":50,\"currency\":\"USD\",\"properties\":{\"order_id\":\"test_1\"}}"
```

```bash
export S2S_API_KEY="s2s_…"
./scripts/smoke-staging.sh
```

E2E: tracking URL → register → deposit → both `attributed: true`.

---

## 8. Return to operator

| Field | |
|-------|--|
| Environment | `staging` / `production` |
| `crid` | |
| `user_id` | |
| `order_id` | |
| Registration JSON | `attributed: true` |
| Deposit JSON | `attributed: true` |
| Kit version | `VERSION` |
