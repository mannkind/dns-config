locals {
  # Two lists from the flags in tunnels.tf, one per rule below: protected is
  # the per-IP rate ceiling, challenge the managed challenge. API clients can't
  # solve a challenge, so clear it in tunnels.tf when a host starts failing to sync.
  thenullpointer_net_protected = sort([
    for host, cfg in local.tunnel_hostnames : host
    if try(cfg.protected, false) && endswith(host, "thenullpointer.net")
  ])

  thenullpointer_net_challenged = sort([
    for host, cfg in local.tunnel_hostnames : host
    if try(cfg.challenge, false) && endswith(host, "thenullpointer.net")
  ])

  thenullpointer_net_protected_expr = format(
    "(http.host in {%s})",
    join(" ", formatlist("%q", local.thenullpointer_net_protected)),
  )

  thenullpointer_net_challenged_expr = format(
    "(http.host in {%s})",
    join(" ", formatlist("%q", local.thenullpointer_net_challenged)),
  )
}

# Cloudflare allows one custom-firewall ruleset per zone and this resource owns
# every rule in it, so a rule missing here is a rule deleted in Cloudflare.
import {
  to = cloudflare_ruleset.thenullpointer_net_waf_custom
  id = "zone/${nonsensitive(var.cloudflare_zoneid_thenullpointer_net)}/f82d4da92e05432588173b5ba28699d9"
}

resource "cloudflare_ruleset" "thenullpointer_net_waf_custom" {
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "default"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  # Predates Terraform. Blocks outright, so it must stay ahead of the challenge.
  rules {
    action      = "block"
    expression  = "(not ip.src.country in {\"US\" \"GB\"})"
    description = "USA & Friends"
    enabled     = true
  }

  rules {
    action      = "managed_challenge"
    expression  = local.thenullpointer_net_challenged_expr
    description = "Managed challenge on tunnel-fronted hostnames"
    enabled     = true
  }
}

resource "cloudflare_ruleset" "thenullpointer_net_ratelimit" {
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "default"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules {
    action      = "block"
    expression  = local.thenullpointer_net_protected_expr
    description = "Per-IP ceiling on tunnel-fronted hostnames"
    enabled     = true

    ratelimit {
      # ip.src alone is Enterprise-only; every other plan must pair it with the
      # colo, which counts per datacenter rather than globally.
      characteristics = ["ip.src", "cf.colo.id"]
      # The zone plan only permits a 10s window; 50/10s is the same sustained
      # 5 req/s the original 300/60s described.
      period              = 10
      requests_per_period = 50
      # The zone plan forces this to equal the period: a tripped IP is shut out
      # for 10s, not the 10min originally written.
      mitigation_timeout = 10
    }
  }
}
