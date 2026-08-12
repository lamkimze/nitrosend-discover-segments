# Nitrosend Challenge — AI Smart Audiences

Focused Rails prototype: **AI organises audiences from HubSpot-style CRM behaviour; the user still controls sending.**

## Product flow

```
HubSpot-style CRM
├── Contact data
├── Website page views
├── Email opens / clicks
├── Forms / CTAs
└── Purchase history
        ↓
AI engine (profiles → discovers segments → assigns contacts)
        ↓
Smart Audiences stay updated → user reviews “why” + campaign angle → creates campaign
```

Example signal: repeated visits to `/japan-tours`, `/tokyo-hotels`, `/osaka-packages` plus Japan email clicks → **Japan Enthusiasts** (confidence ~0.9).

This uses marketing CRM activity businesses already have — not in-app product analytics (feature usage, SaaS funnels, etc.).

## Stack

- Rails 8 + Hotwire UI + JSON API
- SQLite for portable staging (swap to PostgreSQL in production)
- Deterministic `Segmentation::Providers::Demo` by default (`SEGMENTATION_PROVIDER=demo`)
- Optional `openai` provider stub sharing the same interface
- `AnalyseAudienceJob` via Active Job `:async` (single-process staging)
- `Hubspot::IngestActivities` accepts HubSpot-shaped activity payloads for the demo sync

## Demo walkthrough

1. Open **Smart Audiences** → see ~500 contacts synced with page views, email engagement, and purchases.
2. Click **Refresh all** → progress states while the job runs (bookmarkable; leave and come back).
3. Review audiences (Japan Enthusiasts / Luxury / Budget / Highly Engaged / Frequent Buyers / Dormant) with confidence, evidence, and a **suggested campaign angle**.
4. Open an audience → see assigned contacts, reasons, and recent CRM activity — or **Dismiss** if unused.
5. Click **Create campaign** → audience already selected; subject prefilled from the angle.
6. Import a sample batch, then **Allocate new** to place only pending contacts.

## Local setup

```bash
bundle install
bin/rails db:prepare db:seed
bin/rails tailwindcss:build
bin/dev   # or bin/rails server
```

Visit http://localhost:3000

## API

| Method | Path | Purpose |
| --- | --- | --- |
| GET | `/health` | `{ "status": "ok" }` |
| POST | `/api/v1/audience/analyses` | Start analysis |
| GET | `/api/v1/audience/analyses/:id` | Poll status |
| GET | `/api/v1/segments` | List Smart Audiences |
| GET | `/api/v1/segments/:id` | Segment detail |
| GET | `/api/v1/segments/:id/contacts` | Members |

## Architecture note

AI provider is abstracted (`Segmentation::Provider`). Staging uses the Demo provider so reviewers always get:

**CRM activity → discover → auto-assign → inspect reasoning → create campaign (or dismiss)**

Production can set `SEGMENTATION_PROVIDER=openai` without changing the domain layer.

## Staging

**Live demo:** https://375c666a46b2fa.lhr.life

Local: http://127.0.0.1:3000

> Keep `bin/rails server` and a public tunnel running while reviewers browse.
> Cloudflare: `cloudflared tunnel --url http://127.0.0.1:3000`
> Or localhost.run: `ssh -R 80:http://127.0.0.1:3000 nokey@localhost.run`

## Collaborators

Invited with write access: [@cosmoblk](https://github.com/cosmoblk), [@auscaster](https://github.com/auscaster)

Repo: https://github.com/lamkimze/nitrosend-discover-segments

## Report

See [docs/REPORT.md](docs/REPORT.md) for the Product & UX write-up.
