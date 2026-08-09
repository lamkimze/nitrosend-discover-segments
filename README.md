# Nitrosend Challenge — Discover Segments

Product Engineer challenge prototype: **AI-powered customer segment discovery** for [Nitrosend](https://nitrosend.com), plus a UX report.

Built with **Rails 8**, Hotwire, and Tailwind. Clustering is **deterministic** (no live LLM) so the demo is stable and explainable.

## Deliverables

| Item | Location |
| --- | --- |
| UX / product report | [docs/REPORT.md](docs/REPORT.md) |
| Feature demo | This app (local or staging URL below) |
| GitHub | https://github.com/lamkimze/nitrosend-discover-segments — collaborators invited: `@cosmoblk`, `@auscaster` |

## Demo walkthrough (≈2 minutes)

1. Open the app → **Horizon Travel** audiences.
2. Click **Discover segments**. Watch the short progress beat, then review proposed groups (e.g. *Japan · Luxury seekers*).
3. Open a segment → read **Why this group** and the **campaign recommendation** → **Accept as segment**.

Optional: **Reset demo** clears proposals/accepted segments (contacts stay). Run discovery again anytime.

## Local setup

```bash
bin/setup          # bundle, db:prepare
bin/rails db:seed  # Horizon Travel contacts (~112)
bin/dev            # web + Tailwind watch
```

Visit [http://localhost:3000](http://localhost:3000).

Or:

```bash
bin/rails server
bin/rails tailwindcss:watch   # separate terminal
```

## Design notes

- Restraint over “AI SaaS” chrome: paper background, teal accent, list rows, no glowing metric cards.
- Typography: Fraunces (display) + IBM Plex Sans (UI).
- Every proposed segment includes plain-English reasons — explainability is the product.
- Dropbox `DESIGN.md` / `theme.css` were not accessible during build; tokens can be swapped if those files are added later.

## How discovery works

`SegmentDiscoveryService` buckets contacts by destination + trip style, merges thin groups, scores strength from engagement/cohesion, and attaches templated campaign recommendations plus a few insights. Seed data is fixed (`Random.new(42)`) so reviewers see the same story.

## Docker

```bash
docker build -t nitrosend-discover .
docker run --rm -p 3000:80 \
  -e RAILS_MASTER_KEY="$(cat config/master.key)" \
  --name nitrosend-discover \
  nitrosend-discover
```

Seeds load automatically when the contact table is empty.

## Staging

**Live demo:** https://5c4fc7cdede105.lhr.life

> Tunnelled to a local Rails process. Keep `bin/rails server` (and the SSH tunnel) running while reviewers browse. If the link expires:
>
> ```bash
> bin/rails server -p 3000 -b 127.0.0.1
> ssh -R 80:127.0.0.1:3000 nokey@localhost.run
> ```
>
> For a longer-lived host, deploy the included `Dockerfile` / `render.yaml` to Render (set `RAILS_MASTER_KEY` from `config/master.key`).

## Collaborators

Please grant access to:

- [@cosmoblk](https://github.com/cosmoblk)
- [@auscaster](https://github.com/auscaster)
