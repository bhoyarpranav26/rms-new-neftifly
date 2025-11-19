# Deploying the Frontend (Netlify or Vercel)

This guide covers two quick ways to deploy the frontend with HTTPS + CDN: Netlify or Vercel.

Both options assume the repository root is `C:\RestoM-11` and the frontend code is in `frontend/`.

Prerequisites
- Node.js + npm installed
- (For CLI deploy) Netlify CLI or Vercel CLI installed and logged in
- If you use Netlify/Vercel Git integration: connect your GitHub repo and set the build settings below

Environment variable
- The frontend reads the backend base URL from `VITE_API_BASE_URL`. Provide a production backend URL (e.g. `https://api.example.com`) before building/deploy.
- Example file `frontend/.env.production.example` is included — copy to `.env.production` and set the value.

Build locally

PowerShell (from repo root):
```powershell
# From repo root
npm --prefix .\frontend install
# Set API base for the build (PowerShell):
$env:VITE_API_BASE_URL = 'https://<your-backend-url>'
npm --prefix .\frontend run build
# Or: cd frontend; set env and run build depending on your shell
```

The static build output will be in `frontend/dist`.

Option A — Deploy with Netlify (recommended if you want simple CLI or Git-based deploy)

1) Using Netlify UI (recommended for continuous deploy):
- Go to https://app.netlify.com, create a new site -> "Import from Git" -> choose your GitHub repo.
- Build settings:
  - Build command: `npm run build`
  - Publish directory: `frontend/dist`
- In Site settings -> Build & deploy -> Environment -> Add variable `VITE_API_BASE_URL` with your backend URL.
- Deploy the site. Netlify provides HTTPS and CDN automatically.

2) Using Netlify CLI (quick one-off / manual deploy):
```powershell
npm i -g netlify-cli
netlify login
# Optional interactive link: netlify init (follow prompts to create/link site)
# Deploy production from built dist folder:
netlify deploy --prod --dir=frontend\dist --site=YOUR_NETLIFY_SITE_ID
```
- To find `YOUR_NETLIFY_SITE_ID` use `netlify sites:list` or look in the site settings in the Netlify UI.

Netlify notes
- Make sure `VITE_API_BASE_URL` is set in Netlify UI for production.
- For single-page routing, Netlify handles SPA fine but you can add a `_redirects` file in `frontend/dist` if needed (the repo already includes `public/_redirects`).

Option B — Deploy with Vercel (also recommended)

1) Using Vercel UI (Git integration):
- Go to https://vercel.com/new -> import your GitHub repo.
- Vercel will auto-detect; set project root to `frontend/` if needed.
- Build Command: `npm run build`
- Output Directory: `dist`
- Add an environment variable `VITE_API_BASE_URL` (Production) in Project Settings -> Environment Variables.

2) Using Vercel CLI (quick deploy):
```powershell
npm i -g vercel
vercel login
# From the frontend folder
cd frontend
# First deploy (interactive) to create and configure project
vercel --prod
# Or run non-interactive with environment variable set
$env:VITE_API_BASE_URL = 'https://<your-backend-url>' ; vercel --prod --confirm
```
To set env vars via CLI:
```powershell
vercel env add VITE_API_BASE_URL production
# then paste the value when prompted
```

After deploy
- Both Netlify and Vercel provide a production domain (e.g. `https://your-site.netlify.app` or `https://your-site.vercel.app`).
- Add that domain to your backend CORS allow list (ECS/Express uses `CORS_ORIGIN`) or set `CORS_ORIGIN` in ECS if you want backend to allow this origin.

Connecting to your backend
- If your backend will later have an ALB DNS (e.g. `restom-alb-...amazonaws.com`), update the environment variable `VITE_API_BASE_URL` in the Netlify/Vercel project settings and trigger a redeploy.
- If you want me to perform the build and CLI deploy for you, provide either:
  - Netlify site ID and confirmation you want me to deploy via CLI, or
  - A Vercel token (not recommended to share here) and confirmation.

Security note
- Do not commit `.env.production` with secrets. Use the hosting provider's environment variables.

Files added
- `frontend/.env.production.example` — example env for production
- `frontend/netlify.toml` — optional Netlify config (used by Netlify when present)
- `frontend/DEPLOY.md` — this guide (you are reading it)

If you want I can:
- Build locally and perform a Netlify CLI deploy to your account (you must `netlify login` locally or share a site ID and grant deploy rights).
- Or give you step-by-step interactive commands to run in your terminal (I can provide exact PowerShell commands).