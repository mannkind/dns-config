resource "cloudflare_record" "mirandalovesdeals_com_website" {
  for_each = {
    for i, type in ["mirandalovesdeals.com", "www"] : type => true
  }
  zone_id = var.cloudflare_zoneid_mirandalovesdeals_com
  name    = each.key
  proxied = true
  type    = "CNAME"
  value   = "mirandalovesdeals-com.pages.dev"
}
