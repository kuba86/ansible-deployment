package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.CopyCertsOptions
import munit.FunSuite
import os.*

class CopyCertsSpec extends FunSuite {
  val tmpDir = os.temp.dir()
  val letsEncryptPath = tmpDir / "letsencrypt"
  val caddyPath = tmpDir / "caddy"

  override def afterAll(): Unit = {
    os.remove.all(tmpDir)
  }

  test("CopyCerts should copy certificates correctly when they exist") {
    val certsDir = letsEncryptPath / "certificates"
    os.makeDir.all(certsDir)

    val domain = "example.com"
    os.write.over(certsDir / s"$domain.crt", "dummy cert content")
    os.write.over(certsDir / s"$domain.key", "dummy key content")

    val options = CopyCertsOptions(
      logLevel = "debug",
      domains = List(domain),
      letsEncryptPath = letsEncryptPath.toString,
      caddyPath = caddyPath.toString
    )

    new CopyCerts(options)

    assert(os.exists(caddyPath / s"$domain.crt"))
    assert(os.exists(caddyPath / s"$domain.key"))
    assertEquals(os.read(caddyPath / s"$domain.crt"), "dummy cert content")
    assertEquals(os.read(caddyPath / s"$domain.key"), "dummy key content")
  }

  test("CopyCerts should not fail when certificates do not exist") {
    val domain = "missing.com"
    val options = CopyCertsOptions(
      logLevel = "debug",
      domains = List(domain),
      letsEncryptPath = letsEncryptPath.toString,
      caddyPath = caddyPath.toString
    )

    // Should not throw any exception
    new CopyCerts(options)

    assert(!os.exists(caddyPath / s"$domain.crt"))
    assert(!os.exists(caddyPath / s"$domain.key"))
  }

  test("CopyCerts should handle multiple domains") {
    val certsDir = letsEncryptPath / "certificates"
    os.makeDir.all(certsDir)

    val domain1 = "example1.com"
    val domain2 = "example2.com"

    os.write.over(certsDir / s"$domain1.crt", "cert1")
    os.write.over(certsDir / s"$domain1.key", "key1")
    os.write.over(certsDir / s"$domain2.crt", "cert2")
    os.write.over(certsDir / s"$domain2.key", "key2")

    val options = CopyCertsOptions(
      logLevel = "debug",
      domains = List(domain1, domain2),
      letsEncryptPath = letsEncryptPath.toString,
      caddyPath = caddyPath.toString
    )

    new CopyCerts(options)

    assert(os.exists(caddyPath / s"$domain1.crt"))
    assert(os.exists(caddyPath / s"$domain1.key"))
    assert(os.exists(caddyPath / s"$domain2.crt"))
    assert(os.exists(caddyPath / s"$domain2.key"))

    assertEquals(os.read(caddyPath / s"$domain1.crt"), "cert1")
    assertEquals(os.read(caddyPath / s"$domain2.crt"), "cert2")
  }
}
