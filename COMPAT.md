# API compatibility

| Kit | Ads stack | S2S endpoint | Events |
|-----|-----------|--------------|--------|
| 1.0.0 | [marketing-full-stack](https://github.com/Rog033ht/marketing-full-stack) @ `9651fba` | `POST /api/v1/s2s/event` | `registration`, `deposit` |

| Environment | `TRACKER_ORIGIN` |
|-------------|------------------|
| Staging | `https://ads-staging.datavela.io` |
| Production | `https://ads.datavela.io` |

Auth: `Authorization: Bearer s2s_…`
