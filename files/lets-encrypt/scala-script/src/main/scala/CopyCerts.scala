package com.kuba86.letsEntryptScript

import com.kuba86.letsEntryptScript.model.CopyCertsOptions
import os.*
import scribe.*

class CopyCerts(options: CopyCertsOptions) {
  info("copy-certs command executed")

  val sourcePath: Path = Path(options.letsEncryptPath) / "certificates"
  val targetPath: Path = Path(options.caddyPath)

  options.domains.foreach { domain =>
    val certSource = sourcePath / s"$domain.crt"
    val keySource  = sourcePath / s"$domain.key"

    val certTarget = targetPath / s"$domain.crt"
    val keyTarget  = targetPath / s"$domain.key"

    if (exists(certSource) && exists(keySource)) {
      info(s"Copying certificates for $domain")
      copy.over(certSource, certTarget, createFolders = true)
      copy.over(keySource, keyTarget, createFolders = true)
    } else {
      warn(s"Certificates for $domain not found in $sourcePath")
    }
  }
}
