---
author: gene
title: 'Proxying Bitcoin Core and LND with Tailscale and Nginx'
date: 2025-02-08 10:30 +01:00
description: >-
  How I use Nginx as a TCP proxy for bitcoind and lnd on another host via Tailscale
# image:
  # path: '/assets/images/posts/foo.png'
tags:
  - bitcoin
  - tailscale
  - nixos
  - proxy
  - vpn
  - bitcoind
  - flakes
---

Recently I decided I wanted to run my own Bitcoin and Lightning node and I wanted it to be reachable on the public internet. I didn't, however, want it to actually reside on the server that has the static public IPv4 and IPv6 addresses available. Thus, a reverse proxy was needed. This turned out to be a pretty simple thing to solve for thanks to the [Nginx Stream Proxy module](https://nginx.org/en/docs/stream/ngx_stream_proxy_module.html) and [Tailscale](https://tailscale.com/linuxunplugged). Here's the basic architecture:

- Nginx on a virtual private server (VPS) at [Hetzner](https://hetzner.cloud/?ref=TYk0wCkqSS6T) listens on ports 8333 & 9735 for TCP connections
- The stream proxy module forwards those connections to [bitcoind](https://bitcoin.org) and [lnd](https://github.com/lightningnetwork/lnd) over [Tailscale](https://tailscale.com/linuxunplugged)
- The server running bitcoind and lnd uses the [Hetzner](https://hetzner.cloud/?ref=TYk0wCkqSS6T) VPS as a Tailscale [exit node](https://tailscale.com/kb/1103/exit-nodes) so that all outbound traffic is via the VPS

Here's a technical breakdown of how I make that happen. My configuration is done via [NixOS](https://nixos.org/) flakes, but the general process would work on anything using Nginx and Tailscale.

```nix
{ config, username, ... }: let 
  domain = "example.com";
  private_btc = "some-host.your-domain.ts.net";
in {
  networking.firewall.allowedTCPPorts = [
    8333 # Bitcoin Core
    9735 # LND
  ];

  services = {
    nginx = {
      enable = true;
      streamConfig = ''
        server {
          listen 0.0.0.0:8333;
          listen [::]:8333;
          proxy_pass ${private_btc}:8333;
        }

        server {
          listen 0.0.0.0:9735;
          listen [::]:9735;
          proxy_pass ${private_btc}:9735;
        }
      '';
    }; # end nginx
    tailscale = {
      enable = true;
      authKeyFile = config.sops.secrets.tailscale_key.path;
      extraUpFlags = [
        "--advertise-exit-node"
        "--operator"
        "${username}"
        "--ssh"
      ];
      useRoutingFeatures = "both";
    }; # end tailscale
  }; # end services

  sops = {
    age.keyFile = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
    defaultSopsFile = ../secrets.yaml;
    secrets = {
      tailscale_key = {
        restartUnits = [ "tailscaled-autoconnect.service" ];
      };
    };
  }; # end sops
}
```

Breaking that down a little:

1. `networking.firewall.allowedTCPPorts` opens the firewall ports needed for bitcoind and lnd
2. `services.nginx` configures two `ngx_stream_proxy_module` instances within the `streamConfig` section that route traffic to the backend using the dns name from [Tailscale](https://tailscale.com/linuxunplugged)
3. `services.tailscale` enables Tailscale on the VPS and configures it as an [exit node](https://tailscale.com/kb/1103/exit-nodes).
4. `sops` configures [SOPS](https://getsops.io/) to securely store secrets

And that's it on the VPS. For the backend, you could be running a variety of different options from [Umbrel](https://github.com/getumbrel/umbrel) to [Nix Bitcoin](https://nixbitcoin.org/) to the services manually configured on a variety of operating systems. Settings those up is best left to a different post, but the keys that relates to this setup are:

- that where ever they run uses the VPS as an exit node
- the services listen on for connections incoming via Tailscale
- the services advertise the IP of the VPS as their public address

*Note: the links to [Hetzner](https://hetzner.cloud/?ref=TYk0wCkqSS6T) and [Tailscale](https://tailscale.com/linuxunplugged) in this post are referral / affiliate links. The Hetzner one is mine and the Tailscale one is from Jupiter Broadcasting's [Linux Unplugged](https://www.jupiterbroadcasting.com/show/linux-unplugged/) podcast. I've used the JB link because [Chris Fisher](https://chrislas.com/), [Alex Kretzschmar](https://alex.ktz.me/), [Brent Gervais](https://www.jupiterbroadcasting.com/hosts/brent/), & [Wes Payne](https://www.jupiterbroadcasting.com/hosts/wes/) have taught me about much of what's here through their podcasting.*
