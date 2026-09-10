locals {
  # Hostnames the tunnel fronts. Every name here gets a managed challenge and a
  # per-IP rate ceiling. API clients cannot solve a challenge, so dropping a
  # name from this list is the fix when one starts failing to sync.
  thenullpointer_net_protected = [
    "auth.thenullpointer.net",
    "actual.thenullpointer.net",
    "homeassistant.thenullpointer.net",
    "vw.thenullpointer.net",
  ]

  thenullpointer_net_protected_expr = format(
    "(http.host in {%s})",
    join(" ", formatlist("%q", local.thenullpointer_net_protected)),
  )
}

resource "cloudflare_ruleset" "thenullpointer_net_waf_custom" {
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "default"
  kind    = "zone"
  phase   = "http_request_firewall_custom"

  rules {
    action      = "managed_challenge"
    expression  = local.thenullpointer_net_protected_expr
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
      characteristics     = ["ip.src", "cf.colo.id"]
      period              = 60
      requests_per_period = 300
      mitigation_timeout  = 600
    }
  }
}
