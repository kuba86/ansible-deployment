package com.kuba86.letsEntryptScript
package model

case class CaddyOptions(
    logLevel: String = "info",
    domains: List[String] = List(),
    letsEncryptPath: String = "",
    caddyPath: String = ""
)
