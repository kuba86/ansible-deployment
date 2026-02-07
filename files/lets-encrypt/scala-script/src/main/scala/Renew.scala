package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.RenewOptions

class Renew(options: RenewOptions) extends LegoJob {
  override protected def certDomains: String          = options.certificate.certDomains
  override protected def dnsServers: String           = options.lego.legoDnsServers
  override protected def legoEmail: String            = options.lego.legoEmail
  override protected def legoPath: Option[String]     = options.lego.legoPath
  override protected def legoServer: Option[String]   = options.lego.legoServer
  override protected def dnsProvider: String          = options.cloudflare.dnsProvider
  override protected def cfApiToken: String           = options.cloudflare.apiToken
  override protected def cfPollingInterval: String    = options.cloudflare.pollingInterval.toString
  override protected def cfPropagationTimeout: String = options.cloudflare.propagationTimeout.toString
  override protected def cfTtl: String                = options.cloudflare.ttl.toString

  override protected def actionName: String      = "renew"
  override protected def actionArgs: Seq[String] = Seq(
    "renew",
    "--no-random-sleep",
    "--days",
    options.lego.legoRenewDays.toString
  )
}
