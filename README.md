# AFWILTO Platform

Everything — Module Federation shell, 6 microfrontends, 8 subject managers,
finance API and their databases — starts with:

```bash
docker compose up -d
```

Then open **http://localhost:3000**. Verify with `./scripts/smoke.sh`.

| Slice | URL |
|---|---|
| Root homepage | http://localhost:3000/ |
| Software Lab | http://localhost:3000/slab |
| UD subjects | http://localhost:3000/slab/ud |
| MATI | http://localhost:3000/slab/mati |
| CIDR Calculator | http://localhost:3000/slab/cidr |
| Finance | http://localhost:3000/finance |
| Certifications | http://localhost:3000/certifications |
| MailHog (theater emails) | http://localhost:8025 |

APIs publish on 8080 (finance), 8081–8091 (subject managers) and 8092 (CIDR calculator); databases are
network-internal only. All env vars have working defaults (`.env.example`).

- Architecture & specs: `frontend/docs/specs/` (start at `00`, deployment at `10`)
- Frontend workspace: `frontend/README.md`
- The finance data volume is shared with the former standalone stack
  (`personal-financial-status_pgdata`) — existing data carries over.
