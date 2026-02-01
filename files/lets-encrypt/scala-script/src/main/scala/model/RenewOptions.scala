package com.kuba86.letsEntryptScript
package model

case class RenewOptions(
    logLevel: String = "info",
    cloudflare: Cloudflare,
    certificate: Certificate,
    lego: Lego
)

object RenewOptions {
  extension (options: RenewOptions)
    def podmanCommand(domain: String, action: String): String = {
      val noRandomSleep: String = if (action == "renew") "--no-random-sleep" else ""
      s"""
         |podman run --rm
         |  --name=letsencrypt_lego_${domain}
         |  --volume=${options.lego.letsEncryptPath}:/.lego:z
         |  --env=CF_DNS_API_TOKEN=${options.cloudflare.cfApiToken}
         |  --env=CLOUDFLARE_POLLING_INTERVAL=${options.cloudflare.cfPoolingInterval}
         |  --env=CLOUDFLARE_PROPAGATION_TIMEOUT=${options.cloudflare.cfPropagationTimeout}
         |  --env=CLOUDFLARE_TTL=${options.cloudflare.cfTtl}
         |  --env=DNS_PROVIDER=${options.cloudflare.dnsProvider}
         |  docker.io/goacme/lego:${options.lego.legoVersion}
         |    --server=${options.lego.server}
         |    --accept-tos
         |    --dns.resolvers=${options.lego.dnsServers.mkString(",")}
         |    --email=${options.lego.email}
         |    --dns=${options.cloudflare.dnsProvider}
         |    --domains=${domain}
         |    --domains=*.${domain}
         |    ${action} ${noRandomSleep}
         |""".stripMargin
    }
}
