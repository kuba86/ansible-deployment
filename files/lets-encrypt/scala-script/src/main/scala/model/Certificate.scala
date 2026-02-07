package com.kuba86.letsEntryptScript
package model

case class Certificate(
    certDomains: List[String] = List("example.com", "*.example.com"),
    certFileName: String = "example.com"
)
