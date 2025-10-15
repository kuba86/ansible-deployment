package com.kuba86.letsEntryptScript

import caseapp.*
import com.kuba86.letsEntryptScript.model.*
import scribe.*

object Main extends CommandsEntryPoint {

  import scribe.Logger

  override def progName: String = "Lets Encrypt Script"

  override def commands: Seq[Command[?]] = Seq(
    RenewCommand,
    CaddyCommand
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
  override def run(options: RenewOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
    new Renew(options)
  }
}

object CaddyCommand extends Command[CaddyOptions] {
  override def run(options: CaddyOptions, remainingArgs: RemainingArgs): Unit = {
    Main.setLogLevel(options.logLevel)
    debug(pprint.apply(options).render)
  }
}
