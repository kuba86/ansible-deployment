package com.kuba86.letsEntryptScript
package model

case class Lego(
    legoVersion: String = "latest",
    email: String = "letsencrypt-testing@example.com",
    letsEncryptPath: String = "tmp/.lego",
    dnsServers: List[String] = List("1.1.1.1:53", "1.0.0.1:53"),
    server: String = "https://acme-staging-v02.api.letsencrypt.org/directory"
)
