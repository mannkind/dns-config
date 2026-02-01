resource "cloudflare_record" "af7nk_com_caa" {
  for_each = {
    "iodef"     = "mailto:mannkind@thenullpointer.net"
    "issuewild" = "letsencrypt.org"
    "issue"     = "letsencrypt.org"
  }
  zone_id = var.cloudflare_zoneid_af7nk_com
  name    = "af7nk.com"
  proxied = false
  type    = "CAA"
  data {
    flags = "0"
    tag   = each.key
    value = each.value
  }
}

resource "cloudflare_record" "af7nk_com_domainkey" {
  for_each = {
    for i, type in ["fm1", "fm2", "fm3"] : type => true
  }
  zone_id = var.cloudflare_zoneid_af7nk_com
  name    = "${each.key}._domainkey"
  proxied = false
  type    = "CNAME"
  content = "${each.key}.af7nk.com.dkim.fmhosted.com"
}

resource "cloudflare_record" "af7nk_com_mx10" {
  zone_id  = var.cloudflare_zoneid_af7nk_com
  name     = "af7nk.com"
  proxied  = false
  type     = "MX"
  content  = "in1-smtp.messagingengine.com"
  priority = 10
}

resource "cloudflare_record" "af7nk_com_mx20" {
  zone_id  = var.cloudflare_zoneid_af7nk_com
  name     = "af7nk.com"
  proxied  = false
  type     = "MX"
  content  = "in2-smtp.messagingengine.com"
  priority = 20
}

resource "cloudflare_record" "af7nk_com_spf" {
  zone_id = var.cloudflare_zoneid_af7nk_com
  name    = "af7nk.com"
  proxied = false
  type    = "TXT"
  content = "v=spf1 include:spf.messagingengine.com ?all"
}

resource "cloudflare_record" "af7nk_com_website" {
  for_each = {
    for i, type in ["af7nk.com", "www"] : type => true
  }
  zone_id = var.cloudflare_zoneid_af7nk_com
  name    = each.key
  proxied = true
  type    = "CNAME"
  content = "af7nk-com.pages.dev"
}
