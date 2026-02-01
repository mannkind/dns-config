resource "cloudflare_record" "ismycatavegetarian_com_website" {
  for_each = {
    for i, type in ["ismycatavegetarian.com", "www"] : type => true
  }
  zone_id = var.cloudflare_zoneid_ismycatavegetarian_com
  name    = each.key
  proxied = true
  type    = "CNAME"
  content = "ismycatavegetarian-com.pages.dev"
}
