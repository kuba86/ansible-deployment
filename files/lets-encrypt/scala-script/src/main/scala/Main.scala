package com.kuba86.letsEntryptScript

import caseapp.*
import com.kuba86.letsEntryptScript.model.*
import scribe.*

object Main extends CommandsEntryPoint {

  import scribe.Logger

  override def progName: String = "Lets Encrypt Script"

  override def commands = Seq(
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
  override def name: String = "renew"
  override def run(options: RenewOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    info("starting renew")
    new Renew(options)
  }
}

object RunCommand extends Command[RenewOptions] {
  override def name: String = "run"
  override def run(options: RenewOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    info("starting run")
    new Run(options)
  }
}

object CopyCertsCommand extends Command[CopyCertsOptions] {
  override def name: String = "copy-certs"
  override def run(options: CopyCertsOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    info("starting copy")
    new CopyCerts(options)
  }
}
