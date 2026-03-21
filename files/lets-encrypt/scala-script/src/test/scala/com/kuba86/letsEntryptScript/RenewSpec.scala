package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.*
import munit.FunSuite

class RenewSpec extends FunSuite {
  val options = RenewOptions(
    logLevel = "debug",
    cloudflare = Cloudflare(
      apiToken = "test-token",
      pollingInterval = 10,
      propagationTimeout = 200,
      ttl = 60,
      dnsProvider = "test-provider"
    ),
    certificate = Certificate(
      certDomains = "example.com www.example.com"
    ),
    lego = Lego(
      legoEmail = "test@example.com",
      legoPath = Some("/tmp/lego"),
      legoServer = Some("https://acme-staging-v02.api.letsencrypt.org/directory"),
      legoDnsServers = "8.8.8.8:53",
      legoRenewDays = 15
    )
  )

  val renew = new Renew(options)

  test("Renew should correctly map options") {
    assertEquals(renew.certDomains, "example.com www.example.com")
    assertEquals(renew.dnsServers, "8.8.8.8:53")
    assertEquals(renew.legoEmail, "test@example.com")
    assertEquals(renew.legoPath, Some("/tmp/lego"))
    assertEquals(renew.legoServer, Some("https://acme-staging-v02.api.letsencrypt.org/directory"))
    assertEquals(renew.dnsProvider, "test-provider")
    assertEquals(renew.cfApiToken, "test-token")
    assertEquals(renew.cfPollingInterval, "10")
    assertEquals(renew.cfPropagationTimeout, "200")
    assertEquals(renew.cfTtl, "60")
  }

  test("Renew should have correct action name and args") {
    assertEquals(renew.actionName, "renew")
    assertEquals(renew.actionArgs, Seq("renew", "--no-random-sleep", "--days", "15"))
  }
}
