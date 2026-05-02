# Lightning-Gated Podcast Members Feeds with BTCPay Server

## Introduction

You make a Bitcoin podcast. Your audience already streams sats while they listen and boosts episodes they love. Now you want to offer something more: a members-only feed with bonus content, available only to paying supporters, compatible with the apps your listeners already use — Fountain, Castamatic, and any other Podcasting 2.0 player.

The catch is that you want to do this without Patreon, without Stripe, and without handing a platform a cut of every payment. You want Bitcoin-native subscriptions that go directly to you, managed on infrastructure you control.

This article describes a practical, self-hosted architecture for exactly that. It is written for the podcaster who wants to understand how the pieces fit together, and for the developer — perhaps a technically-minded co-host — who will build and maintain it. The complete reference implementation, including all source code and NixOS configuration, lives at [github.com/genebean/podcast-members-feed](https://github.com/genebean/podcast-members-feed). Two deployment paths are covered: one built on Umbrel that most people can follow without prior server administration experience, and one built on NixOS for a fully declarative, production-grade system.

One note before we begin: if you and your listeners are already streaming sats and boosting, value-for-value is already working for your public feed. This architecture sits alongside that — it does not replace it. Members get a private feed with bonus content; everyone else keeps listening and paying however they choose.

-----

## Subscriber Experience

Before getting into how this works technically, it helps to understand what you are building from your listener’s perspective. This is also the story you will tell your audience when you launch.

A listener visits your members page and picks a plan — monthly or annual. They pay a Lightning invoice with their wallet of choice. Payment settles in seconds. Within a minute they receive an email containing their private podcast feed URL. They open Fountain, Castamatic, or whichever podcast app they use, find the option to add a podcast by URL, and paste the link. The members feed appears in their library alongside their other shows. New bonus episodes appear automatically when you publish them, exactly like any other podcast. There is no app to install, no account to create, no password to remember.

When their subscription is approaching expiry, they receive a reminder email. They pay again and nothing changes in their podcast app — the same URL keeps working, silently extended in the background.

**If a subscriber provides their Nostr npub during checkout,** the experience gains two meaningful additions. First, their feed URL arrives as an encrypted direct message in their Nostr client — Damus, Primal, Amethyst, YakiHonne, or whichever they use — in addition to email. For a Nostr-native listener this feels native rather than bureaucratic. Second, if they ever lose their feed URL they can retrieve it themselves without emailing you. From any Nostr client they send a cryptographically signed request proving they own the npub associated with their subscription, and the system returns their URL immediately. No support ticket, no waiting. This is NIP-98 in practice, explained in detail in the Nostr section below.

If a subscription lapses without renewal, the podcast app will eventually receive an error when it tries to refresh the feed and will stop showing new episodes. There is no in-app notification — this is a limitation of RSS rather than this architecture. Clear renewal reminder emails are therefore important, and BTCPay handles sending them automatically.

-----

## How It Works

The subscriber experience above is produced by three pieces working together.

When a listener pays, BTCPay Server receives and settles the Lightning invoice, records the subscription, and immediately fires a webhook — an automated HTTP notification — to a small service running on your server. That service, which we call the token service, generates a unique random string, stores it in a database alongside the subscriber’s email address, expiry date, and optionally their Nostr pubkey, and constructs a private RSS feed URL containing that token. It then sends the URL to the subscriber by email, and as a Nostr DM if they provided their npub.

When a podcast app polls the feed URL, the token service checks the token against the database, verifies it has not expired or been revoked, and if valid fetches the actual RSS feed from PodServer and returns it to the app. PodServer’s real feed URL is never exposed to subscribers.

When BTCPay fires a renewal webhook, the token service extends the expiry on the subscriber’s existing token rather than issuing a new URL — the subscriber’s podcast app never needs updating. When a subscription expires or is suspended, the token is revoked and subsequent feed requests receive a 402 Payment Required response.

The Bitcoin and Lightning infrastructure underneath BTCPay handles payment settlement. BTCPay connects to a Lightning node — managed through Alby Hub — to generate invoices and receive payments. That Lightning node needs a view of the Bitcoin blockchain, which means running a Bitcoin node locally. The infrastructure considerations section covers the options.

-----

## The Stack

**BTCPay Server** handles everything money-related: Lightning invoices, subscription plans, renewal reminders, and webhooks. It is self-hosted, open-source, and takes no fees. Its native subscription system handles monthly and annual billing, sends renewal reminders automatically, and provides a subscriber management dashboard.

**PodServer** is a BTCPay Server plugin that adds podcast hosting to your BTCPay instance. It generates a valid RSS feed with Podcasting 2.0 tags including value splits, and manages your audio files. You will use it to host the members-only feed separately from your public feed.

**Alby Hub** is a self-hosted Lightning node management layer that sits in front of LND. It handles channel management, liquidity, and the connection interface between BTCPay and your Lightning node. BTCPay connects to Alby Hub rather than to LND directly, which makes day-to-day Lightning operations significantly more approachable.

**The token service** is a small Python application — the glue between BTCPay and your private RSS feed. The complete source is in the repository at `pkgs/podcast-token-service/token_service.py`. It listens for BTCPay webhooks, issues and revokes tokenized feed URLs, proxies the private feed to authenticated subscribers, and delivers feed URLs via email and Nostr DM. This is the only custom code in the stack.

-----

## Infrastructure Considerations

### Bitcoin Node

Both deployment paths require a local Bitcoin node. LND — the Lightning implementation used here — needs a Bitcoin chain backend to watch for on-chain transactions, and Umbrel’s LND is wired to its local Bitcoin Core instance by design.

**Full node** is the recommended option. It requires approximately 700 GB of disk space, several days to sync from scratch, and gives you complete verification of every transaction. It is the most sovereign and reliable path.

**Pruned node** is a valid alternative if disk space is a constraint. A pruned node discards historical block data after verification, keeping only the most recent blocks — typically 10–25 GB depending on the prune target you set. LND works correctly with a pruned node for all operations this architecture requires: opening and closing channels, generating invoices, and receiving payments. The tradeoff is that some other Umbrel apps — Electrs and similar indexers — will not work with a pruned node. If the Bitcoin node exists specifically to support this membership system and your Lightning node, pruned is fine. If you want to run a broader set of Umbrel apps, use a full node.

If you already run a Bitcoin node and LND elsewhere — on a home server, a separate VPS, or another Umbrel — you can point BTCPay at your existing Alby Hub instance rather than setting up a new one.

### Alby Hub

Alby Hub provides a management interface over LND that handles channel opening, liquidity monitoring, and the connection string BTCPay uses to interact with Lightning. On Umbrel it is a one-click install from the app store. On NixOS it runs as a container alongside nix-bitcoin’s LND service, connecting to it via the credentials nix-bitcoin generates.

### Hardware

For Path A, the Umbrel hardware handles the heavy lifting. A machine with a 1 TB SSD (2 TB recommended for a full node with room to grow), 4–8 GB RAM, and a wired ethernet connection is a solid Umbrel host. The VPS running the token service can be minimal — a Hetzner CX22 (2 vCPU, 4 GB RAM) is more than sufficient.

For Path B on a dedicated server, a Hetzner CX32 (4 vCPU, 8 GB RAM) with an attached 1 TB volume covers the full stack comfortably.

-----

## Choosing a Deployment Path

Both paths share the same architecture, the same BTCPay configuration, the same PodServer setup, and the same token service code. They differ in how the infrastructure is assembled and managed.

**Path A: Umbrel** is the right choice if you want to get started quickly, already have an Umbrel running, or want to validate the concept before committing to a dedicated server. Most of the infrastructure is one-click installs. The token service runs as a Docker container on a small VPS connected to your Umbrel via Tailscale.

**Path B: NixOS** is the right choice if you want a fully declarative, auditable system where every piece of infrastructure is described in version-controlled configuration, or if you already run NixOS. It uses nix-bitcoin for BTCPay and LND, a custom NixOS module for the token service, and produces the same Docker container image used in Path A from the same Nix derivation. Choose this path when you are ready to treat the membership system as long-term production infrastructure.

Neither path is a stepping stone to the other — both are legitimate long-term choices. A podcaster running a healthy Umbrel with active Lightning channels has no compelling reason to migrate to NixOS unless they want the operational model NixOS provides.

-----

## Path A: Umbrel Deployment

### Architecture

The Umbrel deployment splits across two machines:

**Your Umbrel** (home lab, office, or wherever it lives) runs Bitcoin Core, LND, Alby Hub, BTCPay Server, and PodServer — all installed from the Umbrel app store.

**A small VPS** (Hetzner CX22 or equivalent) runs the token service as a Docker container, nginx with Let’s Encrypt TLS, and Tailscale configured as an exit node.

The two machines communicate exclusively over Tailscale. The VPS is the only machine with a public IP. Your Umbrel’s home IP is never exposed to the internet — all inbound traffic routes through the VPS, and Umbrel uses the VPS as its Tailscale exit node so outbound traffic does too. This keeps your home IP private and gives the Lightning node a stable public address for peer connections.

### VPS Setup

Provision a Hetzner CX22 or equivalent running Ubuntu 24.04. Install Tailscale:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --advertise-exit-node
```

Approve the exit node in the Tailscale admin console after running this command. Then install Docker and nginx:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
sudo apt install nginx certbot python3-certbot-nginx
```

Point a DNS A record at the VPS public IP before requesting a certificate. Replace `members.yourpodcast.com` throughout with your actual domain:

```bash
sudo certbot --nginx -d members.yourpodcast.com
```

Add proxy locations for the token service to your nginx config. Certbot will have created a server block — add these location blocks inside it:

```nginx
server {
    server_name members.yourpodcast.com;

    location /rss/ {
        proxy_pass       http://127.0.0.1:8765;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /webhook/btcpay {
        proxy_pass       http://127.0.0.1:8765;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /api/feed-url {
        proxy_pass       http://127.0.0.1:8765;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    location /health {
        proxy_pass       http://127.0.0.1:8765;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
    # /admin/ is intentionally not proxied — localhost access only

    # TLS configuration managed by Certbot
}
```

For Bitcoin and Lightning peer connections, nginx can also forward TCP traffic on ports 8333 and 9735 to your Umbrel over Tailscale using the stream proxy module. This is the same pattern described in [Proxying Bitcoin Core and LND with Tailscale and Nginx](https://beanbag.technicalissues.us/proxying-bitcoin-core-lnd-with-tailscale-nginx/). Add a stream block to your nginx config (outside the http block):

```nginx
stream {
    server {
        listen 0.0.0.0:8333;
        listen [::]:8333;
        proxy_pass <umbrel-tailscale-ip>:8333;
    }
    server {
        listen 0.0.0.0:9735;
        listen [::]:9735;
        proxy_pass <umbrel-tailscale-ip>:9735;
    }
}
```

Open those ports in the VPS firewall:

```bash
sudo ufw allow 8333/tcp
sudo ufw allow 9735/tcp
```

### Tailscale: Connecting Umbrel to the VPS

On your Umbrel host, install Tailscale at the OS level:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
sudo tailscale up --exit-node=<vps-tailscale-ip> --exit-node-allow-lan-access
```

The `--exit-node-allow-lan-access` flag preserves access to your local network while routing all other traffic — including outbound Lightning connections — through the VPS. Your Umbrel’s home IP remains private.

Once both machines are on the same Tailscale network, note the Umbrel’s Tailscale IP. You will use it in the token service configuration for `PODSERVER_FEED_URL` and in the nginx stream proxy for Bitcoin and LND peer forwarding.

### Umbrel App Installation Order

Install apps from the Umbrel app store in this order. Each step depends on the previous one being complete:

1. **Bitcoin Node** — installs Bitcoin Core. Wait for the blockchain to fully sync before proceeding. This takes days on a first install.
1. **Lightning Node** — installs LND. Requires Bitcoin Core to be synced.
1. **Alby Hub** — installs Alby Hub. Connect it to your LND instance using the connection details shown in the Lightning Node app.
1. **BTCPay Server** — installs BTCPay. During setup, connect it to Alby Hub using the connection string Alby Hub provides.
1. **PodServer** — install from within the BTCPay admin interface under Plugins, not the Umbrel app store.

### Token Service: Docker Container on VPS

Clone or copy the repository to your VPS:

```bash
git clone https://github.com/genebean/podcast-members-feed.git
cd podcast-members-feed/docker
cp .env.example .env
```

Edit `.env` and fill in all values. The `PODSERVER_FEED_URL` should use the Umbrel’s Tailscale IP:

```
PODSERVER_FEED_URL=http://<umbrel-tailscale-ip>/podserver/feed/<feed-id>.xml
```

Pull the image and start the service:

```bash
docker pull ghcr.io/genebean/podcast-members-feed:latest
docker compose up -d
```

Verify it is running:

```bash
curl -s http://127.0.0.1:8765/health
# {"status":"ok"}
```

-----

## Path B: NixOS Deployment

### nix-bitcoin

[nix-bitcoin](https://github.com/fort-nix/nix-bitcoin) is a collection of NixOS modules for Bitcoin and Lightning infrastructure with a strong emphasis on security. It handles BTCPay Server, LND, nbxplorer, PostgreSQL, and their interconnections in a well-audited, actively maintained set of modules — you do not need to write service definitions for any of them from scratch.

Add nix-bitcoin as a flake input. Note that your nixpkgs should follow nix-bitcoin’s — it pins specific versions it has tested against and overriding with your own nixpkgs risks subtle breakage:

```nix
inputs = {
  nix-bitcoin.url = "github:fort-nix/nix-bitcoin/release";
  # Follow nix-bitcoin's nixpkgs — do not override with your own
  nixpkgs.follows          = "nix-bitcoin/nixpkgs";
  nixpkgs-unstable.follows = "nix-bitcoin/nixpkgs-unstable";
};
```

Alternatively, add the podcast-members-feed repo as a flake input and get nix-bitcoin transitively:

```nix
inputs = {
  podcast-members-feed.url = "github:genebean/podcast-members-feed";
  # Follow through to get consistent nixpkgs
  nixpkgs.follows          = "podcast-members-feed/nixpkgs";
  nixpkgs-unstable.follows = "podcast-members-feed/nixpkgs-unstable";
};
```

Enable Bitcoin Core, LND, and BTCPay Server via nix-bitcoin:

```nix
nix-bitcoin.generateSecrets = true;
nix-bitcoin.operator = {
  enable = true;
  name   = "youruser";  # gives this user access to bitcoin-cli, lncli, etc.
};

services.bitcoind.enable    = true;
services.lnd.enable         = true;
services.btcpayserver = {
  enable           = true;
  lightningBackend = "lnd";
};
```

For a pruned node, add to bitcoind’s extraConfig:

```nix
services.bitcoind.extraConfig = ''
  prune=10000
'';
```

nix-bitcoin wires LND to bitcoind automatically and generates all required credentials at `/etc/nix-bitcoin-secrets/`.

### Alby Hub on NixOS

Alby Hub is not packaged in nixpkgs. Run it as a container alongside nix-bitcoin’s LND:

```nix
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

After both services are running, configure BTCPay to connect to Alby Hub in the BTCPay admin interface under Server Settings > Lightning.

### Token Service NixOS Module

The NixOS module is at `modules/services/podcast-token-service.nix` in the repository. If you added the repo as a flake input:

```nix
imports = [ podcast-members-feed.nixosModules.podcast-token-service ];

services.podcastTokenService = {
  enable          = true;
  package         = pkgs.podcast-token-service;
  environmentFile = config.sops.secrets."podcast-token-service-env".path;
};
```

The module creates a hardened systemd service with `DynamicUser`, strict filesystem access, and a weekly cleanup timer. It follows nix-bitcoin’s service hardening conventions.

Secrets are managed with sops-nix or agenix. The `environmentFile` points at the decrypted path at runtime. Never commit credentials to your flake repository. See the example host configuration at `nixos-configurations/example-host/configuration.nix` in the repository for a complete working setup.

### TLS with nginx and ACME

```nix
security.acme = {
  acceptTerms    = true;
  defaults.email = "you@yourpodcast.com";
};

services.nginx = {
  enable = true;

  # These module-level options apply globally and handle proxy headers,
  # TLS best practices, gzip, and performance tuning declaratively.
  recommendedProxySettings = true;
  recommendedTlsSettings   = true;
  recommendedGzipSettings  = true;
  recommendedOptimisation  = true;

  # Stream proxy for Bitcoin and Lightning peer connections.
  # Forwards TCP on 8333/9735 to local services.
  # See: https://beanbag.technicalissues.us/proxying-bitcoin-core-lnd-with-tailscale-nginx/
  streamConfig = let
    # On a dedicated server bitcoind and lnd are local.
    # If proxying for a remote Umbrel over Tailscale, use its Tailscale IP.
    backendHost = "127.0.0.1";
  in ''
    server {
      listen 0.0.0.0:8333;
      listen [::]:8333;
      proxy_pass ${backendHost}:8333;
    }
    server {
      listen 0.0.0.0:9735;
      listen [::]:9735;
      proxy_pass ${backendHost}:9735;
    }
  '';

  virtualHosts."members.yourpodcast.com" = {
    enableACME = true;
    forceSSL   = true;

    locations."/rss/"          = { proxyPass = "http://127.0.0.1:${toString config.services.podcastTokenService.port}"; };
    locations."/webhook/btcpay" = { proxyPass = "http://127.0.0.1:${toString config.services.podcastTokenService.port}"; };
    locations."/api/feed-url"  = { proxyPass = "http://127.0.0.1:${toString config.services.podcastTokenService.port}"; };
    locations."/health"        = { proxyPass = "http://127.0.0.1:${toString config.services.podcastTokenService.port}"; };

    # /admin/ is intentionally not proxied — localhost access only
  };
};

networking.firewall.allowedTCPPorts = [ 80 443 8333 9735 ];
```

With `recommendedProxySettings = true` set at the nginx level, the individual location blocks do not need manual `proxy_set_header` directives — the recommended headers are applied automatically.

### Initialising the Flake

After cloning the repository, generate the lock file before building:

```bash
nix flake update
```

Commit `flake.lock` to your repository. This pins all inputs to known-good versions and makes builds reproducible.

### Building and Loading the Docker Image from Nix

The same Nix derivation that produces the NixOS service also produces the Docker image used in Path A:

```bash
nix build github:genebean/podcast-members-feed#dockerImage
docker load < result
```

This ensures both deployment paths run identical code built from the same source.

-----

## BTCPay Configuration

This section applies to both deployment paths.

### Subscription Plans

Create a dedicated store in BTCPay for your members feed to keep subscription accounting separate from any value-for-value activity on your public feed.

Navigate to your store and create a Subscription Offering. Add two plans:

**Monthly membership** — billing interval monthly. Price in satoshis or a fiat currency with invoice-time conversion.

**Annual membership** — same offering, annual interval. A 15–20% discount compared to twelve months of monthly billing is a conventional starting point.

For both plans configure:

- A grace period of 3–5 days so a renewal reminder landing in spam does not immediately cut off a subscriber
- Email notifications: a reminder 5 days before expiry and a confirmation on successful renewal
- A custom metadata field on the checkout page labelled “Nostr npub (optional)” — this passes through to the webhook payload and the token service uses it to deliver the Nostr DM

BTCPay sends renewal reminder emails automatically once you configure an SMTP server in Server Settings > Email.

### Webhook Configuration

In Store Settings > Webhooks, add a new webhook:

**URL:** `https://members.yourpodcast.com/webhook/btcpay`

**Events to enable:**

- `SubscriptionCreated`
- `SubscriptionRenewed`
- `SubscriptionExpired`
- `SubscriptionSuspended`

**Secret:** generate with `openssl rand -hex 32`. This value goes into `BTCPAY_WEBHOOK_SECRET` in the token service configuration. BTCPay signs every webhook delivery with this secret and the token service verifies the signature before processing any event.

Enable **Automatic redelivery**. This causes BTCPay to retry failed webhook deliveries, protecting against missed subscription events if the token service is briefly unavailable.

-----

## PodServer Setup

Install PodServer from the BTCPay Plugins menu. Configure a storage location for your audio files — a local directory or S3-compatible bucket both work.

Create a new podcast in PodServer for your members feed. Keep it completely separate from your public feed — different title, different episodes. Do not submit this feed URL to any podcast directory.

Add a `<podcast:value>` block to the members feed exactly as you would your public feed. Members who listen in Podcasting 2.0 apps can stream sats and boost episodes on the private feed. They are paying for access to the content; what they do while listening remains their own choice.

Note the internal feed URL PodServer generates — it will look something like:

```
https://<btcpay-address>/podserver/feed/<feed-id>.xml
```

This is the upstream URL the token service fetches and proxies. Subscribers never see it. On Path A, use the Umbrel’s Tailscale IP in place of a public address. On Path B, this is a localhost address.

-----

## The Token Service

The complete implementation is at `pkgs/podcast-token-service/token_service.py` in the repository. This section describes how it works and what to configure.

### How It Is Built

The service uses Python with FastAPI for the HTTP layer and SQLite via aiosqlite for storage. All cryptography for Nostr — Schnorr event signing, raw x-coordinate ECDH for NIP-04 message encryption, and Schnorr signature verification for NIP-98 — is implemented directly against `libsecp256k1` via ctypes. This avoids any dependency on Python wrapper packages, some of which have packaging issues in nixpkgs. Bech32 encoding and decoding for npub and nsec keys is implemented in pure Python with no external dependencies.

On NixOS, `libsecp256k1` is provided by `pkgs.secp256k1` and linked into the derivation. On the Docker path, install `libsecp256k1-dev` (Debian/Ubuntu) or `secp256k1-dev` (Alpine) before running pip.

### Configuration

```bash
# BTCPay webhook secret — must match the value configured in BTCPay
BTCPAY_WEBHOOK_SECRET=<openssl rand -hex 32>

# PodServer internal feed URL — never exposed to subscribers
# Path A: use the Umbrel's Tailscale IP
# Path B: localhost address
PODSERVER_FEED_URL=http://<address>/podserver/feed/<feed-id>.xml

# Public base URL for subscriber feed URLs
FEED_BASE_URL=https://members.yourpodcast.com

# SQLite database
DATABASE_PATH=/var/lib/podcast-token-service/tokens.db

# SMTP for email delivery
SMTP_HOST=smtp.yourmailprovider.com
SMTP_PORT=587
SMTP_USER=you@yourpodcast.com
SMTP_PASSWORD=<password>
SMTP_FROM=members@yourpodcast.com

# Nostr keypair for the service — use a dedicated key, not your personal key
# Generate with: nak keygen
# Accepts nsec bech32 or hex format
NOSTR_PRIVATE_KEY=nsec1...
```

On startup the service logs its Nostr pubkey in npub format so you can verify which key it is using and follow or display it to subscribers if desired.

### What It Does

**Webhook handler** (`POST /webhook/btcpay`) — verifies the HMAC-SHA256 signature on every incoming webhook before processing. On `SubscriptionCreated`, issues a token, stores it, and delivers the feed URL by email and Nostr DM. On `SubscriptionRenewed`, extends the existing token’s expiry — never issues a new URL, which would break the subscriber’s podcast app silently. On `SubscriptionExpired` or `SubscriptionSuspended`, revokes all tokens for that subscriber.

**Feed endpoint** (`GET /rss/<token>.xml`) — validates the token, applies a 3-day grace period after expiry before hard cutoff, fetches the upstream PodServer feed (cached for 5 minutes), and returns it. Returns 402 for invalid or expired tokens.

**NIP-98 feed URL re-issuance** (`GET /api/feed-url`) — full Schnorr signature verification of the kind:27235 event, timestamp freshness check, and token lookup by pubkey. Allows Nostr-native subscribers to retrieve their feed URL without contacting support.

**Admin endpoints** — `GET /admin/stats` returns subscriber and active token counts. `POST /admin/cleanup` removes tokens expired or revoked more than 90 days ago. These endpoints listen only on localhost and are not proxied through nginx.

**Health endpoint** (`GET /health`) — returns `{"status":"ok"}` for uptime monitoring.

-----

## Nostr Integration

Nostr plays two roles in this architecture. On the server side it is always active: the service has its own keypair and is ready to publish to relays. On the subscriber side it is opt-in: a subscriber who provides their npub during checkout gets additional capabilities.

### Why a Subscriber Would Use Nostr

The email-only path works fine. But for a listener who lives on Nostr, providing their npub offers meaningful improvements:

**Native delivery.** Their feed URL arrives as an encrypted DM in Damus, Primal, Amethyst, YakiHonne, or whichever client they use — alongside their other messages, not in an email inbox.

**Self-service URL recovery.** If they lose their feed URL they do not need to email you. Using NIP-98, described below, they can retrieve it themselves from any Nostr client in seconds.

**Passwordless identity.** Their Nostr keypair is their identity. No separate account, password, or email address is required if they prefer not to provide one.

### NIP-04 Direct Messages

The service sends DMs using NIP-04 — kind:4 encrypted direct messages using AES-256-CBC encryption with a shared secret derived via ECDH. NIP-04 is used rather than the newer NIP-17 for compatibility across the current client landscape: Damus, Primal, Amethyst (with NIP-17 mode off), and YakiHonne all support NIP-04. NIP-17 offers better metadata privacy but is not yet universally supported, and for a one-time feed URL delivery the metadata privacy advantage is minimal.

### NIP-98: What It Is and Why It Matters Here

NIP-98 is a standard for HTTP authentication using Nostr events. Instead of a username and password, the client proves its identity by signing a request with its Nostr private key.

When a subscriber wants to retrieve their feed URL, their Nostr client creates a small JSON event of kind 27235 containing the URL they are requesting and the HTTP method. They sign it with their private key, base64-encode the result, and include it as an HTTP Authorization header. The token service decodes the event, verifies the Schnorr signature is valid, checks that the URL matches this endpoint and the event was created within the last 60 seconds, and looks up the subscription associated with that pubkey.

The result: a subscriber can prove they own the npub associated with their subscription without any password, session token, or account — just their key. For an audience already using Nostr keys to sign notes and zap payments, this is the natural model.

-----

## Accounting and Reporting

### What BTCPay Provides

BTCPay’s reporting covers the essentials for a podcast membership program: an active/expiring/expired subscriber dashboard filterable by plan, full transaction history exportable to CSV, aggregate revenue views by time period, and email delivery logs for renewal reminders.

For most podcast membership programs this is sufficient. BTCPay does not provide churn analysis, lifetime value, or subscriber growth charts — export to CSV and process in a spreadsheet if you need those.

### Useful SQLite Queries

The token service database contains operational data BTCPay does not track. Run these directly with `sqlite3 /var/lib/podcast-token-service/tokens.db`:

```sql
-- Active subscribers and when they last accessed their feed
-- (subscribers with null last_used_at may not have set up the feed yet)
SELECT s.email, s.nostr_pubkey, t.expires_at, t.last_used_at
FROM subscribers s
JOIN tokens t USING (btcpay_subscriber_id)
WHERE t.revoked = 0 AND t.expires_at > datetime('now')
ORDER BY t.last_used_at DESC;

-- Subscribers who have never accessed their feed
SELECT s.email, t.created_at
FROM subscribers s
JOIN tokens t USING (btcpay_subscriber_id)
WHERE t.last_used_at IS NULL AND t.revoked = 0;

-- Subscriptions expiring in the next 7 days
SELECT s.email, t.expires_at
FROM subscribers s
JOIN tokens t USING (btcpay_subscriber_id)
WHERE t.revoked = 0
  AND t.expires_at BETWEEN datetime('now') AND datetime('now', '+7 days');
```

-----

## Operations

### Resending a Lost Feed URL

Look up the subscriber in the BTCPay subscriber dashboard using their email address to get their `subscriberId`. Then query the token service database:

```bash
sqlite3 /var/lib/podcast-token-service/tokens.db \
  "SELECT token FROM tokens
   WHERE btcpay_subscriber_id = '<id>'
     AND revoked = 0
   ORDER BY created_at DESC LIMIT 1;"
```

Construct their feed URL as `https://members.yourpodcast.com/rss/<token>.xml` and send it manually. Subscribers who provided their npub can self-serve via the `/api/feed-url` NIP-98 endpoint without contacting you.

### Manually Revoking a Token

```bash
sqlite3 /var/lib/podcast-token-service/tokens.db \
  "UPDATE tokens SET revoked = 1
   WHERE btcpay_subscriber_id = '<id>';"
```

Then cancel the subscription in BTCPay to prevent future renewals.

### Issuing a Refund

Lightning payments are final — there are no chargebacks and no automatic refunds. For a refund request: ask the subscriber for a Lightning address or invoice, send the refund manually from your Lightning wallet, revoke the token, and cancel the subscription in BTCPay. Document your refund policy on your members page before launch.

### Recovering from a Missed Webhook

If the token service was down when BTCPay fired a webhook, BTCPay will retry delivery automatically if you enabled Automatic Redelivery during webhook configuration. Once the service is back, missed events will be delivered. For events outside the retry window, find the failed delivery in BTCPay under Store Settings > Webhooks > Delivery History and click Redeliver.

### Database Backup

The SQLite database is a single file and is the source of truth for who has active access. Back it up daily. On Path B, include it in your sops-encrypted backup or NixOS backup configuration. On Path A:

```bash
docker compose exec token-service sqlite3 \
  /var/lib/podcast-token-service/tokens.db \
  ".backup /tmp/tokens-backup.db"
# Copy /tmp/tokens-backup.db to off-site storage
```

### Token Cleanup

On Path B, the NixOS module installs a systemd timer that calls `/admin/cleanup` weekly automatically. On Path A, add a cron job to the VPS:

```bash
0 3 * * 0 curl -sf -X POST http://127.0.0.1:8765/admin/cleanup
```

### Changing Subscription Plan Pricing

Update prices in BTCPay under your store’s Subscription Offering. Existing active subscribers are unaffected — their tokens remain valid until natural expiry. New subscribers pay the updated price. For a significant price increase, export the subscriber list from BTCPay to CSV and notify existing subscribers manually before the change takes effect.

### Monitoring

Point an uptime monitor at `https://members.yourpodcast.com/health`. The `/admin/stats` endpoint returns current active subscriber and token counts — a significant drop compared to the BTCPay subscriber count indicates a sync issue worth investigating.

On Path B, `journalctl -u podcast-token-service -f` streams the service log. Key signals to watch for: `Rejected webhook: invalid signature` (misconfigured webhook secret or probing), `Feed fetch failed` (PodServer unreachable), `DM publish failed on all relays` (Nostr relay connectivity issue — non-critical since email was already sent).

On Path A, `docker compose logs -f token-service` gives the same view.

-----

## Limitations and Honest Tradeoffs

**No automatic recurring charges.** Bitcoin does not support automatic debits. Subscribers must actively renew. BTCPay’s reminder emails handle most of this, but some subscribers will lapse due to inattention. Annual plans reduce this friction significantly — make the annual option genuinely attractive.

**RSS caching.** Podcast apps cache feeds aggressively. A new episode may not appear for some subscribers for 15–60 minutes after publishing. This is normal RSS behaviour, not specific to this architecture.

**Revocation delay.** When a token is revoked, a subscriber’s podcast app does not know until its next feed poll. Previously downloaded episodes remain playable on the device. This is appropriate behaviour — subscribers who paid for access should keep what they downloaded while subscribed.

**Token sharing.** A subscriber could share their feed URL. Monitor `last_used_at` frequency for anomalous patterns and rotate tokens for suspicious accounts. Your subscribers are supporters who pay in Bitcoin to back your show — token sharing is rarely a meaningful problem in practice.

**Single point of failure.** The token service sits on the critical path for feed access. Systemd’s `Restart=on-failure` and Docker’s `restart: unless-stopped` cover most failure modes automatically. The health endpoint enables external monitoring. Brief downtime is invisible to subscribers since podcast apps retry on the next polling interval.

**Lightning is final.** There are no chargebacks. Set a clear refund policy and handle requests manually as described in the Operations section.
