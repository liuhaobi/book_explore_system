# SourceForge OAuth gateway

This project is a Cloudflare Worker. It exchanges SourceForge authorization
codes without exposing the OAuth client secret to the Flutter application.

## Endpoints

- `GET /health`
- `GET /source/auth/callback`
- `POST /source/auth/token`

The token endpoint accepts JSON containing `code`, `code_verifier`, and
optionally `client_id`. It returns the upstream `access_token` object only
when the exchange succeeds.

## Cloudflare configuration

Set the secret values before deploying:

```bash
npx wrangler secret put SOURCEFORGE_CLIENT_ID
npx wrangler secret put SOURCEFORGE_CLIENT_SECRET
npx wrangler deploy
```

The non-secret OAuth URL settings are in `wrangler.toml`. For local
development, copy `.dev.vars.example` to `.dev.vars` and run:

```bash
npx wrangler dev
```
