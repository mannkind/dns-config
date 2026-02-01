resource "cloudflare_record" "thenullpointer_net_home_dyndns" {
  for_each = {
    for i, type in ["A", "AAAA"] : type => true
  }
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "home"
  proxied = false
  type    = each.key
  content = each.key == "A" ? "127.0.0.1" : "::1"
  lifecycle {
    ignore_changes = [content]
  }
}

resource "cloudflare_record" "thenullpointer_net_tunnel_refs" {
  for_each = {
    for i, ref in ["auth", "argocd", "calibre", "homeassistant", "llm", "miniflux", "plexrequests"] : ref => true
  }
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = each.key
  comment = each.key == "argocd" ? "Webhook Only" : null
  proxied = true
  type    = "CNAME"
  content = "tunnel.thenullpointer.net"
}

resource "cloudflare_record" "thenullpointer_net_tunnel_dev_refs" {
  for_each = {
    for i, ref in ["argocd-dev"] : ref => true
  }
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = each.key
  comment = each.key == "argocd-dev" ? "Webhook Only" : null
  proxied = true
  type    = "CNAME"
  content = "tunnel-dev.thenullpointer.net"
}


resource "cloudflare_record" "thenullpointer_net_caa" {
  for_each = {
    "iodef"     = "mailto:mannkind@thenullpointer.net"
    "issuewild" = "letsencrypt.org"
    "issue"     = "letsencrypt.org"
  }
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "thenullpointer.net"
  proxied = false
  type    = "CAA"
  data {
    flags = "0"
    tag   = each.key
    value = each.value
  }
}

resource "cloudflare_record" "thenullpointer_net_domainkey" {
  for_each = {
    for i, type in ["fm1", "fm2", "fm3"] : type => true
  }
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "${each.key}._domainkey"
  proxied = false
  type    = "CNAME"
  content = "${each.key}.thenullpointer.net.dkim.fmhosted.com"
}

resource "cloudflare_record" "thenullpointer_net_tunnel" {
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "tunnel"
  proxied = true
  type    = "CNAME"
  content = "placeholder.invalid"
  lifecycle {
    ignore_changes = [content]
  }
}

resource "cloudflare_record" "thenullpointer_net_tunnel_dev" {
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "tunnel-dev"
  proxied = true
  type    = "CNAME"
  content = "placeholder.invalid"
  lifecycle {
    ignore_changes = [content]
  }
}

resource "cloudflare_record" "thenullpointer_net_website" {
  for_each = {
    for i, type in ["thenullpointer.net", "www"] : type => true
  }
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = each.key
  proxied = true
  type    = "CNAME"
  content = "thenullpointer-net.pages.dev"
}

resource "cloudflare_record" "thenullpointer_net_mx10" {
  zone_id  = var.cloudflare_zoneid_thenullpointer_net
  name     = "thenullpointer.net"
  proxied  = false
  type     = "MX"
  content  = "in1-smtp.messagingengine.com"
  priority = 10
}

resource "cloudflare_record" "thenullpointer_net_mx20" {
  zone_id  = var.cloudflare_zoneid_thenullpointer_net
  name     = "thenullpointer.net"
  proxied  = false
  type     = "MX"
  content  = "in2-smtp.messagingengine.com"
  priority = 20
}

resource "cloudflare_record" "thenullpointer_net_spf" {
  zone_id = var.cloudflare_zoneid_thenullpointer_net
  name    = "thenullpointer.net"
  proxied = false
  type    = "TXT"
  content = "v=spf1 include:spf.messagingengine.com ?all"
}
