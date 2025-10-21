
package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.{RenewError, RenewOk, RenewOptions}
import com.kuba86.letsEntryptScript.model.RenewError.*
import com.kuba86.letsEntryptScript.model.RenewOk.*
import os.*
import scribe.*

import scala.util.matching.Regex

class Renew(options: RenewOptions) {
  private val daysPattern: Regex = """The certificate expires in (\d+) days""".r

  private def cmds(): List[(domain: String, cmd: String)] = options.domains.map { domain =>
    (domain = domain, cmd = options.podmanCommand(domain, "renew"))
  }

  private def executeCmd(domain: String, cmd: String): (domain: String, stderr: String, exitCode: Int) = {
    debug(s"Starting process for domain ${domain}")
    debug(s"cmd:${cmd}")
    val cmdString: List[String] = cmd
      .split("\n")
      .flatMap(_.split(" "))
      .toList
      .filterNot(_.isEmpty)

    val proc: SubProcess = os.proc(cmdString).spawn(stderr = os.Pipe)
    proc.waitFor()
    (domain = domain, stderr = proc.stderr.text(), exitCode = proc.exitCode())
  }

  private def startProcesses(): List[(domain: String, proc: SubProcess)] = cmds().map { record =>
    debug(s"Starting process for domain ${record.domain}")
    debug(s"cmd:${record.cmd}")
    val cmdString: List[String] = record.cmd
      .split("\n")
      .flatMap(_.split(" "))
      .toList
      .filterNot(_.isEmpty)

    (domain = record.domain, proc = os.proc(cmdString).spawn(stderr = os.Pipe))
  }

  private def finishedProcesses(): List[(domain: String, stderr: String, exitCode: Int)] =
    startProcesses().map { record =>
      record.proc.waitFor()
      (domain = record.domain, stderr = record.proc.stderr.text(), exitCode = record.proc.exitCode())
    }

  private def result(): List[Either[RenewError, RenewOk]] = finishedProcesses().map { record =>
    info(s"stderr for ${record.domain}:\n${record.stderr}")
    record.stderr match {
      case stderr if stderr.contains("Server responded with a certificate.") =>
        Right(NewCertificate(record.domain))

      case stderr if stderr.contains("Error while loading the certificate for domain") =>
        new Run(options)
        warn(s"Error loading certificate for domain ${record.domain}, retrying with 'run' command")
        val runCmd: String = options.podmanCommand(record.domain, "run")
        val runResult: (domain: String, stderr: String, exitCode: Int) = executeCmd(record.domain, runCmd)
        debug(s"stderr for ${record.domain} (run command):\n${runResult.stderr}")

        if (runResult.stderr.contains("Server responded with a certificate."))
          Right(NewCertificate(record.domain))
        else {
          Left(UnspecifiedError(record.domain, runResult.stderr))
        }

      case stderr if stderr.contains("The certificate expires in") =>
        daysPattern.findFirstMatchIn(stderr) match {
          case Some(m) =>
            Right(NoNeedForRenew(record.domain, Option(m.group(1).toInt)))
          case None =>
            Left(UnspecifiedError(record.domain, stderr))
        }

      case _ => Left(UnspecifiedError(record.domain, s"Unhandled stderr output for domain ${record.domain}"))
    }
  }

  private lazy val run: List[Either[RenewError, RenewOk]] = result()

  info(pprint.apply(run).render)
}
