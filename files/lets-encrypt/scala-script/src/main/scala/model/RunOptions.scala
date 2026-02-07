package com.kuba86.letsEntryptScript
package model
import caseapp.Recurse

case class RunOptions(
    logLevel: String = "info",
    @Recurse(prefix = "cf-")
    cloudflare: Cloudflare,
    @Recurse(prefix = "cert-")
    certificate: Certificate,
    @Recurse(prefix = "lego-")
    lego: Lego
)
