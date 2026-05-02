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

  protected def runCommand(command: Seq[String], env: Map[String, String]): os.CommandResult = {
    os.proc(command)
      .call(
        cwd = os.pwd,
        env = env,
        stdout = os.Pipe,
        stderr = os.Pipe
      )
  }

  def execute(): Either[CertError, CertOk] = {
    val domains: List[String] = certDomains.trim.split(" ").filter(_.nonEmpty).toList
    if (domains.isEmpty) {
      error("No domains provided")
      return Left(CertError.UnspecifiedError("", "No domains provided"))
    }
    debug(s"Domains: $domains")

    val dnsResolverList: List[String] = dnsServers.trim.split(" ").filter(_.nonEmpty).toList

    val domainFlags: List[String]      = domains.flatMap(d => Seq("--domains", d))
    val dnsResolverFlags: List[String] = dnsResolverList.flatMap(s => Seq("--dns.resolvers", s))

    val pathFlag: Seq[String]   = legoPath.map(v => Seq("--path", v)).getOrElse(Seq.empty)
    val serverFlag: Seq[String] = legoServer.map(v => Seq("--server", v)).getOrElse(Seq.empty)

    val legoCommand: Seq[String] = Seq(
      "lego",
      "--accept-tos",
      "--email",
      legoEmail,
      "--dns",
      dnsProvider
    ) ++ pathFlag ++ serverFlag ++ domainFlags ++ dnsResolverFlags ++ actionArgs

    debug(s"Executing command: ${legoCommand.mkString(" ")}")

    val env: Map[String, String] = Map(
      "CF_DNS_API_TOKEN"               -> cfApiToken,
      "CLOUDFLARE_POLLING_INTERVAL"    -> cfPollingInterval,
      "CLOUDFLARE_PROPAGATION_TIMEOUT" -> cfPropagationTimeout,
      "CLOUDFLARE_TTL"                 -> cfTtl
    )

    Try {
      runCommand(legoCommand, env)
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
            error(s"Lego $actionName command failed with exit code: ${result.exitCode}")
            Left(CertError.UnspecifiedError(domains.head, result.err.trim()))
        }
      case Failure(exception) =>
        error(s"Lego $actionName command failed with exception: ${exception.getMessage}")
        Left(CertError.UnspecifiedError(actionName, s"Exception: ${exception.getMessage}"))
    }
  }
}
