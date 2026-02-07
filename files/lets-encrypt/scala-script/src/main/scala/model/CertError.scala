package com.kuba86.letsEntryptScript
package model

enum CertError {
  case UnspecifiedError(domain: String, message: String) extends CertError
}
