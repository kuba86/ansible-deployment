package com.kuba86.letsEntryptScript
package model

enum RenewOk {
  case NoNeedForRenew(domain: String, daysRemaining: Option[Int]) extends RenewOk
  case NewCertificate(domain: String) extends RenewOk
}
