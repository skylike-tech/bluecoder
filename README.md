<div align="center">

# BlueCoder

### One interface. Every AI provider.

A unified platform for connecting, managing, and using multiple AI providers and models from a single environment.

<br>

[![Status](https://img.shields.io/badge/status-in%20development-orange?style=for-the-badge)](#)
[![CLI](https://img.shields.io/badge/CLI-Nim-FFE953?style=for-the-badge\&logo=nim\&logoColor=black)](#)
[![Desktop](https://img.shields.io/badge/Desktop-Tauri-24C8DB?style=for-the-badge\&logo=tauri\&logoColor=white)](#)
[![License](https://img.shields.io/badge/license-TBD-lightgrey?style=for-the-badge)](#)

<br>

**BlueCoder** brings multiple AI providers together through a unified CLI and desktop interface.

</div>

---

## ✨ What is BlueCoder?

BlueCoder is a platform designed to make working with different AI providers simple.

Instead of configuring and learning a different tool for every provider, BlueCoder provides a common interface for managing:

* AI providers
* Models
* API endpoints
* API keys
* Conversations
* Model selection
* Provider routing

The project consists of a **native Nim CLI** and a **Tauri desktop application**.

---

## 🧠 Why BlueCoder?

<div align="center">

|             Problem            |           BlueCoder          |
| :----------------------------: | :--------------------------: |
|      Multiple AI providers     |       Unified interface      |
|      Different API formats     |       Provider adapters      |
| Different model configurations | Centralized model management |
|   Switching between providers  |   Simple provider selection  |
|          CLI workflows         |        Native Nim CLI        |
|        Desktop workflows       |       Tauri application      |

</div>

---

## 🚀 Features

<table>
<tr>
<td width="50%">

### 🔌 Provider Management

Connect multiple AI providers and configure their API endpoints and credentials.

</td>
<td width="50%">

### 🤖 Model Management

Organize and select models from different providers through one interface.

</td>
</tr>

<tr>
<td>

### 💻 Native CLI

A fast command-line interface written in **Nim**.

</td>
<td>

### 🖥️ Desktop Application

A cross-platform desktop interface powered by **Tauri**.

</td>
</tr>

<tr>
<td>

### 🔑 Credential Management

Keep provider credentials separate from the application logic.

</td>
<td>

### 🧩 Extensible Architecture

Add new providers without rewriting the core system.

</td>
</tr>
</table>

---

## 🏗️ Architecture

```text
                         ┌──────────────────────┐
                         │      BlueCoder       │
                         └──────────┬───────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    │                               │
             ┌──────▼──────┐                 ┌──────▼──────┐
             │     CLI      │                 │  Desktop UI │
             │     Nim      │                 │    Tauri    │
             └──────┬──────┘                 └──────┬──────┘
                    │                               │
                    └───────────────┬───────────────┘
                                    │
                            ┌───────▼────────┐
                            │ Provider Layer │
                            └───────┬────────┘
                                    │
              ┌─────────────────────┼─────────────────────┐
              │                     │                     │
       ┌──────▼──────┐       ┌──────▼──────┐       ┌──────▼──────┐
       │   OpenAI    │       │  Anthropic  │       │   Mistral   │
       │ Compatible  │       │ Compatible  │       │ Compatible  │
       └─────────────┘       └─────────────┘       └─────────────┘
```

---

## 🛠️ Technology Stack

<div align="center">

| Component          | Technology                  |
| :----------------- | :-------------------------- |
| 💻 CLI             | **Nim**                     |
| 🖥️ Desktop        | **Tauri**                   |
| 🎨 Frontend        | **HTML / CSS / JavaScript** |
| 🌐 Networking      | **HTTP / HTTPS**            |
| 🔀 Version Control | **Git**                     |

</div>

---

## 🔌 Supported API Formats

BlueCoder is designed around provider adapters rather than hard-coding individual services.

Currently planned API compatibility:

```text
OpenAI-compatible
Anthropic-compatible
Mistral-compatible
```

This means third-party services implementing compatible APIs can potentially be used without requiring a completely separate integration.

### Example

```text
Provider
│
├── Name
├── API Type
├── Base URL
├── API Key
└── Models
    ├── Model A
    ├── Model B
    └── Model C
```

---

## 💻 CLI

The BlueCoder CLI is written in **Nim**.

Example commands:

```bash
bluecoder providers
bluecoder models
bluecoder config
bluecoder chat
```

A provider and model can be selected when starting a session:

```bash
bluecoder chat --provider mistral --model <model>
```

The CLI is intended to support streaming responses and provider-aware model selection.

---

## 🖥️ Desktop

The desktop application is built with **Tauri**.

The UI will provide a graphical interface for:

* Adding providers
* Managing API keys
* Discovering models
* Selecting default providers
* Selecting default models
* Testing connections
* Managing configuration

The desktop application and CLI are designed to share the same configuration rather than becoming two separate systems.

---

## 🔐 Security

API keys are sensitive credentials.

BlueCoder should never expose or commit API keys to the repository.

```text
✓ Environment variables
✓ Secure credential storage
✓ Masked credentials in UI
✗ API keys inside source code
✗ API keys inside Git commits
✗ API keys inside logs
```

> **Never commit your API keys to Git.**

---

## 🗺️ Roadmap

### Core

* [ ] Provider management
* [ ] Model management
* [ ] Secure API key management
* [ ] Provider connection testing
* [ ] Shared configuration system

### CLI

* [ ] Complete Nim CLI
* [ ] Interactive chat
* [ ] Streaming responses
* [ ] Model selection
* [ ] Provider selection
* [ ] Conversation history

### Desktop

* [ ] Tauri desktop interface
* [ ] Provider management UI
* [ ] Model management UI
* [ ] API key management UI
* [ ] Configuration editor

### Intelligence

* [ ] Intelligent model routing
* [ ] Provider fallback system
* [ ] Automatic provider selection
* [ ] Model capability detection
* [ ] Usage-aware routing

---

## 🚀 Getting Started

Clone the repository:

```bash
git clone git@github.com:YOUR-USERNAME/bluecoder.git
cd bluecoder
```

> Development instructions will be added as the project reaches a more stable development stage.

---

## 📦 Project Structure

```text
bluecoder/
│
├── cli/
│   └── Nim source
│
├── ui/
│   ├── frontend
│   └── src-tauri
│
├── providers/
│   ├── OpenAI-compatible
│   ├── Anthropic-compatible
│   └── Mistral-compatible
│
└── README.md
```

---

## 🎯 Vision

BlueCoder aims to become a flexible layer between developers and the rapidly growing ecosystem of AI models.

Instead of being locked into a single provider, developers should be able to choose the right model for the right task.

**One interface. Multiple providers. Your models. Your keys.**

---

<div align="center">

### BlueCoder

**Build with the model you want.**

<br>

Made with Nim + Tauri.

</div>
