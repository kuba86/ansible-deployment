package com.kuba86.letsEntryptScript
package model

case class RenewOptions(
    logLevel: String = "info",
    legoVersion: String = "latest",
    email: String = "letsencrypt-testing@kuba86.com",
    cfApiToken: String = "7hw0nXSvv7A04pbIrRZYsbIDHLdpSFhGKT1r4kGC",
    cfPoolingInterval: Int = 15,
    cfPropagationTimeout: Int = 240,
    CfTtl: Int = 120,
    domains: List[String] = List("kuba86.com", "k86.dev", "k86.pl"),
    letsEncryptPath: String =
      "/var/mnt/data/syncthing/Kuba-ProjectsCode/ansible-deployment/files/lets-encrypt/scala-script/tmp/.lego",
    dnsServers: List[String] = List("1.1.1.1:53", "1.0.0.1:53")
)

object RenewOptions {
  extension (options: RenewOptions)
    def podmanCommand(domain: String, action: String): String = {
      val noRandomSleep: String = if (action == "renew") "--no-random-sleep" else ""
      s"""
         |podman run --rm
         |  --name=letsencrypt_lego_${domain}
         |  --volume=${options.letsEncryptPath}:/.lego:z
         |  --env=CF_DNS_API_TOKEN=${options.cfApiToken}
         |  --env=CLOUDFLARE_POLLING_INTERVAL=${options.cfPoolingInterval}
         |  --env=CLOUDFLARE_PROPAGATION_TIMEOUT=${options.cfPropagationTimeout}
         |  --env=CLOUDFLARE_TTL=${options.CfTtl}
         |  docker.io/goacme/lego:${options.legoVersion}
         |    --server=https://acme-staging-v02.api.letsencrypt.org/directory
         |    --accept-tos
         |    --dns.resolvers=${options.dnsServers.mkString(",")}
         |    --email=${options.email}
         |    --dns=cloudflare
         |    --domains=${domain}
         |    --domains=*.${domain}
         |    ${action} ${noRandomSleep}
         |""".stripMargin
    }
}
