---
author: gene
title: Lightning-Gated Podcast Members Feeds with BTCPay Server
date: 2026-05-04
description: >-
  A practical guide to self-hosted Bitcoin-native podcast membership using
  BTCPay Server, private RSS feeds, and a small token service — compatible
  with Fountain, Castamatic, and any Podcasting 2.0 player.
image:
  path: '/assets/images/posts/2026-05-04-lightning-podcast-members.jpg'
tags:
  - bitcoin
  - lightning
  - podcasting
  - btcpay
  - nostr
  - self-hosted
---

## Introduction

You make a Bitcoin podcast. Your audience already streams sats while they listen and boosts episodes they love. Now you want to offer something more: a members-only feed with bonus content, available only to paying supporters, compatible with the apps your listeners already use — Fountain, Castamatic, and any other Podcasting 2.0 player.

The catch is that you want to do this without Patreon, without Stripe, and without handing a platform a cut of every payment. You want Bitcoin-native subscriptions that go directly to you, managed on infrastructure you control.

This article describes a practical, self-hosted architecture for exactly that. It is written for the podcaster who wants to understand how the pieces fit together, and for the developer — perhaps a technically-minded co-host — who will build and maintain it. The complete reference implementation, including all source code, NixOS configuration, and alerting rules, lives at [github.com/genebean/podcast-members-feed](https://github.com/genebean/podcast-members-feed). Two deployment paths are covered: one built on Umbrel that most people can follow without prior server administration experience, and one built on NixOS for a fully declarative, production-grade system.

One note before we begin: if you and your listeners are already streaming sats and boosting, value-for-value is already working for your public feed. This architecture sits alongside that — it does not replace it. Members get a private feed with bonus content; everyone else keeps listening and paying however they choose.

## Subscriber Experience

Before getting into how this works technically, it helps to understand what you are building from your listener's perspective. This is also the story you will tell your audience when you launch.

A listener visits your members page and picks a plan — monthly or annual. They pay a Lightning invoice with their wallet of choice. Payment settles in seconds. Within a minute they receive an email containing their private podcast feed URL. They open Fountain, Castamatic, or whichever podcast app they use, find the option to add a podcast by URL, and paste the link. The members feed appears in their library alongside their other shows. New bonus episodes appear automatically when you publish them, exactly like any other podcast. There is no app to install, no account to create, no password to remember.

When their subscription is approaching expiry, they receive a reminder email. They pay again and nothing changes in their podcast app — the same URL keeps working, silently extended in the background.

If a subscription lapses without renewal, the podcast app will eventually try to refresh the feed and receive a different experience depending on timing. On the first poll after expiry, a synthetic episode appears at the top of the feed with a title like "Your subscription has expired" — and if you record a short audio clip, it plays that clip. After that first notification episode is delivered, subsequent polls receive a 402 Payment Required response and the app stops updating. This gives the listener a graceful in-app notice rather than a silent failure.

**If a subscriber provides their Nostr npub during checkout,** the experience gains two meaningful additions. First, their feed URL arrives as an encrypted direct message in Damus, Primal, Amethyst, YakiHonne, or whichever Nostr client they use — alongside their other messages rather than buried in email. Second, at the same time as the expiry episode is served, they receive a Nostr DM reminding them their subscription has lapsed and directing them to renew. And if they ever lose their feed URL, they can retrieve it themselves without emailing you — see the Nostr section below for how this works.

A subscriber does not need to provide an email address if they provide their Nostr npub, and vice versa. At least one is required. For a Nostr-native listener who prefers not to share their email, npub-only is fully supported.

## How It Works

The subscriber experience above is produced by three pieces working together.

When a listener pays, BTCPay Server receives and settles the Lightning invoice, records the subscription, and immediately fires a webhook — an automated HTTP notification — to a small service running on your server. That service, which we call the token service, generates a unique random string, stores it in a database alongside the subscriber's contact details and expiry date, and constructs a private RSS feed URL containing that token. It then delivers the URL by email and Nostr DM as applicable.

When a podcast app polls the feed URL, the token service checks the token against the database. If valid and not expired, it fetches the actual RSS feed from PodServer and returns it to the app. PodServer's real feed URL is never exposed to subscribers. If the token has just expired and has not yet been notified, the service injects a synthetic expiry episode into the feed before returning it, marks the token as notified, and fires a Nostr DM if the subscriber has a pubkey. Subsequent requests for the expired token receive a 402.

When BTCPay fires a renewal webhook, the token service extends the expiry on the subscriber's existing token rather than issuing a new URL — the subscriber's podcast app never needs updating. If a subscriber lapses and then re-subscribes later, a new token is issued and the feed URL is re-delivered.

When a subscription expires or is suspended, any active tokens for that subscriber are revoked immediately.

## The Stack

**BTCPay Server** handles everything money-related: Lightning invoices, subscription plans, renewal reminders, and webhooks. It is self-hosted, open-source, and takes no fees. Its native subscription system handles monthly and annual billing, sends renewal reminders automatically, and provides a subscriber management dashboard.

**Alby Hub** is a self-hosted Lightning node management layer that sits in front of LND. It handles channel management, liquidity monitoring, and the connection interface that BTCPay uses to interact with Lightning. On Umbrel it is a one-click app store install. On NixOS it runs as a Podman container alongside nix-bitcoin's LND service. Both paths connect BTCPay to Alby Hub rather than to LND directly, which makes Lightning significantly more approachable day-to-day.

**PodServer** is a BTCPay Server plugin that adds podcast hosting to your BTCPay instance. It generates a valid RSS feed with Podcasting 2.0 tags including value splits, and manages your audio files. You will use it to host the members-only feed separately from your public feed.

**The token service** is a small Python application — the glue between BTCPay and your private RSS feed. The complete source is at `pkgs/podcast-token-service/token_service.py` in the repository. It listens for BTCPay webhooks, manages tokenized feed URLs, proxies the private feed, delivers notifications via email and Nostr DM, and exposes Prometheus metrics. This is the only custom code in the stack.

## Infrastructure Considerations

### Bitcoin Node

Both deployment paths require a local Bitcoin node. LND needs a Bitcoin chain backend, and both Umbrel's LND and nix-bitcoin's LND are wired to a local Bitcoin Core instance.

**Full node** is the recommended option — roughly 700 GB of disk, several days to sync from scratch, complete transaction verification, and full sovereignty. It also supports the widest range of other Umbrel apps and services.

**Pruned node** is valid if disk space is constrained or if you already run a full node elsewhere and want this stack self-contained on a smaller machine. A pruned node discards historical block data after verification, keeping only recent blocks — typically 10–25 GB. LND works correctly with a pruned node for all operations this architecture requires: opening channels, generating invoices, receiving payments. The tradeoff is that some Umbrel apps (Electrs and similar indexers) require a full node and will not work in pruned mode.

### Alby Hub and LND Credentials

On NixOS, nix-bitcoin generates LND credentials at `/etc/nix-bitcoin-secrets/`. The example host configuration mounts these into the Alby Hub container read-only. After both services are running, paste the Alby Hub connection string into BTCPay under Server Settings > Lightning.

### Hardware

For Path A, the Umbrel hardware does the heavy lifting. A machine with a 1 TB SSD (2 TB recommended for a full node with room to grow), 4–8 GB RAM, and wired ethernet is comfortable. The VPS running the token service can be minimal — a Hetzner CX22 (2 vCPU, 4 GB RAM) is more than sufficient.

For Path B on a dedicated server, a Hetzner CX32 (4 vCPU, 8 GB RAM) with an attached 1 TB volume covers the full stack.

## Choosing a Deployment Path

Both paths share the same architecture, the same BTCPay configuration, the same PodServer setup, and the same token service code. They differ in how the infrastructure is assembled and managed.

**Path A: Umbrel** is the right choice if you want to get started quickly, already have an Umbrel running, or want to prove the concept before committing to a dedicated server. Most of the infrastructure is one-click app store installs. The token service runs as a Podman container on a small VPS connected to your Umbrel via Tailscale.

**Path B: NixOS** is the right choice if you want a fully declarative, auditable system where every piece of infrastructure is described in version-controlled configuration, or if you are already running NixOS infrastructure. It uses nix-bitcoin for BTCPay and LND, a custom NixOS module for the token service, and produces the same Podman-compatible container image used in Path A from the same Nix derivation.

Neither path is a stepping stone to the other — both are legitimate long-term choices. A podcaster running a healthy Umbrel with active Lightning channels has no compelling reason to migrate to NixOS unless that operational model is what they want.

## Path A: Umbrel Deployment

### Architecture

The Umbrel deployment splits across two machines:

**Your Umbrel** (home lab, office, or wherever it lives) runs Bitcoin Core, LND, Alby Hub, BTCPay Server, and PodServer — all installed from the Umbrel app store.

**A small VPS** (Hetzner CX22 or equivalent) runs the token service as a Podman container, nginx with Let's Encrypt TLS, and Tailscale configured as an exit node.

The two machines communicate exclusively over Tailscale. The VPS is the only machine with a public IP. Your Umbrel's home IP is never exposed to the internet — all inbound traffic routes through the VPS, and configuring the VPS as Tailscale exit node means outbound traffic from your Umbrel also routes through it. This keeps your home IP private and gives your Lightning node a stable public address for peer connections.

### VPS Setup

Provision a Hetzner CX22 or equivalent running Ubuntu 24.04. Install Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-exit-node
```

Approve the exit node in the Tailscale admin console. Install Podman and nginx:

```bash
sudo apt install podman nginx certbot python3-certbot-nginx
```

Point a DNS A record at the VPS public IP before requesting a certificate:

```bash
sudo certbot --nginx -d members.yourpodcast.com
```

Add proxy locations to your nginx config inside the server block Certbot created:

```nginx
location /rss/           { proxy_pass http://127.0.0.1:8765; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
location /webhook/btcpay { proxy_pass http://127.0.0.1:8765; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
location /api/feed-url   { proxy_pass http://127.0.0.1:8765; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
location /recover        { proxy_pass http://127.0.0.1:8765; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
location /health         { proxy_pass http://127.0.0.1:8765; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
location /metrics        { proxy_pass http://127.0.0.1:8765; proxy_set_header Host $host; proxy_set_header X-Real-IP $remote_addr; }
# /admin/ is intentionally not proxied — localhost only
```

If you want your Bitcoin and Lightning node to be reachable by peers — which supports the broader network, though it is not required for the membership system to function — add a stream proxy block (outside the http block) and open the ports. The pattern for this with Tailscale and nginx is documented in detail at [beanbag.technicalissues.us/proxying-bitcoin-core-lnd-with-tailscale-nginx](https://beanbag.technicalissues.us/proxying-bitcoin-core-lnd-with-tailscale-nginx/).

### Tailscale: Connecting Umbrel to the VPS

Tailscale is available directly in the Umbrel app store — install it there. Once installed, connect it to your Tailscale account and configure the VPS as the exit node in the Umbrel Tailscale settings. Your Umbrel's home IP will then be routed through the VPS.

Note the Umbrel's Tailscale IP from the Tailscale admin console — you will need it for the `PODSERVER_FEED_URL` configuration and for the nginx stream proxy if you set that up.

### Umbrel App Installation Order

Install from the Umbrel app store in this sequence — each step depends on the previous one being complete:

1. **Bitcoin Node** — installs Bitcoin Core. Wait for the blockchain to fully sync before continuing. This takes days on a first install and requires significant disk space (700 GB for a full node; around 10–25 GB for pruned).
2. **Lightning Node** — installs LND. Requires Bitcoin Core to be fully synced.
3. **Alby Hub** — installs Alby Hub. Connect it to your LND instance using the details shown in the Lightning Node app.
4. **BTCPay Server** — installs BTCPay. During initial setup, connect it to Alby Hub using the connection string Alby Hub provides.
5. **PodServer** — install from within the BTCPay admin interface under Plugins, not from the Umbrel app store.

### Token Service: Podman Container on VPS

Clone the repository to your VPS:

```bash
git clone https://github.com/genebean/podcast-members-feed.git
cd podcast-members-feed/podman
cp .env.example .env
```

Edit `.env` and fill in all values. The `PODSERVER_FEED_URL` uses the Umbrel's Tailscale IP:

```
PODSERVER_FEED_URL=http://<umbrel-tailscale-ip>/podserver/feed/<feed-id>.xml
```

Pull the image and start:

```bash
podman pull ghcr.io/genebean/podcast-members-feed:latest
podman compose up -d
```

Verify:

```bash
curl -s http://127.0.0.1:8765/health
# {"status":"ok"}
```

## Path B: NixOS Deployment

### nix-bitcoin

[nix-bitcoin](https://github.com/fort-nix/nix-bitcoin) is a collection of NixOS modules for Bitcoin and Lightning infrastructure with a strong emphasis on security. It handles BTCPay Server, LND, nbxplorer, PostgreSQL, and their interconnections — you do not write service definitions for these from scratch.

Add inputs to your flake. Your nixpkgs must follow nix-bitcoin's pinned versions — overriding with your own nixpkgs risks subtle breakage with software nix-bitcoin has not tested against:

```nix
inputs = {
  podcast-members-feed.url = "github:genebean/podcast-members-feed";
  # Follow nix-bitcoin's nixpkgs through the podcast-members-feed flake
  nixpkgs.follows          = "podcast-members-feed/nixpkgs";
  nixpkgs-unstable.follows = "podcast-members-feed/nixpkgs-unstable";
};
```

After cloning the repository locally, generate the lock file before your first build:

```bash
nix flake update
git add flake.lock
git commit -m "Add flake.lock"
```

Enable Bitcoin Core, LND, and BTCPay:

```nix
nix-bitcoin.generateSecrets = true;
nix-bitcoin.operator = {
  enable = true;
  name   = "youruser";
};

services.bitcoind.enable    = true;
services.lnd.enable         = true;
services.btcpayserver = {
  enable           = true;
  lightningBackend = "lnd";
};
```

For a pruned node:

```nix
services.bitcoind.extraConfig = ''
  prune=10000
'';
```

### Alby Hub on NixOS

Alby Hub is not in nixpkgs. Run it as a Podman container alongside nix-bitcoin's LND. Set the container backend explicitly:

```nix
virtualisation.oci-containers.backend = "podman";

virtualisation.oci-containers.containers.alby-hub = {
  image  = "ghcr.io/getalbyhub/albyhub:latest";
  ports  = [ "127.0.0.1:8080:8080" ];
  volumes = [
    "/var/lib/alby-hub:/data"
    "/etc/nix-bitcoin-secrets/lnd-cert:/lnd/tls.cert:ro"
    "/etc/nix-bitcoin-secrets/lnd-admin-macaroon:/lnd/admin.macaroon:ro"
  ];
  environment = {
    LND_ADDRESS       = "127.0.0.1:10009";
    LND_CERT_FILE     = "/lnd/tls.cert";
    LND_MACAROON_FILE = "/lnd/admin.macaroon";
  };
};
```

After deploying, configure BTCPay to connect to Alby Hub: Server Settings > Lightning > paste the connection string from the Alby Hub interface.

### Token Service Module

The NixOS module is at `modules/services/podcast-token-service.nix` in the repository. Import it and configure:

```nix
imports = [ podcast-members-feed.nixosModules.podcast-token-service ];

services.podcastTokenService = {
  enable          = true;
  package         = pkgs.podcast-token-service;
  environmentFile = config.sops.secrets."podcast-token-service-env".path;
};
```

The module installs a hardened systemd service and a weekly cleanup timer. Secrets are managed with sops-nix or agenix — the `environmentFile` points at the decrypted path at runtime.

See `nixos-configurations/example-host/configuration.nix` in the repository for a complete working host configuration including nix-bitcoin, Alby Hub, nginx, TLS, Tailscale, and sops-nix.

### TLS with nginx and ACME

```nix
security.acme = {
  acceptTerms    = true;
  defaults.email = "you@yourpodcast.com";
};

services.nginx = {
  enable = true;

  # Module-level recommended settings apply globally — no need for
  # manual proxy_set_header in individual location blocks.
  recommendedProxySettings = true;
  recommendedTlsSettings   = true;
  recommendedGzipSettings  = true;
  recommendedOptimisation  = true;

  virtualHosts."members.yourpodcast.com" = {
    enableACME = true;
    forceSSL   = true;

    locations = let
      svc = "http://127.0.0.1:${toString config.services.podcastTokenService.port}";
    in {
      "/rss/".proxyPass           = svc;
      "/webhook/btcpay".proxyPass = svc;
      "/api/feed-url".proxyPass   = svc;
      "/recover".proxyPass        = svc;
      "/health".proxyPass         = svc;
      # /metrics requires bearer token auth — enforced by the service
      "/metrics".proxyPass        = svc;
      # /admin/ is NOT proxied — localhost access only
    };
  };
};
```

For Bitcoin and Lightning peer connectivity, add a `streamConfig` block to the nginx config forwarding ports 8333 and 9735. The pattern and rationale is covered in [beanbag.technicalissues.us/proxying-bitcoin-core-lnd-with-tailscale-nginx](https://beanbag.technicalissues.us/proxying-bitcoin-core-lnd-with-tailscale-nginx/). As with Path A, this is ecosystem-supporting but not required for the membership system.

### Container Image from Nix

The Nix derivation also produces a Podman-compatible OCI image. This is informational for developers who want to verify both paths run identical code, or who want to build locally before pushing:

```bash
nix build .#dockerImage
podman load < result
```

The GitHub Actions workflow in the repository builds this image and pushes it to `ghcr.io/genebean/podcast-members-feed` automatically on pushes to main and on version tags.

## BTCPay Configuration

This section applies to both deployment paths.

### Subscription Plans

Create a dedicated store in BTCPay for your members feed to keep subscription accounting separate from value-for-value activity on your public feed.

Navigate to your store and create a Subscription Offering. Add two plans:

**Monthly membership** — billing interval monthly. Price in satoshis or a fiat currency with invoice-time conversion.

**Annual membership** — same offering, annual interval. A 15–20% discount compared to twelve monthly payments is a conventional starting point and meaningfully reduces renewal friction.

For both plans configure:
- A grace period of 3–5 days so a renewal reminder landing in spam does not immediately cut off a subscriber
- Email notifications: a reminder 5 days before expiry and a confirmation on successful renewal
- A custom metadata field on the checkout page labelled "Nostr npub (optional)" — this passes through to the webhook payload and the token service uses it for Nostr DM delivery and NIP-98 self-service recovery

BTCPay sends renewal reminders automatically once SMTP is configured in Server Settings > Email.

### Webhook Configuration

In Store Settings > Webhooks, add a webhook:

**URL:** `https://members.yourpodcast.com/webhook/btcpay`

**Events:** `SubscriptionCreated`, `SubscriptionRenewed`, `SubscriptionExpired`, `SubscriptionSuspended`

**Secret:** `openssl rand -hex 32` — store this value as `BTCPAY_WEBHOOK_SECRET` in the token service configuration.

Enable **Automatic redelivery** so BTCPay retries failed deliveries if the token service is briefly unavailable.

## PodServer Setup

Install PodServer from the BTCPay Plugins menu. Configure audio file storage — a local directory or an S3-compatible bucket both work. [Backblaze B2](https://www.backblaze.com/cloud-storage) is a cost-effective S3-compatible option worth considering for audio hosting.

Create a new podcast in PodServer for your members feed. Keep it completely separate from your public feed — different title, different episodes, never submitted to any podcast directory.

Add a `<podcast:value>` block to the members feed exactly as you would your public feed. Members who listen in Podcasting 2.0 apps can stream sats and boost episodes on the private feed. Access is what they are paying for; their listening behaviour remains their own.

Note the internal feed URL PodServer generates. On Path A, use the Umbrel's Tailscale IP in the address. On Path B, this is a localhost address. This URL goes into `PODSERVER_FEED_URL` — subscribers never see it.

## The Token Service

The complete implementation is at `pkgs/podcast-token-service/token_service.py` in the repository.

### Dependencies and Crypto

The service uses FastAPI for HTTP, aiosqlite for the database, and `libsecp256k1` via ctypes for all Nostr cryptography — Schnorr signing for NIP-01 event signatures, Schnorr verification for NIP-98 auth, and raw x-coordinate ECDH for NIP-04 message encryption. Calling libsecp256k1 directly avoids Python wrapper packaging issues and gives precise control over the ECDH output, which NIP-04 requires to be the raw x-coordinate rather than the hashed form some wrappers return. Bech32 for npub/nsec encode and decode is pure Python with no external dependencies. Prometheus metrics are provided by `prometheus-client`, available in nixpkgs.

### Configuration

```bash
BTCPAY_WEBHOOK_SECRET=<openssl rand -hex 32>
PODSERVER_FEED_URL=http://<address>/podserver/feed/<feed-id>.xml
FEED_BASE_URL=https://members.yourpodcast.com
DATABASE_PATH=/var/lib/podcast-token-service/tokens.db
ADMIN_TOKEN=<openssl rand -hex 32>
EXPIRED_AUDIO_URL=https://...  # optional: URL of expiry notification clip
SMTP_HOST=smtp.example.com     # required if not using npub-only subscriptions
SMTP_PORT=587
SMTP_USER=you@yourpodcast.com
SMTP_PASSWORD=<password>
SMTP_FROM=members@yourpodcast.com
NOSTR_PRIVATE_KEY=nsec1...     # dedicated service keypair — not your personal key
```

Generate the Nostr service keypair with `nak keygen`. On startup the service logs its npub so you can verify which key it is using.

### Endpoints

- `POST /webhook/btcpay` — HMAC-verified webhook receiver
- `GET /rss/<token>.xml` — gated feed proxy with expiry episode injection
- `GET /api/feed-url` — NIP-98 authenticated feed URL retrieval
- `GET /recover` — self-service recovery page (NIP-07 browser signing)
- `GET /metrics` — Prometheus metrics (bearer token required)
- `POST /admin/cleanup` — remove old expired tokens (bearer token, localhost nginx)
- `GET /health` — liveness check

## Validating the Token Service

Before committing to the full BTCPay and Lightning setup it is worth validating that the token service container works correctly on its own. The `test-webhook` command in the management CLI handles the full validation flow without needing curl, manual database queries, or a real SMTP server.

### Starting the Container for Testing

You will need a real podcast RSS feed URL to use as the upstream source. This lets you verify that the proxy is returning genuine podcast content rather than test XML. Sample feeds from a wide range of shows can be found at [podcastindex.org](https://podcastindex.org/).

Start the container with a volume mount and explicit `DATABASE_PATH` so the management CLI can reach the database from the host. Without the volume mount the database lives inside the ephemeral container filesystem and is unreachable:

```bash
mkdir -p data

podman run --rm \
  --name podcast-token-service \
  -p 127.0.0.1:8765:8765 \
  -v $(pwd)/data:/var/lib/podcast-token-service \
  -e BTCPAY_WEBHOOK_SECRET=testsecret \
  -e PODSERVER_FEED_URL=https://feeds.npr.org/500005/podcast.xml \
  -e FEED_BASE_URL=http://localhost:8765 \
  -e ADMIN_TOKEN=testtoken \
  -e NOSTR_PRIVATE_KEY=$(openssl rand -hex 32) \
  -e SMTP_HOST=localhost \
  -e DATABASE_PATH=/var/lib/podcast-token-service/tokens.db \
  ghcr.io/genebean/podcast-members-feed:latest
```

`SMTP_HOST=localhost` is intentionally unreachable — email delivery will fail and be logged, but the webhook returns 200 and the token is created correctly. This is expected behaviour. `--name` is required so `podman exec` can address the container by name.

On startup the service logs its Nostr pubkey:

```
INFO:token_service:Token service started — Nostr pubkey: npub1...
```

### Running the Validation

In a second terminal, run the `test-webhook` command. Use a hex pubkey as the test subscriber identity — generate one with `openssl rand -hex 32` or use a real Nostr pubkey:

```bash
FEED_BASE_URL=http://localhost:8765 \
ADMIN_TOKEN=testtoken \
python3 cli/podcast_members_manage.py \
  --db ./data/tokens.db \
  test-webhook \
  --webhook-secret testsecret \
  --npub $(openssl rand -hex 32) \
  --feed-url https://feeds.npr.org/500005/podcast.xml \
  --run-expiry-test
```

A passing run looks like this:

```
Stage 1: Health check
─────────────────────
  ✓ Health endpoint returned ok

Stage 2: Metrics endpoint
─────────────────────────
  ✓ Metrics returned Prometheus data
  ✓ Unauthenticated request correctly rejected (401)

Stage 3: Webhook
────────────────
  ✓ Webhook accepted for subscriber test-1777845664

Stage 4: Token and feed
───────────────────────
  ✓ Token created: ...xF3MAkzPfE
  Feed URL: http://localhost:8765/rss/<token>.xml
  ✓ Feed URL returns valid RSS content
  ✓ Upstream feed is valid RSS

Stage 5: Expiry flow
────────────────────
  ✓ Token expired in database
  ✓ First fetch: 200 with expiry episode injected
  ✓ Second fetch: 402 Payment Required
  ✓ Token restored to active state

────────────────────────────────────────
  Passed: 10  Failed: 0
  All checks passed
```

Once all checks pass the token service is working correctly and you are ready to proceed with the full BTCPay and Lightning setup.

## Nostr Integration

Nostr plays two roles in this architecture. On the server side it is always active — the service has its own keypair and is ready to publish to relays. On the subscriber side it is opt-in: a subscriber who provides their npub during checkout gets additional capabilities.

### Why a Subscriber Would Provide Their Npub

The email-only path works fine. But for a listener who lives in Nostr, providing their npub offers:

**Native delivery.** Their feed URL arrives as an encrypted NIP-04 DM in Damus, Primal, Amethyst, YakiHonne, or whichever client they use — in their messages, not in an email inbox.

**Expiry notification in-client.** When their subscription expires and the expiry episode is served, a DM is sent simultaneously telling them their subscription has lapsed and directing them to renew. No waiting for a reminder email.

**Self-service URL recovery.** If they lose their feed URL, they can retrieve it themselves without contacting you — using NIP-98, described below.

**Passwordless identity.** Their Nostr keypair is their identity. They do not need to provide an email address if they prefer not to.

### NIP-04 Direct Messages

The service uses NIP-04 — kind:4 encrypted DMs using AES-256-CBC with an ECDH shared secret. NIP-04 is used rather than the newer NIP-17 because it is supported across the current client landscape: Damus, Primal, Amethyst (with NIP-17 mode off), and YakiHonne all support NIP-04. NIP-17 offers better metadata privacy but is not yet universally implemented.

### NIP-98: Self-Service Feed URL Recovery

NIP-98 is a standard for HTTP authentication using Nostr events. It powers the `/recover` page and the `/api/feed-url` endpoint.

When a subscriber wants to retrieve their feed URL, they visit `https://members.yourpodcast.com/recover` in a desktop browser with a NIP-07 extension installed (Alby or nos2x are the common choices). The page uses `window.nostr.signEvent()` to create a kind:27235 Nostr event containing the endpoint URL and HTTP method, signed with their private key. It submits this signed event as a base64-encoded Authorization header. The token service verifies the Schnorr signature, checks the event is fresh (within 60 seconds, preventing replay attacks), and returns their feed URL.

The result: a subscriber proves they own the npub associated with their subscription without any password or session — just their key. For an audience that already uses Nostr keys daily, this is the natural model.

**On mobile:** standard iOS and Android browsers do not support extensions, so the NIP-07 signing flow is not available on phones. Mobile users should use the email fallback — reply to the subscription confirmation email to have their URL resent. The recovery page makes this clear.

## Accounting and Reporting

### What BTCPay Provides

BTCPay's built-in reporting covers the essentials: an active/expiring/expired subscriber dashboard filterable by plan, full transaction history exportable to CSV, aggregate revenue views by time period, and email delivery logs for renewal reminders. For most podcast membership programs this is sufficient.

### Management CLI

The `podcast-members-manage` command is installed alongside the service and wraps common queries:

```bash
# Show all active subscribers
podcast-members-manage subscribers --active

# Find subscribers expiring in the next 7 days
podcast-members-manage subscribers --expiring-days 7

# Find subscribers who signed up but never opened their feed
podcast-members-manage subscribers --never-accessed

# Look up a feed URL by email or npub
podcast-members-manage feed-url --email subscriber@example.com
podcast-members-manage feed-url --npub npub1...

# Summary counts
podcast-members-manage stats

# Run cleanup via the API
podcast-members-manage cleanup
```

On Path A with Podman:

```bash
podman exec podcast-token-service \
  podcast-members-manage \
  --db /var/lib/podcast-token-service/tokens.db \
  stats
```

## Operations

### Resending a Lost Feed URL

Look up the subscriber in BTCPay to get their subscriber ID, then:

```bash
podcast-members-manage feed-url --email subscriber@example.com
```

Send the URL to them manually. Subscribers with a Nostr npub can also self-serve via `/recover`.

### Manually Revoking Access

```bash
podcast-members-manage revoke <btcpay-subscriber-id>
```

Then cancel the subscription in BTCPay to prevent future renewals.

### Issuing a Refund

Lightning payments are final. For a refund: ask the subscriber for a Lightning address or invoice, send the refund from your Lightning wallet, revoke their token, and cancel in BTCPay. Document your refund policy on your members page before launch.

### Recovering from a Missed Webhook

BTCPay retries failed webhook deliveries automatically if Automatic Redelivery is enabled. For events outside the retry window, find the failed delivery in Store Settings > Webhooks > Delivery History and click Redeliver.

### Database Backup

The SQLite database is a single file and the source of truth for subscriber access. Back it up daily. On Path B, include it in your sops-encrypted backup configuration. On Path A:

```bash
podman exec podcast-token-service sqlite3 \
  /var/lib/podcast-token-service/tokens.db \
  ".backup /tmp/tokens-backup.db"
# Copy /tmp/tokens-backup.db off-site
```

### Token Cleanup

On Path B, the NixOS module installs a weekly systemd timer that calls `/admin/cleanup` automatically. On Path A, run it via cron:

```bash
0 3 * * 0 podman exec podcast-token-service \
  curl -sf -X POST \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  http://127.0.0.1:8765/admin/cleanup
```

### Monitoring and Alerting

The service exposes Prometheus metrics at `/metrics` with bearer token authentication. Since scrapes may come from another host (your monitoring machine), the endpoint is reachable on all interfaces — authentication is enforced by the service rather than by restricting access at the network level.

Example Prometheus scrape configuration:

```yaml
- job_name: podcast_token_service
  bearer_token: YOUR_ADMIN_TOKEN
  static_configs:
    - targets: ["members.yourpodcast.com"]
  scheme: https
```

AlertManager rules are provided in `alerts/podcast-members-feed.rules.yml` in the repository. Include them in your Prometheus configuration:

```yaml
rule_files:
  - /etc/prometheus/rules/podcast-members-feed.rules.yml
```

On NixOS:

```nix
services.prometheus.ruleFiles = [
  ./alerts/podcast-members-feed.rules.yml
];
```

The rules cover:

- **Critical:** email delivery failing (new subscribers not receiving their URLs)
- **Critical:** webhook signature errors sustained (misconfigured secret or probing)
- **Critical:** no webhooks received in 7 days (BTCPay stopped firing)
- **Critical:** token service unreachable
- **Warning:** upstream PodServer feed unreachable (subscribers getting 502)
- **Warning:** active token count dropped more than 20% in an hour
- **Warning:** Nostr DM delivery failing on all relays (non-critical — email unaffected)

Point an uptime monitor at `https://members.yourpodcast.com/health` for basic liveness alerting outside of Prometheus.

### Changing Subscription Plan Pricing

Update prices in BTCPay under the Subscription Offering. Existing active subscribers are unaffected — their tokens remain valid until natural expiry. New subscribers pay the updated price.

## Limitations and Honest Tradeoffs

**No automatic recurring charges.** Bitcoin does not support automatic debits. Subscribers must actively renew. BTCPay's reminder emails handle most of this, but annual plans reduce the friction significantly — make the annual option genuinely attractive.

**RSS caching.** Podcast apps cache feeds aggressively. A new episode may not appear for 15–60 minutes after publishing. This is normal RSS behaviour.

**Revocation delay.** When a token is revoked, a subscriber's app does not know until its next poll. Previously downloaded episodes remain playable on the device. This is appropriate — subscribers who paid for access should keep what they downloaded while subscribed.

**Token sharing.** A subscriber could share their feed URL. Use `podcast-members-manage subscribers --active` to spot unusual `last_used_at` patterns and revoke suspicious tokens. Your subscribers support your work in Bitcoin — token sharing is rarely a meaningful problem in practice.

**Single point of failure.** The token service sits on the critical path for feed access. Systemd's `Restart=on-failure` and Podman's `restart: unless-stopped` cover most failure modes. Brief downtime is invisible to subscribers since podcast apps retry on the next polling interval.

**Lightning is final.** No chargebacks. Document your refund policy before launch.

---

*This article was written with assistance from Claude (Anthropic) and extensive human review, testing, and editorial direction by the author.*
