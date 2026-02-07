package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.{CertError, CertOk, RenewOptions}
import os.*
import scribe.*

import scala.util.{Failure, Success, Try}
import scala.util.matching.Regex

class Renew(options: RenewOptions) {
  info("renew command executed")

  def execute(): Either[CertError, CertOk] = {
    // Parse DNS servers from space-separated string
    val dnsServers = options.lego.legoDnsServers.trim.split(" ").filter(_.nonEmpty).toList

    debug(s"DNS Servers: $dnsServers")

    // Build lego command
    val dnsResolverFlags = dnsServers.flatMap(s => Seq("--dns.resolvers", s))

    val legoCommand = Seq(
      "lego",
      "--email", options.lego.legoEmail,
      "--path", options.lego.legoPath,
      "--server", options.lego.legoServer,
      "--dns", options.cloudflare.dnsProvider
    ) ++ dnsResolverFlags ++ Seq("renew", "--days", "30")

    debug(s"Executing command: ${legoCommand.mkString(" ")}")

    // Set environment variables for Cloudflare
    val env = Map(
      "CF_DNS_API_TOKEN" -> options.cloudflare.apiToken,
      "CLOUDFLARE_POLLING_INTERVAL" -> options.cloudflare.pollingInterval.toString,
      "CLOUDFLARE_PROPAGATION_TIMEOUT" -> options.cloudflare.propagationTimeout.toString,
      "CLOUDFLARE_TTL" -> options.cloudflare.ttl.toString
    )

    debug(s"Environment variables: ${env.keys.mkString(", ")}")

    // Execute command
    Try {
      val result = os.proc(legoCommand).call(
        cwd = os.pwd,
        env = env,
        stdin = os.Inherit,
        stdout = os.Inherit,
        stderr = os.Inherit
      )
      result.exitCode
    } match {
      case Success(0) =>
        info("Certificate renewal completed successfully")
        Right(CertOk.NewCertificate("renewed"))
      case Success(exitCode) =>
        error(s"Lego renew command failed with exit code: $exitCode")
        Left(CertError.UnspecifiedError("renew", s"Lego renew command failed with exit code: $exitCode"))
      case Failure(exception) =>
        error(s"Lego renew command failed with exception: ${exception.getMessage}")
        Left(CertError.UnspecifiedError("renew", s"Exception: ${exception.getMessage}"))
    }
  }
}
