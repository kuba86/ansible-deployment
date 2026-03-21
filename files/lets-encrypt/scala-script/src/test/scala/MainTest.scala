package com.kuba86.letsEntryptScript

import munit.FunSuite
import scribe.Level

class MainTest extends FunSuite {

  def checkLogLevel(levelName: String, expectedLevels: Set[Level], unexpectedLevels: Set[Level]): Unit = {
    // Set the log level using the utility method
    val logger = Main.setLogLevel(levelName)

    expectedLevels.foreach { level =>
      assertEquals(logger.includes(level), true, s"Level $levelName should include $level")
    }

    unexpectedLevels.foreach { level =>
      assertEquals(logger.includes(level), false, s"Level $levelName should NOT include $level")
    }
  }

  test("setLogLevel maps 'fatal' correctly") {
    checkLogLevel(
      "fatal",
      Set(Level.Fatal),
      Set(Level.Error, Level.Warn, Level.Info, Level.Debug, Level.Trace)
    )
  }

  test("setLogLevel maps 'error' correctly") {
    checkLogLevel(
      "error",
      Set(Level.Fatal, Level.Error),
      Set(Level.Warn, Level.Info, Level.Debug, Level.Trace)
    )
  }

  test("setLogLevel maps 'warn' correctly") {
    checkLogLevel(
      "warn",
      Set(Level.Fatal, Level.Error, Level.Warn),
      Set(Level.Info, Level.Debug, Level.Trace)
    )
  }

  test("setLogLevel maps 'info' correctly") {
    checkLogLevel(
      "info",
      Set(Level.Fatal, Level.Error, Level.Warn, Level.Info),
      Set(Level.Debug, Level.Trace)
    )
  }

  test("setLogLevel maps 'debug' correctly") {
    checkLogLevel(
      "debug",
      Set(Level.Fatal, Level.Error, Level.Warn, Level.Info, Level.Debug),
      Set(Level.Trace)
    )
  }

  test("setLogLevel maps 'trace' correctly") {
    checkLogLevel(
      "trace",
      Set(Level.Fatal, Level.Error, Level.Warn, Level.Info, Level.Debug, Level.Trace),
      Set.empty
    )
  }

  test("setLogLevel maps unknown strings to 'info' correctly") {
    checkLogLevel(
      "unknown",
      Set(Level.Fatal, Level.Error, Level.Warn, Level.Info),
      Set(Level.Debug, Level.Trace)
    )
  }
}
