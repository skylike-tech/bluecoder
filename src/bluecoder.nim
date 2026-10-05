import std/[httpclient, json, os, strutils, tables]

const
  ConfigDir = getHomeDir() / ".config" / "bluecoder"
  ConfigFile = ConfigDir / "config.json"

type
  ProviderType = enum
    ptOpenAI
    ptAnthropic
    ptMistral

  Provider = object
    name: string
    kind: ProviderType
    baseUrl: string
    apiKeyEnv: string
    models: seq[string]

  Config = object
    providers: seq[Provider]
    defaultProvider: string
    defaultModel: string


proc kindToString(kind: ProviderType): string =
  case kind
  of ptOpenAI:
    "openai"
  of ptAnthropic:
    "anthropic"
  of ptMistral:
    "mistral"


proc stringToKind(value: string): ProviderType =
  case value.toLowerAscii()
  of "openai":
    ptOpenAI
  of "anthropic":
    ptAnthropic
  of "mistral":
    ptMistral
  else:
    raise newException(
      ValueError,
      "Unknown provider type: " & value
    )


proc normalizedUrl(url: string): string =
  var normalized = url.strip()

  while normalized.endsWith("/"):
    normalized.setLen(normalized.len - 1)

  normalized


proc apiUrl(provider: Provider; path: string): string =
  let base = normalizedUrl(provider.baseUrl)
  let cleanPath = path.strip(chars = {'/'})

  if base.endsWith("/v1"):
    return base & "/" & cleanPath

  base & "/v1/" & cleanPath


proc ensureConfigDir() =
  if not dirExists(ConfigDir):
    createDir(ConfigDir)


proc providerToJson(provider: Provider): JsonNode =
  result = %*{
    "name": provider.name,
    "type": kindToString(provider.kind),
    "url": provider.baseUrl,
    "apiKeyEnv": provider.apiKeyEnv,
    "models": provider.models
  }


proc providerFromJson(node: JsonNode): Provider =
  result.name = node["name"].getStr()
  result.kind = stringToKind(node["type"].getStr())
  result.baseUrl = node["url"].getStr()

  if node.hasKey("apiKeyEnv"):
    result.apiKeyEnv = node["apiKeyEnv"].getStr()
  else:
    result.apiKeyEnv = ""

  result.models = @[]

  if node.hasKey("models") and node["models"].kind == JArray:
    for model in node["models"]:
      if model.kind == JString:
        result.models.add(model.getStr())


proc saveConfig(config: Config) =
  ensureConfigDir()

  var providers = newJArray()

  for provider in config.providers:
    providers.add(providerToJson(provider))

  let data = %*{
    "providers": providers,
    "defaultProvider": config.defaultProvider,
    "defaultModel": config.defaultModel
  }

  writeFile(ConfigFile, pretty(data))


proc loadConfig(): Config =
  result.providers = @[]
  result.defaultProvider = ""
  result.defaultModel = ""

  if not fileExists(ConfigFile):
    return

  try:
    let data = parseJson(readFile(ConfigFile))

    if data.hasKey("defaultProvider"):
      result.defaultProvider = data["defaultProvider"].getStr()

    if data.hasKey("defaultModel"):
      result.defaultModel = data["defaultModel"].getStr()

    if data.hasKey("providers") and
       data["providers"].kind == JArray:

      for node in data["providers"]:
        result.providers.add(providerFromJson(node))

  except CatchableError as e:
    echo "Warning: could not load config: ", e.msg


proc findProvider(config: Config; name: string): int =
  for i, provider in config.providers:
    if provider.name == name:
      return i

  -1


proc getApiKey(provider: Provider): string =
  if provider.apiKeyEnv.len == 0:
    return ""

  getEnv(provider.apiKeyEnv)


proc newBlueCoderHttpClient(): HttpClient =
  result = newHttpClient()

  result.headers = newHttpHeaders({
    "Content-Type": "application/json",
    "Accept": "application/json"
  })


proc discoverModels(provider: Provider): seq[string] =
  result = @[]

  let apiKey = getApiKey(provider)

  if apiKey.len == 0:
    raise newException(
      ValueError,
      "Environment variable '" &
      provider.apiKeyEnv &
      "' is not set."
    )

  let client = newBlueCoderHttpClient()

  defer:
    client.close()

  client.headers["Authorization"] = "Bearer " & apiKey

  let endpoint = apiUrl(provider, "models")

  let response = client.request(
    endpoint,
    httpMethod = HttpGet
  )

  let body = response.body

  if response.code.int >= 400:
    raise newException(
      IOError,
      "Provider returned " &
      $response.code &
      ": " &
      body
    )

  let data = parseJson(body)

  if not data.hasKey("data"):
    return

  if data["data"].kind != JArray:
    return

  for item in data["data"]:
    if item.hasKey("id"):
      let modelId = item["id"].getStr()

      if modelId.len > 0 and modelId notin result:
        result.add(modelId)


