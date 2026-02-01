package com.kuba86.letsEntryptScript
package model

case class Certificate(
    domains: List[String] = List("example.com", "*.example.com"),
    fileName: String = "example.com"
)
