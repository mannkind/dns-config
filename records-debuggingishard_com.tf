resource "cloudflare_record" "debuggingishard_com_website" {
  for_each = {
    for i, type in ["debuggingishard.com", "www"] : type => true
  }
  zone_id = var.cloudflare_zoneid_debuggingishard_com
  name    = each.key
  proxied = true
  type    = "CNAME"
  value   = "debuggingishard-com.pages.dev"
}