proc testProvider(provider: Provider) =
  let models = discoverModels(provider)

  echo "Provider ", provider.name, " is working."
  echo models.len, " models found."

  for model in models:
    echo "  - ", model


proc addProvider(
  config: var Config;
  name: string;
  kind: ProviderType;
  url: string;
  apiKeyEnv: string
) =
  let existing = findProvider(config, name)

  let provider = Provider(
    name: name,
    kind: kind,
    baseUrl: normalizedUrl(url),
    apiKeyEnv: apiKeyEnv,
    models: @[]
  )

  if existing >= 0:
    config.providers[existing] = provider
    echo "Provider updated: ", name
  else:
    config.providers.add(provider)
    echo "Provider added: ", name

  saveConfig(config)


proc removeProvider(
  config: var Config;
  name: string
) =
  let index = findProvider(config, name)

  if index < 0:
    echo "Provider not found: ", name
    return

  config.providers.delete(index)

  if config.defaultProvider == name:
    config.defaultProvider = ""
    config.defaultModel = ""

  saveConfig(config)

  echo "Provider removed: ", name


proc listProviders(config: Config) =
  if config.providers.len == 0:
    echo "No providers configured."
    return

  echo "Providers:"

  for provider in config.providers:
    var marker = ""

    if provider.name == config.defaultProvider:
      marker = " [default]"

    echo "- ",
      provider.name,
      " (",
      kindToString(provider.kind),
      ")",
      marker

    echo "  URL: ", provider.baseUrl
    echo "  API key: ", provider.apiKeyEnv
    echo "  Models: ", provider.models.len


proc fetchModels(
  config: var Config;
  providerName: string
) =
  let index = findProvider(config, providerName)

  if index < 0:
    echo "Provider not found: ", providerName
    return

  echo "Fetching models from ", providerName, "..."

  let models = discoverModels(config.providers[index])

  config.providers[index].models = models

  saveConfig(config)

  echo models.len, " models saved."


proc listModels(
  config: Config;
  providerName: string
) =
  let index = findProvider(config, providerName)

  if index < 0:
    echo "Provider not found: ", providerName
    return

  let provider = config.providers[index]

  if provider.models.len == 0:
    echo "No models found."
    echo ""
    echo "Run:"
    echo "  ./src/bluecoder models fetch ", providerName
    return

  echo "Models for ", providerName, ":"

  for model in provider.models:
    echo "- ", model


proc setDefault(
  config: var Config;
  providerName: string;
  model: string
) =
  let index = findProvider(config, providerName)

  if index < 0:
    echo "Provider not found: ", providerName
    return

  config.defaultProvider = providerName
  config.defaultModel = model

  saveConfig(config)

  echo "Default set to ",
    providerName,
    "/",
    model


proc openAiChat(
  provider: Provider;
  model: string;
  messages: JsonNode
): string =
  let apiKey = getApiKey(provider)

  if apiKey.len == 0:
    raise newException(
      ValueError,
      "Environment variable '" &
      provider.apiKeyEnv &
      "' is not set."
    )

  let client = newBlueCoderHttpClient()

  defer:
    client.close()

  client.headers["Authorization"] = "Bearer " & apiKey

  let body = %*{
    "model": model,
    "messages": messages
  }

  let endpoint = apiUrl(
    provider,
    "chat/completions"
  )

  let response = client.request(
    endpoint,
    httpMethod = HttpPost,
    body = $body
  )

  let responseBody = response.body

  if response.code.int >= 400:
    raise newException(
      IOError,
      "Provider returned " &
      $response.code &
      ": " &
      responseBody
    )

  let data = parseJson(responseBody)

  if not data.hasKey("choices"):
    raise newException(
      IOError,
      "Provider response has no choices."
    )

  if data["choices"].len == 0:
    raise newException(
      IOError,
      "Provider returned an empty choices array."
    )

  let choice = data["choices"][0]

  if not choice.hasKey("message"):
    raise newException(
      IOError,
      "Provider response has no message."
    )

  let message = choice["message"]

  if not message.hasKey("content"):
    raise newException(
      IOError,
      "Provider response has no content."
    )

  if message["content"].kind == JString:
    return message["content"].getStr()

  $message["content"]


