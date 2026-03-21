package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.RunOptions

class Run(options: RunOptions) extends LegoJob {
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

  override def actionName: String      = "run"
  override def actionArgs: Seq[String] = Seq("run")
}
