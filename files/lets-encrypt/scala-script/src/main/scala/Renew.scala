package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.RenewOptions
import os.*
import scribe.*

import scala.util.matching.Regex

class Renew(options: RenewOptions) {
  private val cmds: List[(domain: String, cmd: String)] = options.domains.map { domain =>
    (
      domain = domain,
      cmd = s"""
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
        |    renew --no-random-sleep
        |""".stripMargin
    )
  }

  private val startProcesses: List[(domain: String, proc: SubProcess)] = cmds.map { record =>
    debug(s"Starting process for domain ${record.domain}")
    debug(s"cmd:${record.cmd}")
    val cmdString: List[String] = record.cmd
      .split("\n")
      .flatMap(_.split(" "))
      .toList
      .filterNot(_.isEmpty)

    (domain = record.domain, proc = os.proc(cmdString).spawn(stderr = os.Pipe))
  }

  private val finishedProcesses: List[(domain: String, stderr: String, exitCode: Int)] =
    startProcesses.map { record =>
      record.proc.waitFor()
      (domain = record.domain, stderr = record.proc.stderr.text(), exitCode = record.proc.exitCode())
  }

  private val daysPattern: Regex = """The certificate expires in (\d+) days""".r

  private val result: List[(domain: String, msg: String)] = finishedProcesses.map { record =>
    debug(s"stderr for ${record.domain}:\n${record.stderr}")
    record.stderr match {
      case stderr if stderr.contains("Server responded with a certificate.") =>
        (domain = record.domain, msg = "Server responded with a certificate.")

      case stderr if stderr.contains("Error while loading the certificate for domain") =>
        (domain = record.domain, msg = stderr.split("\n").lastOption.getOrElse("").trim)

      case stderr if stderr.contains("The certificate expires in") =>
        daysPattern.findFirstMatchIn(stderr) match {
          case Some(m) => (domain = record.domain, msg = s"Days until expiration: ${m.group(1)}")
          case None => (domain = record.domain, msg = "Could not extract days from a certificate expiration message")
        }
      
      case _ => (domain = record.domain, msg = s"Unhandled stderr output for domain ${record.domain}")
    }
  }

  info(pprint.apply(result).render)
}
