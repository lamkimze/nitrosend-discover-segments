# Nitrosend Challenge — AI Smart Audiences

Focused Rails prototype: **AI organises audiences from behaviour; the user still controls sending.**

## Product flow

```
Customer data → AI analyses behaviour → discovers segments → assigns contacts
→ Smart Audiences stay updated → user reviews “why” → creates campaign
```

## Stack

- Rails 8 + Hotwire UI + JSON API
- SQLite for portable staging (swap to PostgreSQL in production)
- Deterministic `Segmentation::Providers::Demo` by default (`SEGMENTATION_PROVIDER=demo`)
- Optional `openai` provider stub sharing the same interface
- `AnalyseAudienceJob` via Active Job `:async` (single-process staging)

## Demo walkthrough

1. Open **Smart Audiences** → see 500 contacts.
2. Click **Analyse audience** → progress states while the job runs.
3. Review audiences (Japan / Luxury / Budget / Highly Engaged) with confidence + evidence.
4. Open an audience → see assigned contacts and reasons.
5. Click **Create campaign** → audience already selected.
6. Click **Analyse audience** again to refresh memberships.

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

AI provider is abstracted (`Segmentation::Provider`). Staging uses the Demo provider so George always gets:

**Analyse → discover → auto-assign → inspect reasoning → create campaign**

Production can set `SEGMENTATION_PROVIDER=openai` without changing the domain layer.

## Staging

**Live demo:** https://courses-briefs-census-florida.trycloudflare.com

Local: http://127.0.0.1:3000

> Keep `bin/rails server` and the Cloudflare tunnel running while reviewers browse. Recreate with `cloudflared tunnel --url http://127.0.0.1:3000`.
