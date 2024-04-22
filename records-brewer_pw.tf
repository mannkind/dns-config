resource "cloudflare_record" "brewer_pw_caa" {
  for_each = {
    "iodef"     = "mailto:mannkind@thenullpointer.net"
    "issuewild" = "letsencrypt.org"
    "issue"     = "letsencrypt.org"
  }
  zone_id = var.cloudflare_zoneid_brewer_pw
  name    = "brewer.pw"
  proxied = false
  type    = "CAA"
  data {
    flags = "0"
    tag   = each.key
    value = each.value
  }
}

resource "cloudflare_record" "brewer_pw_domainkey" {
  for_each = {
    for i, type in ["fm1", "fm2", "fm3"] : type => true
  }
  zone_id = var.cloudflare_zoneid_brewer_pw
  name    = "${each.key}._domainkey"
  proxied = false
  type    = "CNAME"
  value   = "${each.key}.brewer.pw.dkim.fmhosted.com"
}

resource "cloudflare_record" "brewer_pw_mx10" {
  zone_id  = var.cloudflare_zoneid_brewer_pw
  name     = "brewer.pw"
  proxied  = false
  type     = "MX"
  value    = "in1-smtp.messagingengine.com"
  priority = 10
}

resource "cloudflare_record" "brewer_pw_mx20" {
  zone_id  = var.cloudflare_zoneid_brewer_pw
  name     = "brewer.pw"
  proxied  = false
  type     = "MX"
  value    = "in2-smtp.messagingengine.com"
  priority = 20
}

resource "cloudflare_record" "brewer_pw_spf" {
  zone_id = var.cloudflare_zoneid_brewer_pw
  name    = "brewer.pw"
  proxied = false
  type    = "TXT"
  value   = "v=spf1 include:spf.messagingengine.com ?all"
}
