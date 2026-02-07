package com.kuba86.letsEntryptScript
package model
import caseapp.*

case class RenewOptions(
    logLevel: String = "info",
    @Recurse cloudflare: Cloudflare,
    @Recurse lego: Lego
)

object RenewOptions {
  implicit val parser: Parser[RenewOptions] = Parser.derive
  implicit val help: Help[RenewOptions]     = Help.derive
}