proc anthropicChat(
  provider: Provider;
  model: string;
  messages: JsonNode
): string =
  let apiKey = getApiKey(provider)

  if apiKey.len == 0:
    raise newException(
      ValueError,
      "Environment variable '" &
      provider.apiKeyEnv &
      "' is not set."
    )

  let client = newBlueCoderHttpClient()

  defer:
    client.close()

  client.headers["x-api-key"] = apiKey
  client.headers["anthropic-version"] = "2023-06-01"

  var anthropicMessages = newJArray()
  var systemPrompt = ""

  for message in messages:
    let role = message["role"].getStr()

    if role == "system":
      systemPrompt = message["content"].getStr()
    else:
      anthropicMessages.add(%*{
        "role": role,
        "content": message["content"]
      })

  var body = %*{
    "model": model,
    "max_tokens": 4096,
    "messages": anthropicMessages
  }

  if systemPrompt.len > 0:
    body["system"] = %systemPrompt

  let endpoint =
    normalizedUrl(provider.baseUrl) &
    "/messages"

  let response = client.request(
    endpoint,
    httpMethod = HttpPost,
    body = $body
  )

  let responseBody = response.body

  if response.code.int >= 400:
    raise newException(
      IOError,
      "Provider returned " &
      $response.code &
      ": " &
      responseBody
    )

  let data = parseJson(responseBody)

  if not data.hasKey("content"):
    raise newException(
      IOError,
      "Provider response has no content."
    )

  if data["content"].len == 0:
    raise newException(
      IOError,
      "Provider returned empty content."
    )

  let content = data["content"][0]

  if content.hasKey("text"):
    return content["text"].getStr()

  $content


proc sendChat(
  provider: Provider;
  model: string;
  messages: JsonNode
): string =
  case provider.kind
  of ptOpenAI, ptMistral:
    openAiChat(
      provider,
      model,
      messages
    )

  of ptAnthropic:
    anthropicChat(
      provider,
      model,
      messages
    )


proc removeLastMessage(
  messages: var JsonNode
) =
  if messages.kind != JArray:
    return

  if messages.len <= 1:
    return

  let newMessages = newJArray()

  for i in 0 ..< messages.len - 1:
    newMessages.add(messages[i])

  messages = newMessages


proc clearTerminal() =
  when defined(windows):
    discard execShellCmd("cls")
  else:
    discard execShellCmd("clear")


proc applyStyle(bold, italic, code: bool): string =
  ## Reaplica o estilo atual depois de um reset.
  result = "\e[0m"
  if bold: result.add("\e[1m")
  if italic: result.add("\e[3m")
  if code: result.add("\e[32m")


proc renderInline(text: string): string =
  var
    i = 0
    bold = false
    italic = false
    code = false

  while i < text.len:
    let c = text[i]

    if c == '`':
      code = not code
      result.add(applyStyle(bold, italic, code))
      inc i

    elif code:
      result.add(c)
      inc i

    elif c == '*' and i + 1 < text.len and text[i + 1] == '*':
      bold = not bold
      result.add(applyStyle(bold, italic, code))
      i += 2

    elif c == '*' and
         (italic or (i + 1 < text.len and text[i + 1] notin {' ', '*'})):
      italic = not italic
      result.add(applyStyle(bold, italic, code))
      inc i

    elif c == '[':
      let closeBracket = text.find(']', i + 1)
      if closeBracket >= 0 and
         closeBracket + 1 < text.len and
         text[closeBracket + 1] == '(':
        let closeParen = text.find(')', closeBracket + 2)
        if closeParen >= 0:
          let label = text[i + 1 ..< closeBracket]
          let url = text[closeBracket + 2 ..< closeParen]
          result.add("\e[4;34m" & label & "\e[0m" &
                     "\e[90m (" & url & ")\e[0m" &
                     applyStyle(bold, italic, code))
          i = closeParen + 1
          continue
      result.add(c)
      inc i

    else:
      result.add(c)
      inc i

  result.add("\e[0m")


