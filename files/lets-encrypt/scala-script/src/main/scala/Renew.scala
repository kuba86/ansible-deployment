
package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.RenewOptions
import os.*
import scribe.*

import scala.util.matching.Regex

class Renew(options: RenewOptions) {
  private val daysPattern: Regex = """The certificate expires in (\d+) days""".r

  private def buildCmd(domain: String, action: String): String = {
    s"""
       |podman run --rm
       |  --name=letsencrypt_lego_${domain}
       |  --volume=${options.letsEncryptPath}:/.lego:z
       |  --env=CF_DNS_API_TOKEN=${options.cfApiToken}
       |  --env=CLOUDFLARE_POLLING_INTERVAL=${options.cfPoolingInterval}
       |  --env=CLOUDFLARE_PROPAGATION_TIMEOUT=${options.cfPropagationTimeout}
       |  --env=CLOUDFLARE_TTL=${options.CfTtl}
       |  docker.io/goacme/lego:${options.legoVersion}
       |    --server=https://acme-staging-v02.api.letsencrypt.org/directory
       |    --accept-tos
       |    --dns.resolvers=${options.dnsServers.mkString(",")}
       |    --email=${options.email}
       |    --dns=cloudflare
       |    --domains=${domain}
       |    --domains=*.${domain}
       |    ${action}
       |""".stripMargin
  }

  private def cmds(): List[(domain: String, cmd: String)] = options.domains.map { domain =>
    (domain = domain, cmd = buildCmd(domain, "renew --no-random-sleep"))
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

  private def result(): List[(domain: String, msg: String)] = finishedProcesses().flatMap { record =>
    info(s"stderr for ${record.domain}:\n${record.stderr}")
    record.stderr match {
      case stderr if stderr.contains("Server responded with a certificate.") =>
        List((domain = record.domain, msg = "Server responded with a certificate."))

      case stderr if stderr.contains("Error while loading the certificate for domain") =>
        warn(s"Error loading certificate for domain ${record.domain}, retrying with 'run' command")
        val runCmd: String = buildCmd(record.domain, "run")
        val runResult: (domain: String, stderr: String, exitCode: Int) = executeCmd(record.domain, runCmd)
        debug(s"stderr for ${record.domain} (run command):\n${runResult.stderr}")

        if (runResult.stderr.contains("Server responded with a certificate.")) {
          List((domain = record.domain, msg = "Server responded with a certificate. (via run command)"))
        } else {
          List((domain = record.domain, msg = s"Error running 'run' command: ${runResult.stderr}"))
        }

      case stderr if stderr.contains("The certificate expires in") =>
        daysPattern.findFirstMatchIn(stderr) match {
          case Some(m) => List((domain = record.domain, msg = s"Days until expiration: ${m.group(1)}"))
          case None => List((domain = record.domain, msg = "Could not extract days from a certificate expiration message"))
        }

      case _ => List((domain = record.domain, msg = s"Unhandled stderr output for domain ${record.domain}"))
    }
  }

  private lazy val run: List[(domain: String, msg: String)] = result()

  info(pprint.apply(run).render)
}
