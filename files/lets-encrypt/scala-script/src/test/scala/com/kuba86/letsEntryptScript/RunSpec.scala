package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.*
import munit.FunSuite

class RunSpec extends FunSuite {
  val options = RunOptions(
    logLevel = "debug",
    cloudflare = Cloudflare(
      apiToken = "test-token",
      pollingInterval = 10,
      propagationTimeout = 200,
      ttl = 60,
      dnsProvider = "test-provider"
    ),
    certificate = Certificate(
      certDomains = "example.com www.example.com"
    ),
    lego = Lego(
      legoEmail = "test@example.com",
      legoPath = Some("/tmp/lego"),
      legoServer = Some("https://acme-staging-v02.api.letsencrypt.org/directory"),
      legoDnsServers = "8.8.8.8:53"
    )
  )

  val run = new Run(options)

  test("Run should correctly map options") {
    assertEquals(run.certDomains, "example.com www.example.com")
    assertEquals(run.dnsServers, "8.8.8.8:53")
    assertEquals(run.legoEmail, "test@example.com")
    assertEquals(run.legoPath, Some("/tmp/lego"))
    assertEquals(run.legoServer, Some("https://acme-staging-v02.api.letsencrypt.org/directory"))
    assertEquals(run.dnsProvider, "test-provider")
    assertEquals(run.cfApiToken, "test-token")
    assertEquals(run.cfPollingInterval, "10")
    assertEquals(run.cfPropagationTimeout, "200")
    assertEquals(run.cfTtl, "60")
  }

  test("Run should have correct action name and args") {
    assertEquals(run.actionName, "run")
    assertEquals(run.actionArgs, Seq("run"))
  }

  test("Run.execute should return error when domains are empty") {
    val emptyOptions = options.copy(certificate = Certificate(certDomains = ""))
    val runEmpty     = new Run(emptyOptions)
    val result       = runEmpty.execute()
    assertEquals(result, Left(CertError.UnspecifiedError("", "No domains provided")))
  }

  test("Run.execute should return error when domains are whitespace only") {
    val whitespaceOptions = options.copy(certificate = Certificate(certDomains = "   "))
    val runWhitespace     = new Run(whitespaceOptions)
    val result            = runWhitespace.execute()
    assertEquals(result, Left(CertError.UnspecifiedError("", "No domains provided")))
  }

  test("Run.execute should handle process execution failure (Exception)") {
    class RunThrows(options: RunOptions) extends Run(options) {
      override protected def runCommand(command: Seq[String], env: Map[String, String]): os.CommandResult = {
        throw new RuntimeException("Simulated process failure")
      }
    }

    val runFailure = new RunThrows(options)
    val result     = runFailure.execute()

    assertEquals(
      result,
      Left(CertError.UnspecifiedError("run", "Exception: Simulated process failure"))
    )
  }

  test("Run.execute should handle successful certificate issuance") {
    class RunSuccess(options: RunOptions) extends Run(options) {
      override protected def runCommand(command: Seq[String], env: Map[String, String]): os.CommandResult = {
        os.CommandResult(0, Seq.empty, os.Source.fromString(""), os.Source.fromString("Server responded with a certificate."))
      }
    }

    val runSuccess = new RunSuccess(options)
    val result     = runSuccess.execute()

    assertEquals(result, Right(CertOk.NewCertificate("example.com")))
  }
}
