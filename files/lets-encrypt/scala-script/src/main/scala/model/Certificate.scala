package com.kuba86.letsEntryptScript
package model

import caseapp.*

case class Certificate(
    certDomains: String = ""
)

object Certificate {
  implicit val parser: Parser[Certificate] = Parser.derive
  implicit val help: Help[Certificate]     = Help.derive
}
