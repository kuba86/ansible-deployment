package com.kuba86.letsEntryptScript
package model
import caseapp.Recurse

case class RenewOptions(
    logLevel: String = "info",
    @Recurse(prefix = "cf-")
    cloudflare: Cloudflare,
    @Recurse(prefix = "lego-")
    lego: Lego
)
