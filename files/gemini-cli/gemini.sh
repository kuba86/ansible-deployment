#!/usr/bin/env bash

# Create config directory if it doesn't exist
mkdir -p "$HOME/.config/gemini-cli"

# Run the Gemini CLI container
# We mount the home directory's gemini-cli config and the current working directory
podman run --rm -it \
  --name "gemini-cli-$(date +%s)" \
  --volume "$HOME/.config/gemini-cli:/root/.config/gemini-cli:z" \
  --volume "$PWD:/app:z" \
  --workdir /app \
  ${GEMINI_API_KEY:+--env GEMINI_API_KEY="$GEMINI_API_KEY"} \
  gemini-cli:latest "$@"
