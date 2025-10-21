package com.kuba86.letsEntryptScript
package model

enum RenewError {
  case UnspecifiedError(domain: String, message: String)          extends RenewError
}
