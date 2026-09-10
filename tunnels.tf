locals {
  # Traefik fronts every brewery service; the tunnel only needs to reach it.
  # Pointing rules at services directly would drag host/port churn into this repo.
  traefik = "https://ingress.home.thenullpointer.net"

  zones = {
    "thenullpointer.net" = var.cloudflare_zoneid_thenullpointer_net
    "brewer.pw"          = var.cloudflare_zoneid_brewer_pw
  }

  # One list per tunnel, keyed by the name Cloudflare knows. Both the ingress
  # rules and the DNS records come from here, so the two cannot drift apart.
  # protected = true adds the hostname to the managed challenge in
  # security-thenullpointer_net.tf. Clients that cannot solve a challenge
  # (miniflux, calibre, plexrequests all sync over API) must stay out.
  tunnels = {
    "brewery-ingress" = {
      "actual.thenullpointer.net"        = { service = local.traefik, protected = true }
      "auth.thenullpointer.net"          = { service = local.traefik, protected = true }
      "calibre.thenullpointer.net"       = { service = local.traefik }
      "homeassistant.thenullpointer.net" = { service = local.traefik, protected = true }
      "miniflux.thenullpointer.net"      = { service = local.traefik }
      "plexrequests.thenullpointer.net"  = { service = local.traefik }
      "reservations.brewer.pw"           = { service = local.traefik }
      "vw.thenullpointer.net"            = { service = local.traefik, protected = true }
      "welcomemat.thenullpointer.net"    = { service = local.traefik }
    }

    "coast-ingress" = {
      "birdnet-coast.brewer.pw"                = { service = "http://birdnet-go:8080" }
      "homeassistant-coast.thenullpointer.net" = { service = "http://homeassistant:8123" }
    }

    "ranch-ingress" = {
      "birdnet-ranch.brewer.pw"                = { service = "http://birdnet-go:8080" }
      "homeassistant-ranch.thenullpointer.net" = { service = "http://homeassistant:8123" }
    }
  }

  # fqdn -> the zone apex it sits under
  tunnel_hostname_zone = {
    for hname in flatten([for tname, hosts in local.tunnels : keys(hosts)]) :
    hname => one([for z, id in local.zones : z if endswith(hname, ".${z}")])
  }

  # fqdn -> { service, tunnel, zone_id, name, protected? }
  # name is the short label, not the fqdn: the provider treats a changed name as
  # a new record and would destroy and recreate every hostname.
  tunnel_hostnames = merge([
    for tname, hosts in local.tunnels : {
      for hname, cfg in hosts : hname => merge(cfg, {
        tunnel  = tname
        zone_id = local.zones[local.tunnel_hostname_zone[hname]]
        name    = trimsuffix(hname, ".${local.tunnel_hostname_zone[hname]}")
      })
    }
  ]...)
}

data "cloudflare_zero_trust_tunnel_cloudflared" "this" {
  for_each = local.tunnels

  account_id = var.cloudflare_account_id
  name       = each.key
}

resource "cloudflare_zero_trust_tunnel_cloudflared_config" "this" {
  for_each = local.tunnels

  account_id = var.cloudflare_account_id
  tunnel_id  = data.cloudflare_zero_trust_tunnel_cloudflared.this[each.key].id

  config {
    dynamic "ingress_rule" {
      for_each = each.value
      content {
        hostname = ingress_rule.key
        service  = ingress_rule.value.service
      }
    }

    # Cloudflare matches in order and requires a catch-all last.
    ingress_rule {
      service = "http_status:404"
    }

    # No warp_routing block on purpose. It is already disabled on every tunnel,
    # and the provider reads a disabled setting back as absent, so declaring it
    # produces a diff that never settles.
  }
}

resource "cloudflare_record" "tunnel_hostnames" {
  for_each = local.tunnel_hostnames

  zone_id = each.value.zone_id
  name    = each.value.name
  proxied = true
  type    = "CNAME"
  content = "${data.cloudflare_zero_trust_tunnel_cloudflared.this[each.value.tunnel].id}.cfargotunnel.com"
}
