package com.kuba86.letsEntryptScript
package model
import caseapp.*

case class RunOptions(
    logLevel: String = "info",
    @Recurse cloudflare: Cloudflare,
    @Recurse certificate: Certificate,
    @Recurse lego: Lego
)

object RunOptions {
  implicit val parser: Parser[RunOptions] = Parser.derive
  implicit val help: Help[RunOptions]     = Help.derive
}
