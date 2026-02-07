package com.kuba86.letsEntryptScript
package model

case class Cloudflare(
    cfApiToken: String = "",
    cfPoolingInterval: Int = 15,
    cfPropagationTimeout: Int = 240,
    cfTtl: Int = 120,
    cfDnsProvider: String = "cloudflare"
)