proc renderMarkdown(input: string): string =
  var
    lines: seq[string] = @[]
    inCodeBlock = false

  for rawLine in input.splitLines():
    let body = rawLine.strip()

    # Blocos de código.
    if body.startsWith("```"):
      inCodeBlock = not inCodeBlock
      if inCodeBlock:
        let lang = body[3 .. ^1].strip()
        let label = if lang.len > 0: " " & lang & " " else: " code "
        lines.add("\e[90m┌─" & label & "──────────────────────────────\e[0m")
      else:
        lines.add("\e[90m└─────────────────────────────────────────\e[0m")
      continue

    if inCodeBlock:
      lines.add("\e[90m│\e[0m \e[32m" & rawLine & "\e[0m")
      continue

    if body.len == 0:
      lines.add("")
      continue

    # Indentação (para listas aninhadas).
    let indent = rawLine.len - rawLine.strip(trailing = false).len
    let pad = " ".repeat(indent)

    # Linha horizontal.
    if body.len >= 3 and
       (body.replace("-", "").len == 0 or
        body.replace("*", "").len == 0 or
        body.replace("_", "").len == 0):
      lines.add("\e[90m" & "─".repeat(48) & "\e[0m")
      continue

    # Títulos.
    var level = 0
    while level < body.len and body[level] == '#':
      inc level

    if level in 1 .. 6 and level < body.len and body[level] == ' ':
      let color =
        case level
        of 1: "1;34"
        of 2: "1;35"
        else: "1;36"
      lines.add("\e[" & color & "m" &
                renderInline(body[level + 1 .. ^1]) & "\e[0m")
      continue

    # Citações.
    if body.startsWith("> "):
      lines.add("\e[90m│\e[0m \e[3m" & renderInline(body[2 .. ^1]) & "\e[0m")
      continue

    # Listas com marcadores.
    if body.len > 2 and body[0] in {'-', '*', '+'} and body[1] == ' ':
      lines.add(pad & "\e[36m•\e[0m " & renderInline(body[2 .. ^1]))
      continue

    # Listas numeradas.
    var d = 0
    while d < body.len and body[d] in {'0' .. '9'}:
      inc d

    if d > 0 and d + 1 < body.len and body[d] == '.' and body[d + 1] == ' ':
      lines.add(pad & "\e[36m" & body[0 ..< d] & ".\e[0m " &
                renderInline(body[d + 2 .. ^1]))
      continue

    # Parágrafo comum.
    lines.add(pad & renderInline(body))

  lines.join("\n").strip(chars = {'\n'})


proc interactiveChat(config: Config) =
  if config.defaultProvider.len == 0:
    echo "No default provider configured."
    echo ""
    echo "Use:"
    echo "  ./src/bluecoder config set-default --provider groq --model MODEL"
    return

  if config.defaultModel.len == 0:
    echo "No default model configured."
    return

  let providerIndex = findProvider(
    config,
    config.defaultProvider
  )

  if providerIndex < 0:
    echo "Default provider not found: ",
      config.defaultProvider
    return

  let provider = config.providers[providerIndex]

  var messages = newJArray()

  messages.add(%*{
    "role": "system",
    "content":
      "You are BlueCoder, an AI coding assistant. " &
      "Help the user with programming and software development."
  })

  echo "BlueCoder chat"
  echo "Provider: ", provider.name
  echo "Model: ", config.defaultModel
  echo "Type /exit or /quit to leave."
  echo "Type /clear to clear the conversation."
  echo "Type /help for commands."
  echo ""

  while true:
    stdout.write("You: ")
    stdout.flushFile()

    let input = stdin.readLine()

    if input.len == 0:
      continue

    let command = input.strip().toLowerAscii()

    if command == "/exit" or
       command == "/quit":

      echo "Bye!"
      break

    if command == "/clear":
      clearTerminal()

      messages = newJArray()

      messages.add(%*{
        "role": "system",
        "content":
          "You are BlueCoder, an AI coding assistant. " &
          "Help the user with programming and software development."
      })

      echo "BlueCoder chat"
      echo "Provider: ", provider.name
      echo "Model: ", config.defaultModel
      echo "Type /exit or /quit to leave."
      echo "Type /clear to clear the conversation."
      echo "Type /help for commands."
      echo ""
      echo "Conversation cleared."
      echo ""

      continue

    if command == "/help":
      echo ""
      echo "/exit  - exit chat"
      echo "/quit  - exit chat"
      echo "/clear - clear conversation"
      echo "/help  - show commands"
      echo ""
      continue

    messages.add(%*{
      "role": "user",
      "content": input
    })

    try:
      echo ""
      echo "Assistant:"
      echo ""

      let answer = sendChat(
        provider,
        config.defaultModel,
        messages
      )

      echo renderMarkdown(answer)
      echo ""

      messages.add(%*{
        "role": "assistant",
        "content": answer
      })

    except CatchableError as e:
      echo ""
      echo "Error: ", e.msg
      echo ""

      removeLastMessage(messages)


