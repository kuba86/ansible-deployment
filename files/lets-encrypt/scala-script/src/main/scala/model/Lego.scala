package com.kuba86.letsEntryptScript
package model

case class Lego(
    legoVersion: String = "latest",
    legoEmail: String = "letsencrypt-testing@example.com",
    legoPath: String = "tmp/.lego",
    legoDnsServers: List[String] = List("1.1.1.1:53", "1.0.0.1:53"),
    legoServer: String = "https://acme-staging-v02.api.letsencrypt.org/directory"
)
