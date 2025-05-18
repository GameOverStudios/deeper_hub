# Módulo: `DeeperHub.Core.Internationalization` 🌍

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.Internationalization`

O módulo `DeeperHub.Core.Internationalization` (referido como `I18n`) é o componente central responsável por fornecer suporte a múltiplos idiomas e localização para todo o sistema DeeperHub. Ele permite que a aplicação apresente textos, datas, números e outros dados formatados de acordo com o locale (idioma e região) do usuário ou do contexto da requisição. O objetivo é garantir uma experiência de usuário localizada e acessível globalmente. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Tradução de Strings:**
    *   Fornecer uma API para buscar traduções de chaves de texto (ex: `t(\"greetings.hello\")`).
    *   Suporte para interpolação de variáveis em strings traduzidas (ex: `t(\"messages.welcome\", name: \"Usuário\")`).
    *   Gerenciamento de plurais (ex: `t(\"items.count\", count: 1)` vs `t(\"items.count\", count: 5)`).
*   **Localização de Datas e Horas:**
    *   Formatar datas e horas de acordo com o locale especificado (ex: \"10/03/2025\" vs \"03/10/2025\").
    *   Parsear datas e horas de strings localizadas.
*   **Localização de Números e Moedas:**
    *   Formatar números com separadores de milhar e decimal apropriados para o locale.
    *   Formatar valores monetários com o símbolo da moeda e formatação correta.
*   **Gerenciamento de Locales:**
    *   Definição de um locale padrão para a aplicação.
    *   Detecção do locale preferido do usuário (ex: via cabeçalho HTTP `Accept-Language`, preferência do usuário, parâmetro de URL).
    *   Capacidade de forçar um locale específico para uma requisição ou processo.
*   **Armazenamento de Traduções:**
    *   Carregar traduções de arquivos de configuração (ex: YAML, JSON, Gettext `.po` files).
    *   Suporte para múltiplos backends de tradução (ex: arquivos locais, banco de dados, serviços de tradução externos).
    *   Cache de traduções para otimizar o desempenho.
*   **Fallback de Traduções:**
    *   Definir um ou mais locales de fallback caso uma tradução não esteja disponível no locale primário.
*   **Extração de Textos Traduzíveis (Ferramentas Auxiliares):**
    *   Fornecer ou integrar com ferramentas que ajudem a extrair strings marcadas para tradução do código-fonte.

## 🏗️ 3. Arquitetura e Design

O `DeeperHub.Core.I18n` provavelmente será uma fachada que utiliza um backend de tradução configurável.

*   **Interface Pública (`DeeperHub.Core.I18n`):** Define as funções principais como `t/2`, `l/3` (para localizar datas/números), `get_locale/0`, `with_locale/2`.
*   **Backend de I18n (ex: `Gettext`, `Exáció` ou uma implementação customizada):**
    *   Responsável por carregar, armazenar e buscar as traduções.
    *   A escolha do backend é configurável.
*   **Módulo de Configuração (`DeeperHub.Core.I18n.Config` ou via `Core.ConfigManager`):**
    *   Armazena o locale padrão, locales disponíveis, caminho para os arquivos de tradução, configuração do backend.
*   **Mecanismo de Detecção de Locale:**
    *   Lógica para determinar o locale a ser usado, possivelmente em um Plug para aplicações web Phoenix, ou através de contexto explícito.
*   **Cache de Traduções:**
    *   Pode utilizar o `DeeperHub.Core.Cache` para armazenar traduções frequentemente acessadas.

**Padrões de Design:**

*   **Fachada (Facade):** Simplifica a interface para o sistema de I18n.
*   **Strategy (Adapter para Backend):** Permite trocar o backend de tradução (Gettext, YAML, etc.) sem alterar a API do `I18n`.

### 3.1. Componentes Principais

*   **`DeeperHub.Core.I18n`:** A fachada principal.
*   **`DeeperHub.Core.I18n.BackendBehaviour` (Novo Sugerido):** Um comportamento que os backends de tradução devem implementar.
*   **`DeeperHub.Core.I18n.Backends.GettextAdapter` (Exemplo):** Implementação usando a biblioteca Gettext.
*   **`DeeperHub.Core.I18n.Locale` (Novo Sugerido):** Módulo para gerenciamento e detecção de locales.
*   **`DeeperHub.Core.I18n.Formatters` (Novo Sugerido):** Módulo contendo lógica para formatação de datas, números e moedas (pode usar bibliotecas como `ex_cldr`).

### 3.3. Decisões de Design Importantes

*   **Escolha do Backend:** A decisão sobre qual backend de tradução usar (Gettext é popular em Elixir) impactará como as traduções são gerenciadas e armazenadas. Gettext oferece boas ferramentas para extração e compilação.
*   **Armazenamento de Locale:** Definir como o locale atual é armazenado e acessado (ex: `Process.put/get`, contexto de Plug) é crucial.
*   **Integração com `Core.ConfigManager`:** Centralizar a configuração do I18n no `ConfigManager` permite flexibilidade.

## 🛠️ 4. Casos de Uso Principais

*   **Exibir Mensagem de Boas-Vindas Localizada:** A API retorna uma mensagem de boas-vindas no idioma do usuário.
    *   `DeeperHub.Core.I18n.t(\"welcome_message\", name: current_user.name)`
*   **Formatar Data em um Email de Notificação:** O módulo `DeeperHub.Notifications` usa `I18n.l(event_date, format: :long)` para formatar uma data de evento no idioma do destinatário.
*   **Validar Entrada de Data de um Formulário:** A API recebe uma data em um formato localizado e usa `I18n.parse_date(input_string)` para convertê-la para um `Date.t()`.
*   **Exibir Preços de Produtos Localizados:** Uma loja virtual dentro do DeeperHub usa `I18n.format_currency(price, currency_code)` para mostrar preços corretamente.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Tradução de uma String:**

1.  Um módulo (ex: Controller da API) chama `DeeperHub.Core.I18n.t(\"my.translation.key\", name: \"Mundo\")`.
2.  `I18n.t/2` determina o locale atual (ex: consultando `DeeperHub.Core.I18n.Locale.current_locale()`).
3.  A chave `\"my.translation.key\"` e o locale são passados para o backend de I18n configurado (ex: `GettextAdapter`).
4.  O `GettextAdapter` busca a tradução nos arquivos `.po` correspondentes ao locale.
    *   Se não encontrada no locale primário, tenta o locale de fallback.
5.  A string traduzida (ex: \"Olá, %{name}!\") é retornada.
6.  `I18n.t/2` realiza a interpolação das variáveis (`name: \"Mundo\"`), resultando em \"Olá, Mundo!\".
7.  A string final é retornada ao chamador.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.Core.I18n.t/2` (Translate)

*   **Descrição:** Busca e retorna uma string traduzida para uma chave, com interpolação opcional.
*   **`@spec`:** `t(key :: String.t() | atom(), bindings :: Keyword.t() | map()) :: String.t()`
    *   Pode também ter uma variação `t/3` com `locale` explícito: `t(key, bindings, locale)`
*   **Parâmetros:**
    *   `key` (String | atom): A chave da tradução (ex: `\"errors.not_found\"` ou `:errors_not_found`).
    *   `bindings` (Keyword.t() | map()): Variáveis para interpolação na string traduzida. (Padrão: `[]`)
*   **Retorno:** A string traduzida e interpolada. Se a chave não for encontrada, retorna a própria chave ou uma string de erro configurável.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    # Supondo que em pt_BR.po: msgid \"labels.greeting\" msgstr \"Olá, %{user}!\"
    name = \"Ana\"
    DeeperHub.Core.I18n.t(\"labels.greeting\", user: name) # => \"Olá, Ana!\"

    # Usando com pluralização (requer configuração no backend Gettext)
    # Supondo: msgid_plural \"%{count} items\" msgstr[0] \"%{count} item\" msgstr[1] \"%{count} itens\"
    DeeperHub.Core.I18n.t(\"items.count\", count: 1) # => \"1 item\"
    DeeperHub.Core.I18n.t(\"items.count\", count: 5) # => \"5 itens\"
    ```

### 6.2. `DeeperHub.Core.I18n.l/3` (Localize)

*   **Descrição:** Formata um valor (data, hora, número) de acordo com o locale atual.
*   **`@spec`:** `l(value :: Date.t() | DateTime.t() | NaiveDateTime.t() | Time.t() | number(), type :: atom(), opts :: Keyword.t()) :: String.t()`
    *   `type` pode ser `:date`, `:time`, `:datetime`, `:number`, `:currency`.
*   **Parâmetros:**
    *   `value`: O valor a ser formatado.
    *   `type`: O tipo de valor a ser formatado.
    *   `opts` (Keyword.t()): Opções de formatação (ex: `format: :long` para datas, `currency: \"BRL\"` para moedas).
*   **Retorno:** A string formatada.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    date = ~D[2025-12-25]
    DeeperHub.Core.I18n.with_locale \"pt-BR\", fn ->
      DeeperHub.Core.I18n.l(date, :date, format: :long) # => \"25 de dezembro de 2025\"
    end

    number = 12345.67
    DeeperHub.Core.I18n.with_locale \"en-US\", fn ->
      DeeperHub.Core.I18n.l(number, :number, precision: 2) # => \"12,345.67\"
    end
    ```

### 6.3. `DeeperHub.Core.I18n.current_locale/0`

*   **Descrição:** Retorna o locale atualmente ativo para o processo/requisição.
*   **`@spec`:** `current_locale() :: String.t()`
*   **Retorno:** O código do locale (ex: \"pt-BR\", \"en-US\").
*   **Exemplo de Uso (Elixir):**
    ```elixir
    locale = DeeperHub.Core.I18n.current_locale()
    Logger.info(\"Current locale: #{locale}\")
    ```

### 6.4. `DeeperHub.Core.I18n.with_locale/2`

*   **Descrição:** Executa uma função dentro de um contexto de locale específico.
*   **`@spec`:** `with_locale(locale :: String.t(), fun :: (() -> any())) :: any()`
*   **Parâmetros:**
    *   `locale` (String): O locale a ser usado.
    *   `fun` (function): A função a ser executada.
*   **Retorno:** O resultado da função `fun`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    DeeperHub.Core.I18n.with_locale \"es-ES\", fn ->
      DeeperHub.Core.I18n.t(\"greetings.hello\") # => \"Hola\"
    end
    ```

## ⚙️ 7. Configuração

O módulo `I18n` é configurado através do `DeeperHub.Core.ConfigManager`.

*   **ConfigManager:**
    *   `[:core, :i18n, :default_locale]`: Locale padrão da aplicação. (Padrão: `\"en-US\"`)
    *   `[:core, :i18n, :available_locales]`: Lista de locales suportados pela aplicação. (Padrão: `[\"en-US\", \"pt-BR\"]`)
    *   `[:core, :i18n, :fallback_locale]`: Locale a ser usado se uma tradução não for encontrada no locale atual. (Padrão: `config :core, :i18n, :default_locale`)
    *   `[:core, :i18n, :backend_module]`: Módulo do backend de tradução (ex: `MyApp.Gettext`). (Padrão: `DeeperHub.Core.I18n.Backends.GettextAdapter`)
    *   `[:core, :i18n, :translations_path]`: Caminho para os arquivos de tradução (relevante para backends baseados em arquivo). (Padrão: `\"priv/gettext\"`)
    *   `[:core, :i18n, :cache_enabled]`: Habilita/desabilita o cache de traduções. (Padrão: `true`)
    *   `[:core, :i18n, :cache_ttl_seconds]`: TTL para o cache de traduções. (Padrão: `3600`)
    *   `[:core, :i18n, :cldr_backend_module]`: Módulo backend CLDR para formatação de datas/números (ex: `MyApp.Cldr`).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para configurações do I18n.
*   `DeeperHub.Core.Cache`: Para cache de traduções (opcional).
*   `DeeperHub.Core.Logger`: Para logar avisos sobre traduções ausentes.

### 8.2. Bibliotecas Externas

*   **`Gettext`** (Comum): Para o sistema de tradução Gettext.
*   **`Exáció`** (Alternativa): Outra biblioteca de I18n para Elixir.
*   **`CLDR`** (ex: `ex_cldr`): Para formatação e parseamento localizado de datas, horas, números e moedas.

## 🤝 9. Como Usar / Integração

Outros módulos que precisam de textos traduzidos ou formatação localizada devem usar as funções da fachada `DeeperHub.Core.I18n`.

**Em Controllers Phoenix (para detectar locale da requisição):**
```elixir
# Em um Plug
defmodule DeeperHubWeb.Plugs.SetLocale do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    # Lógica para detectar o locale (ex: do header Accept-Language, cookie, params)
    locale = determine_locale_from_conn(conn) # Função a ser implementada
    DeeperHub.Core.I18n.set_current_locale_for_process(locale) # Supõe uma função para definir no processo
    conn
  end

  defp determine_locale_from_conn(conn) do
    # ... lógica para extrair locale ...
    # Se não encontrar, usar DeeperHub.Core.I18n.get_default_locale()
    \"pt-BR\" # Exemplo
  end
end

# No endpoint.ex
# plug DeeperHubWeb.Plugs.SetLocale
```

**Em Módulos de Serviço:**
```elixir
defmodule DeeperHub.MyFeatureService do
  alias DeeperHub.Core.I18n

  def process_data(user) do
    # ...
    message = I18n.t(\"feature.success_message\", name: user.name)
    # ...
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários devem verificar a correta busca de traduções, interpolação e formatação para diferentes locales.
*   Verificar o funcionamento do fallback de locales.
*   Testar a detecção de locale em diferentes cenários (headers, params).
*   Localização: `test/deeper_hub/core/i18n/`

### 10.2. Métricas

*   `deeper_hub.core.i18n.translation.lookup.count` (Contador): Número de buscas por tradução. Tags: `locale`, `key`, `status` (:found, :missing, :fallback).
*   `deeper_hub.core.i18n.translation.cache.hit_ratio` (Gauge): Taxa de acerto do cache de traduções.
*   `deeper_hub.core.i18n.formatter.duration_ms` (Histograma): Duração das operações de formatação. Tags: `type` (:date, :number), `locale`.

### 10.3. Logs

*   `Logger.warn(\"Tradução ausente para a chave '#{key}' no locale '#{locale}'\", %{key: key, locale: locale})`
*   `Logger.error(\"Erro ao carregar arquivos de tradução para o locale '#{locale}': #{reason}\", %{locale: locale, error: reason})`

### 10.4. Telemetria

*   `[:deeper_hub, :core, :i18n, :lookup, :start | :stop | :exception]`: Para chamadas a `t/2`.
*   `[:deeper_hub, :core, :i18n, :localize, :start | :stop | :exception]`: Para chamadas a `l/3`.

## ❌ 11. Tratamento de Erros

*   Se uma chave de tradução não for encontrada, o sistema deve retornar a própria chave ou uma string de erro configurável (ex: `\"[MISSING_TRANSLATION: #{key}]\"`), e logar um aviso.
*   Erros ao carregar arquivos de tradução ou ao interagir com o backend de I18n devem ser logados como erros e, se possível, o sistema deve tentar usar o locale de fallback ou o padrão.

## 🛡️ 12. Considerações de Segurança

*   **Interpolação de Strings:** A interpolação de strings de tradução deve ser feita de forma segura para evitar vulnerabilidades de XSS se as traduções puderem conter HTML ou se as variáveis interpoladas vierem de fontes não confiáveis. Geralmente, os frameworks de I18n lidam com o escape, mas é bom estar ciente.
*   **Conteúdo dos Arquivos de Tradução:** Se os arquivos de tradução puderem ser modificados por usuários ou processos não confiáveis, deve-se ter cuidado com o conteúdo que eles podem injetar.

## 🧑‍💻 13. Contribuição

*   Novas traduções devem ser adicionadas aos respectivos arquivos de locale (ex: `priv/gettext/pt_BR/LC_MESSAGES/default.po`).
*   Use chaves de tradução descritivas e organizadas.
*   Ao adicionar funcionalidades que apresentam texto ao usuário, sempre use o `I18n.t/2`.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar uma interface de gerenciamento de traduções (CMS de I18n).
*   [ ] Suporte para tradução em tempo real via API (ex: Google Translate) para locales não cobertos.
*   [ ] Ferramenta para detectar chaves de tradução não utilizadas ou ausentes.
*   [ ] Melhorar a detecção de locale, permitindo que o usuário escolha explicitamente seu idioma na interface.

---

*Última atualização: YYYY-MM-DD*

---

Próximo? Que tal o `Core.InputValidator` ou algum dos módulos de domínio?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, vamos continuar com o README para `DeeperHub.Core.InputValidator`. Este módulo é crucial para a segurança e integridade dos dados.

---

