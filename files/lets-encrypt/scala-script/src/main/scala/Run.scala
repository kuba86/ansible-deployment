package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.{CertError, CertOk, RunOptions}
import os.*
import scribe.*

import scala.util.{Failure, Success, Try}

class Run(options: RunOptions) {
  info("run command executed")

  def execute(): Either[CertError, CertOk] = {
    // Parse domains from space-separated string
    val domains = options.certificate.certDomains.trim.split(" ").filter(_.nonEmpty).toList
    if (domains.isEmpty) {
      error("No domains provided")
      return Left(CertError.UnspecifiedError(options.certificate.certFileName, "No domains provided"))
    }

    // Parse DNS servers from space-separated string
    val dnsServers = options.lego.legoDnsServers.trim.split(" ").filter(_.nonEmpty).toList

    debug(s"Domains: $domains")
    debug(s"DNS Servers: $dnsServers")

    // Build lego command
    val domainFlags = domains.flatMap(d => Seq("--domains", d))
    val dnsResolverFlags = dnsServers.flatMap(s => Seq("--dns.resolvers", s))

    val legoCommand = Seq(
      "lego",
      "--email", options.lego.legoEmail,
      "--path", options.lego.legoPath,
      "--server", options.lego.legoServer,
      "--dns", options.cloudflare.dnsProvider
    ) ++ domainFlags ++ dnsResolverFlags ++ Seq("run")

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
        info(s"Certificate successfully created for ${options.certificate.certFileName}")
        Right(CertOk.NewCertificate(options.certificate.certFileName))
      case Success(exitCode) =>
        error(s"Lego command failed with exit code: $exitCode")
        Left(CertError.UnspecifiedError(options.certificate.certFileName, s"Lego command failed with exit code: $exitCode"))
      case Failure(exception) =>
        error(s"Lego command failed with exception: ${exception.getMessage}")
        Left(CertError.UnspecifiedError(options.certificate.certFileName, s"Exception: ${exception.getMessage}"))
    }
  }
}
