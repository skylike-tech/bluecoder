# Getting started

BlueCoder has a native Nim CLI and a Tauri desktop shell. Both read the shared
configuration file at `~/.config/bluecoder/config.json` (or
`$XDG_CONFIG_HOME/bluecoder/config.json`). The file is created with owner-only
permissions on POSIX systems.

## Build the CLI

Install Nim 2.x, then run from the repository root:

```bash
make cli
./bluecoder init
```

## Configure a provider

Use the provider's API-root URL: BlueCoder appends `/v1/...` itself.

```bash
./bluecoder providers add --name openai --type openai --url https://api.openai.com
export BLUECODER_OPENAI_API_KEY='your-key'
./bluecoder models fetch openai
./bluecoder config set-default --provider openai --model gpt-4.1-mini
./bluecoder chat --message "Say hello in Portuguese"
```

The CLI supports `openai`, `anthropic`, and `mistral` formats. For a
third-party compatible service, use the matching API format and its API-root
URL. Environment variables have precedence over keys saved through `--key` and
are recommended so credentials do not live in the configuration file.

## Build the desktop application

Install Node.js, Rust, and the Tauri system dependencies for your operating
system, then:

```bash
make desktop
```

The desktop application displays the same provider configuration created by the
CLI. It deliberately never returns API keys to its frontend.
