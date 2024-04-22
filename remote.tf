terraform {
  cloud {
    hostname     = "mannkind.scalr.io"
    organization = "Production"

    workspaces {
      name = "dns-config"
    }
  }
}
