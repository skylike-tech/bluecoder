# BlueCoder

**BlueCoder** is a platform for connecting to and using multiple AI providers and models through a unified interface.

The project combines a **Nim-based CLI** with a **Tauri desktop application**, providing a single place to manage providers, models, and API keys.

> 🚧 **Status:** In development

## ✨ Features

* 🔌 Multiple AI provider support
* 🤖 Model management
* 🔑 API key management
* 💻 Native CLI written in Nim
* 🖥️ Desktop application built with Tauri
* 🌐 Support for multiple API formats
* 🧩 Extensible provider architecture

## 🏗️ Architecture

```text
BlueCoder
│
├── CLI
│   └── Nim
│
├── Desktop UI (coming soon)
│   └── Tauri
│
└── Providers
    ├── OpenAI-compatible
    ├── Anthropic-compatible
    └── Mistral-compatible
```

## 🛠️ Technologies

| Component          | Technology              |
| ------------------ | ----------------------- |
| 💻 CLI             | Nim                     |
| 🖥️ Desktop        | Tauri                   |
| 🎨 Frontend        | HTML / CSS / JavaScript |
| 🌐 Communication   | HTTP / HTTPS            |
| 📦 Version Control | Git                     |

## 🎯 Goal

The goal of BlueCoder is to make it easy to work with different AI models without requiring a separate tool for every provider.

Users should be able to configure multiple providers and choose the model they want to use depending on the task.

## 🚀 Development

Clone the repository:

```bash
git clone git@github.com:YOUR-USERNAME/bluecoder.git
cd bluecoder
```

The project is currently under active development. Development instructions will be expanded as the project evolves.

## 🔌 Providers

BlueCoder is designed to support multiple API formats, including:

* OpenAI-compatible
* Anthropic-compatible
* Mistral-compatible

This allows BlueCoder to work with both official providers and third-party services implementing compatible APIs.

## 🔐 API Keys

API keys should always be stored securely.

**Never commit API keys or other secrets to the repository.**

Use environment variables or a secure credential store when appropriate.

## 🗺️ Roadmap

* [ ] Provider fallback system
* [ ] Provider management
* [ ] Model management
* [ ] Secure API key management
* [ ] Complete CLI
* [ ] Tauri desktop interface
* [ ] Response streaming
* [ ] Conversation history
* [ ] Shared configuration between CLI and UI
* [ ] Intelligent model routing

## 📄 License

The license for this project has not been decided yet.

---

**BlueCoder** — One interface for your AI providers.
