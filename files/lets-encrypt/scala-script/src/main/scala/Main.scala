package com.kuba86.letsEntryptScript

import scribe.*
import caseapp.*
import com.kuba86.letsEntryptScript.model.*

object Main extends CommandsEntryPoint {

  import scribe.Logger

  override def progName: String = "Lets Encrypt Script"

  override def commands: Seq[Command[?]] = Seq(
    RenewCommand,
    RunCommand,
    CopyCertsCommand
  )

  def setLogLevel(level: String): Logger = {
    val scribeLevel: Level = level match {
      case "fatal" => Level.Fatal
      case "error" => Level.Error
      case "warn"  => Level.Warn
      case "info"  => Level.Info
      case "debug" => Level.Debug
      case "trace" => Level.Trace
      case _       => Level.Info
    }

    Logger.root
      .clearHandlers()
      .clearModifiers()
      .withHandler(minimumLevel = Some(scribeLevel))
      .replace()
  }
}

object RenewCommand extends Command[RenewOptions] {
  override def name: String                                                   = "renew"
  override def run(options: RenewOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    val result: Either[CertError, CertOk] = new Renew(options).execute()
    result match {
      case Right(certOk) =>
        info(s"Renew successful: $certOk")
        sys.exit(0)
      case Left(certError) =>
        scribe.error(s"Renew failed: $certError")
        sys.exit(1)
    }
  }
}

object RunCommand extends Command[RunOptions] {
  override def name: String                                                 = "run"
  override def run(options: RunOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    debug(pprint.apply(remainingArgs).render)
    val result: Either[CertError, CertOk] = new Run(options).execute()
    result match {
      case Right(certOk) =>
        info(s"Run successful: $certOk")
        sys.exit(0)
      case Left(certError) =>
        scribe.error(s"Run failed: $certError")
        sys.exit(1)
    }
  }
}

object CopyCertsCommand extends Command[CopyCertsOptions] {
  override def name: String                                                       = "copy-certs"
  override def run(options: CopyCertsOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    info("starting copy")
    new CopyCerts(options)
  }
}
