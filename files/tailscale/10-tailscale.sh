export TAILSCALE_IP=$(tailscale status --json | jq -r .Self.TailscaleIPs[0])
export TAILSCALE_SHORT_DOMAIN=$(tailscale status --json | jq -r .Self.HostName)
export TAILSCALE_FULL_DOMAIN=$(tailscale status --json | jq -r .CertDomains[])
