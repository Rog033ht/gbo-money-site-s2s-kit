# Checklist

- [ ] `TRACKER_ORIGIN` + `S2S_API_KEY` (server env)
- [ ] `manifest.webmanifest`, `sw.js`, `clk-capture.js` on web root
- [ ] `users.clk_id` column + set on registration
- [ ] `postRegistration` on account create
- [ ] `postDeposit` on payment success webhook only
- [ ] `./scripts/smoke-staging.sh` pass
- [ ] E2E: tracking URL → register → deposit → `attributed: true` ×2
- [ ] Report §8 in [INTEGRATION.md](../INTEGRATION.md)

Production:

- [ ] New production `S2S_API_KEY`
- [ ] `TRACKER_ORIGIN=https://ads.datavela.io`
- [ ] Repeat E2E