proc parseOptions(
  args: seq[string]
): Table[string, string] =
  result = initTable[string, string]()

  var i = 0

  while i < args.len:
    let arg = args[i]

    if arg.startsWith("--"):
      let option = arg[2 .. ^1]
      let equalsPos = option.find('=')

      if equalsPos >= 0:
        let key = option[0 ..< equalsPos]
        let value = option[equalsPos + 1 .. ^1]

        result[key] = value

      else:
        if i + 1 < args.len and
           not args[i + 1].startsWith("-"):

          result[option] = args[i + 1]
          inc i
        else:
          result[option] = ""

    elif arg.startsWith("-") and
         arg.len == 2:

      let key = arg[1 .. ^1]

      if i + 1 < args.len and
         not args[i + 1].startsWith("-"):

        result[key] = args[i + 1]
        inc i
      else:
        result[key] = ""

    inc i


proc printUsage() =
  echo ""
  echo "BlueCoder - AI coding agent"
  echo ""
  echo "Usage:"
  echo ""
  echo "  bluecoder providers list"
  echo "  bluecoder providers add --name NAME --type TYPE --url URL"
  echo "  bluecoder providers remove NAME"
  echo "  bluecoder providers test NAME"
  echo ""
  echo "  bluecoder models fetch PROVIDER"
  echo "  bluecoder models --provider PROVIDER"
  echo ""
  echo "  bluecoder config set-default --provider NAME --model MODEL"
  echo ""
  echo "  bluecoder chat"
  echo ""
  echo "Provider types:"
  echo "  openai"
  echo "  anthropic"
  echo "  mistral"
  echo ""


proc main() =
  var config = loadConfig()
  let args = commandLineParams()

  if args.len == 0:
    printUsage()
    return

  let command = args[0]

  case command

  of "providers":

    if args.len < 2:
      printUsage()
      return

    let subcommand = args[1]

    case subcommand

    of "list":
      listProviders(config)

    of "add":

      if args.len < 3:
        echo "Usage: providers add --name NAME --type TYPE --url URL"
        return

      let options = parseOptions(
        args[2 .. ^1]
      )

      if not options.hasKey("name") or
         not options.hasKey("url") or
         not options.hasKey("type"):

        echo "Required: --name, --url and --type openai|anthropic|mistral"
        return

      let name = options["name"]
      let url = options["url"]
      let typeName = options["type"]

      var apiKeyEnv = ""

      if options.hasKey("key-env"):
        apiKeyEnv = options["key-env"]

      elif options.hasKey("api-key-env"):
        apiKeyEnv = options["api-key-env"]

      else:
        apiKeyEnv =
          "BLUECODER_" &
          name.toUpperAscii() &
          "_API_KEY"

      try:
        let kind = stringToKind(typeName)

        addProvider(
          config,
          name,
          kind,
          url,
          apiKeyEnv
        )

      except CatchableError as e:
        echo "Error: ", e.msg

    of "remove":

      if args.len < 3:
        echo "Usage: providers remove NAME"
        return

      removeProvider(
        config,
        args[2]
      )

    of "test":

      if args.len < 3:
        echo "Usage: providers test NAME"
        return

      let index = findProvider(
        config,
        args[2]
      )

      if index < 0:
        echo "Provider not found: ", args[2]
        return

      try:
        testProvider(
          config.providers[index]
        )

      except CatchableError as e:
        echo "Error: ", e.msg

    else:
      printUsage()


  of "models":

    if args.len >= 2 and
       args[1] == "fetch":

      if args.len < 3:
        echo "Usage: models fetch PROVIDER"
        return

      try:
        fetchModels(
          config,
          args[2]
        )

      except CatchableError as e:
        echo "Error: ", e.msg

    else:
      let options = parseOptions(
        args[1 .. ^1]
      )

      if not options.hasKey("provider"):
        echo "Usage: models --provider PROVIDER"
        return

      listModels(
        config,
        options["provider"]
      )


  of "config":

    if args.len < 2:
      printUsage()
      return

    if args[1] == "set-default":

      let options = parseOptions(
        args[2 .. ^1]
      )

      if not options.hasKey("provider") or
         not options.hasKey("model"):

        echo "Required: --provider and --model"
        return

      setDefault(
        config,
        options["provider"],
        options["model"]
      )

    else:
      printUsage()


  of "chat":
    interactiveChat(config)


  else:
    printUsage()


when isMainModule:
  main()