# GBO S2S integration — feedback (QUOK88 lab)

**Kit:** [gbo-money-site-s2s-kit](https://github.com/Rog033ht/gbo-money-site-s2s-kit) v1.0.0  
**Environment:** staging · `TRACKER_ORIGIN=https://ads-staging.datavela.io`  
**Target:** `https://lab.quok88.com/`  
**Reference:** `missions-test-and-observe-runbook.md` (lab missions/VIP)

---

## 1. Required event mapping

| Your platform event | GBO S2S call | When |
|---------------------|--------------|------|
| Account created (`/sign-up`) | `POST registration` | **Once** per new user |
| Payment / top-up **success** (treasury webhook) | `POST deposit` | Each successful player payment |
| Login / `sign_in` mission accrual | **Do not send** | — |
| Mission **Claim** (bonus grant) | **Do not send** | — |
| Mission `deposit` dimension | **Do not send** (no hook in your stack) | — |
| Operator bonus-pool funding | **Do not send** | — |

---

## 2. API (unchanged from kit)

```http
POST https://ads-staging.datavela.io/api/v1/s2s/event
Authorization: Bearer {S2S_API_KEY}
Content-Type: application/json
```

**Registration**

```json
{
  "event": "registration",
  "clk_id": "clk_…",
  "properties": {
    "user_id": "{your_player_id}",
    "tenant_id": "quok88"
  }
}
```

**Deposit** (real payment only)

```json
{
  "event": "deposit",
  "clk_id": "clk_…",
  "value": 50,
  "currency": "USDT",
  "properties": {
    "order_id": "{payment_id}",
    "payment_method": "usdt"
  }
}
```

**Pass:** HTTP `200`, response `"attributed": true`, correct `"crid"`.

---

## 3. `clk_id` chain (required)

1. Ad funnel redirects to `https://lab.quok88.com/?clk_id=clk_…`
2. `clk-capture.js` → `localStorage.clk_id`
3. On sign-up: read `clk_id` → persist on user row (DB column)
4. All S2S calls use **the same stored `clk_id`** — do not generate a new one per session

---

## 4. Currency / amount

Your ledger uses **minor units** (e.g. `5000000` USDT minor).

GBO `deposit.value` expects **major units**:

| Your internal | Send to GBO |
|---------------|-------------|
| `5000000` USDT minor | `"value": 50, "currency": "USDT"` |

Do not send minor units as `value` — dashboard CPA and Meta postbacks will be wrong.

---

## 5. What lab missions test vs what GBO needs

| Lab test (runbook) | Validates GBO S2S? |
|--------------------|----------------------|
| Mission `sign_in` + **Claim** | **No** — internal bonus grant only |
| `/account/transactions` Reason = "Bonus grant" | **No** |
| New player `/sign-up` + S2S `registration` | **Yes** |
| Real player payment + S2S `deposit` | **Yes** |

Mission **Claim** is not a GBO deposit. Real treasury/payment webhook is required for `deposit`.

---

## 6. Common mistakes to avoid

| Mistake | Result |
|---------|--------|
| Send `registration` on every login | Inflated reg count on dashboard |
| Send `deposit` on mission Claim | Wrong conversion type (not a payment) |
| Send `deposit` with minor-unit `value` | Wrong amounts / CPA |
| No `clk_id` saved at sign-up | `"attributed": false` on all calls |
| Staging key on production URL | `401` |

---

## 7. Verification steps

### 7.1 API smoke (kit)

```bash
export S2S_API_KEY="s2s_…"
export TRACKER_ORIGIN=https://ads-staging.datavela.io
CAMP={campaign_id} CRID={crid} ./scripts/smoke-staging.sh
```

### 7.2 End-to-end (required sign-off)

1. Open operator test tracking URL (mobile UA)
2. Complete funnel → `lab.quok88.com?clk_id=…`
3. Confirm `localStorage.getItem('clk_id')`
4. **New player** sign-up (not login-only)
5. **Real test payment** (not mission claim)
6. Both S2S responses: `"attributed": true`

### 7.3 Report back

| Field | Value |
|-------|-------|
| Environment | staging |
| `crid` | |
| `user_id` | |
| `order_id` | |
| Registration response | `attributed: true` (screenshot, key redacted) |
| Deposit response | `attributed: true` (screenshot, key redacted) |
| Hook locations in code | sign-up handler / payment webhook paths |

---

## 8. Please confirm

Reply with:

1. **Exact code paths** where you call `POST /api/v1/s2s/event` (sign-up? login? claim? payment webhook?)
2. **Minor → major conversion** for `deposit.value` (formula / decimals per currency)
3. **Sample `properties`** you send (`user_id`, `order_id` format)

If hooks are on **login** or **mission claim**, move them to **sign-up** and **payment success** — no GBO API change required.

---

## 9. Compatibility summary

| Item | Supported without GBO change |
|------|------------------------------|
| Cloudflare Workers edge API | Yes |
| Tenant `quok88` + custom `user_id` in `properties` | Yes |
| USDT / multi-currency deposits (major units) | Yes |
| Extra fields in `properties` | Yes |
| New event types (`sign_in`, `mission_claim`) | No — use `registration` + `deposit` only |
| Mission claim as deposit proxy | No — use real payment webhook |
