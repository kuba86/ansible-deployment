package com.kuba86.letsEntryptScript
package model

case class RenewOptions(
    logLevel: String = "info",
    legoVersion: String = "latest",
    email: String = "letsencrypt-testing@kuba86.com",
    cfApiToken: String = "7hw0nXSvv7A04pbIrRZYsbIDHLdpSFhGKT1r4kGC",
    cfPoolingInterval: Int = 15,
    cfPropagationTimeout: Int = 240,
    CfTtl: Int = 120,
    domains: List[String] = List("kuba86.com", "k86.dev", "k86.pl"),
    letsEncryptPath: String = "/var/mnt/data/syncthing/Kuba-ProjectsCode/ansible-deployment/files/lets-encrypt/scala-script/tmp/.lego",
    dnsServers: List[String] = List("1.1.1.1:53", "1.0.0.1:53")
)
