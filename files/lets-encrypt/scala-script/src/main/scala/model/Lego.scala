package com.kuba86.letsEntryptScript
package model

import caseapp.*

case class Lego(
    legoEmail: String,
    legoPath: Option[String],
    legoServer: Option[String],
    legoDnsServers: String = "1.1.1.1:53 1.0.0.1:53",
    legoRenewDays: Int = 30
)

object Lego {
  implicit val parser: Parser[Lego] = Parser.derive
  implicit val help: Help[Lego]     = Help.derive
}
