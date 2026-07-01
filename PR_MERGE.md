# PR merge

Target branch on money-site repo: `feature/gbo-s2s-staging`

---

## Option A — git subtree (vendor copy)

```bash
git checkout -b feature/gbo-s2s-staging
git subtree add --prefix=vendor/gbo-s2s-kit \
  https://github.com/Rog033ht/gbo-money-site-s2s-kit.git main --squash
```

Wire using paths under `vendor/gbo-s2s-kit/` — see [INTEGRATION.md](./INTEGRATION.md).

---

## Option B — copy files into your tree

| Kit path | Suggested money-site path |
|----------|---------------------------|
| `frontend/clk-capture.js` | `public/clk-capture.js` (or static root) |
| `server/s2s-client.ts` | `src/lib/gbo/s2s-client.ts` (adjust to your layout) |
| `server/.env.example` | merge into `.env.example` |

```bash
git checkout -b feature/gbo-s2s-staging
git remote add gbo-kit https://github.com/Rog033ht/gbo-money-site-s2s-kit.git
git fetch gbo-kit
# copy files manually or:
git checkout gbo-kit/main -- frontend/clk-capture.js server/s2s-client.ts
# move to your paths, then git add
```

---

## Option C — PR from fork

```bash
# fork github.com/Rog033ht/gbo-money-site-s2s-kit on GitHub
git clone git@github.com:{your-org}/gbo-money-site-s2s-kit.git /tmp/gbo-kit
cd /path/to/money-site
git checkout -b feature/gbo-s2s-staging
cp /tmp/gbo-kit/frontend/clk-capture.js ./public/
cp /tmp/gbo-kit/server/s2s-client.ts ./src/lib/gbo/
git add . && git commit -m "feat: GBO S2S kit v1.0.0"
git push -u origin feature/gbo-s2s-staging
# open PR → main on money-site repo
```

---

## After merge — required wiring

1. [INTEGRATION.md](./INTEGRATION.md) §2 — env vars on server
2. §3 — static files + PWA bundle from operator
3. §4 — `users.clk_id` migration
4. §5 — registration + payment webhook hooks
5. §7 — smoke + E2E
6. §8 — report to operator

Checklist: [docs/CHECKLIST.md](./docs/CHECKLIST.md)
