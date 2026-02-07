package com.kuba86.letsEntryptScript
package model

import caseapp.*

case class Lego(
    legoVersion: String = "",
    legoEmail: String = "",
    legoPath: String = "",
    legoDnsServers: String = "",
    legoServer: String = "",
    legoRenewDays: Int = 30
)

object Lego {
  implicit val parser: Parser[Lego] = Parser.derive
  implicit val help: Help[Lego]     = Help.derive
}
