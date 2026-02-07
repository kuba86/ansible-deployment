package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.{CertError, CertOk, RunOptions}
import os.*
import scribe.*

import scala.util.{Failure, Success, Try}
import scala.util.matching.Regex

class Run(options: RunOptions) {
  info("run command executed")
  private val daysPattern: Regex = """The certificate expires in (\d+) days""".r

  def execute(): Either[CertError, CertOk] = {
    val domains: List[String] = options.certificate.certDomains.trim.split(" ").filter(_.nonEmpty).toList
    if (domains.isEmpty) {
      error("No domains provided")
      return Left(CertError.UnspecifiedError("", "No domains provided"))
    }

    val dnsServers: List[String] = options.lego.legoDnsServers.trim.split(" ").filter(_.nonEmpty).toList

    debug(s"Domains: $domains")
    debug(s"DNS Servers: $dnsServers")

    val domainFlags: List[String] = domains.flatMap(d => Seq("--domains", d))
    val dnsResolverFlags: List[String] = dnsServers.flatMap(s => Seq("--dns.resolvers", s))

    val legoCommand: Seq[String] = Seq(
      "lego",
      "--accept-tos",
      "--email", options.lego.legoEmail,
      "--path", options.lego.legoPath,
      "--server", options.lego.legoServer,
      "--dns", options.cloudflare.dnsProvider
    ) ++ domainFlags ++ dnsResolverFlags ++ Seq("run")

    debug(s"Executing command: ${legoCommand.mkString(" ")}")

    val env: Map[String, String] = Map(
      "CF_DNS_API_TOKEN" -> options.cloudflare.apiToken,
      "CLOUDFLARE_POLLING_INTERVAL" -> options.cloudflare.pollingInterval.toString,
      "CLOUDFLARE_PROPAGATION_TIMEOUT" -> options.cloudflare.propagationTimeout.toString,
      "CLOUDFLARE_TTL" -> options.cloudflare.ttl.toString
    )

    debug(s"Environment variables: ${env.keys.mkString(", ")}")

    Try {
      os.proc(legoCommand).call(
        cwd = os.pwd,
        env = env,
        stdout = os.Pipe,
        stderr = os.Pipe
      )
    } match {
      case Success(result) =>
        result.err.trim() match {
          case stderr if stderr.contains("Server responded with a certificate.") =>
        Right(CertOk.NewCertificate(domains.head))
          case stderr if stderr.contains("The certificate expires in") =>
            daysPattern.findFirstMatchIn(stderr) match {
              case Some(m) =>
                Right(CertOk.NoNeedForRenew(domains.head, Option(m.group(1).toInt)))
              case None =>
                Left(CertError.UnspecifiedError(domains.head, stderr))
            }
          case _ =>
            error(s"Lego run command failed with exit code: ${result.exitCode}")
            Left(CertError.UnspecifiedError(domains.head, result.err.trim()))
        }
      case Failure(exception) =>
        error(s"Lego run command failed with exception: ${exception.getMessage}")
        Left(CertError.UnspecifiedError("run", s"Exception: ${exception.getMessage}"))
    }
  }
}
