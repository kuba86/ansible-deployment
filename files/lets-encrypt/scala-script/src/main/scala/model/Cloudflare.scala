package com.kuba86.letsEntryptScript
package model

import caseapp.*

case class Cloudflare(
    apiToken: String,
    pollingInterval: Int = 15,
    propagationTimeout: Int = 300,
    ttl: Int = 120,
    dnsProvider: String = "cloudflare"
)

object Cloudflare {
  implicit val parser: Parser[Cloudflare] = Parser.derive
  implicit val help: Help[Cloudflare]     = Help.derive
}
