package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.{CertError, CertOk}
import os.*
import scribe.*

import scala.util.{Failure, Success, Try}
import scala.util.matching.Regex

abstract class LegoJob {
  def certDomains: String
  def dnsServers: String
  def legoEmail: String
  def legoPath: Option[String]
  def legoServer: Option[String]
  def dnsProvider: String
  def cfApiToken: String
  def cfPollingInterval: String
  def cfPropagationTimeout: String
  def cfTtl: String

  def actionArgs: Seq[String]
  def actionName: String

  private val daysPattern: Regex = """The certificate expires in (\d+) days""".r

  private def buildLegoCommand(domains: List[String], dnsResolverList: List[String]): Seq[String] = {
    val domainFlags: List[String]      = domains.flatMap(d => Seq("--domains", d))
    val dnsResolverFlags: List[String] = dnsResolverList.flatMap(s => Seq("--dns.resolvers", s))

    val pathFlag: Seq[String]   = legoPath.map(v => Seq("--path", v)).getOrElse(Seq.empty)
    val serverFlag: Seq[String] = legoServer.map(v => Seq("--server", v)).getOrElse(Seq.empty)

    Seq(
      "lego",
      "--accept-tos",
      "--email",
      legoEmail,
      "--dns",
      dnsProvider
    ) ++ pathFlag ++ serverFlag ++ domainFlags ++ dnsResolverFlags ++ actionArgs
  }

  private def parseResult(result: os.CommandResult, domain: String): Either[CertError, CertOk] = {
    result.err.trim() match {
      case stderr if stderr.contains("Server responded with a certificate.") =>
        Right(CertOk.NewCertificate(domain))
      case stderr if stderr.contains("The certificate expires in") =>
        daysPattern.findFirstMatchIn(stderr) match {
          case Some(m) =>
            Right(CertOk.NoNeedForRenew(domain, Option(m.group(1).toInt)))
          case None =>
            Left(CertError.UnspecifiedError(domain, stderr))
        }
      case _ =>
        error(s"Lego $actionName command failed with exit code: ${result.exitCode}")
        Left(CertError.UnspecifiedError(domain, result.err.trim()))
    }
  }

  def execute(): Either[CertError, CertOk] = {
    val domains: List[String] = certDomains.trim.split(" ").filter(_.nonEmpty).toList
    if (domains.isEmpty) {
      error("No domains provided")
      return Left(CertError.UnspecifiedError("", "No domains provided"))
    }
    debug(s"Domains: $domains")

    val dnsResolverList: List[String] = dnsServers.trim.split(" ").filter(_.nonEmpty).toList

    val legoCommand: Seq[String] = buildLegoCommand(domains, dnsResolverList)

    debug(s"Executing command: ${legoCommand.mkString(" ")}")

    val env: Map[String, String] = Map(
      "CF_DNS_API_TOKEN"               -> cfApiToken,
      "CLOUDFLARE_POLLING_INTERVAL"    -> cfPollingInterval,
      "CLOUDFLARE_PROPAGATION_TIMEOUT" -> cfPropagationTimeout,
      "CLOUDFLARE_TTL"                 -> cfTtl
    )

    Try {
      os.proc(legoCommand)
        .call(
          cwd = os.pwd,
          env = env,
          stdout = os.Pipe,
          stderr = os.Pipe
        )
    } match {
      case Success(result) =>
        parseResult(result, domains.head)
      case Failure(exception) =>
        error(s"Lego $actionName command failed with exception: ${exception.getMessage}")
        Left(CertError.UnspecifiedError(actionName, s"Exception: ${exception.getMessage}"))
    }
  }
}
