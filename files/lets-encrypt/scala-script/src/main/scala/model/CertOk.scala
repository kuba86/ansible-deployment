package com.kuba86.letsEntryptScript
package model

enum CertOk {
  case NoNeedForRenew(domain: String, daysRemaining: Option[Int]) extends CertOk
  case NewCertificate(domain: String)                             extends CertOk
}
