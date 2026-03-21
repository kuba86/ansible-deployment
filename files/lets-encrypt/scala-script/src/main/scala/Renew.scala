package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.RenewOptions

class Renew(options: RenewOptions) extends LegoJob {
  override def certDomains: String          = options.certificate.certDomains
  override def dnsServers: String           = options.lego.legoDnsServers
  override def legoEmail: String            = options.lego.legoEmail
  override def legoPath: Option[String]     = options.lego.legoPath
  override def legoServer: Option[String]   = options.lego.legoServer
  override def dnsProvider: String          = options.cloudflare.dnsProvider
  override def cfApiToken: String           = options.cloudflare.apiToken
  override def cfPollingInterval: String    = options.cloudflare.pollingInterval.toString
  override def cfPropagationTimeout: String = options.cloudflare.propagationTimeout.toString
  override def cfTtl: String                = options.cloudflare.ttl.toString

  override def actionName: String      = "renew"
  override def actionArgs: Seq[String] = Seq(
    "renew",
    "--no-random-sleep",
    "--days",
    options.lego.legoRenewDays.toString
  )
}
