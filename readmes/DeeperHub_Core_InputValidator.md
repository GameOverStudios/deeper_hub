# Módulo: `DeeperHub.Core.InputValidator` 🛡️

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.InputValidator`

O módulo `DeeperHub.Core.InputValidator` é o responsável centralizado por validar e sanitizar todos os dados de entrada que chegam ao sistema DeeperHub, seja através de APIs REST, GraphQL, chamadas de console, ou qualquer outra interface externa. Seu principal objetivo é garantir a integridade, formato e segurança dos dados antes que sejam processados pelas lógicas de negócio, prevenindo uma variedade de ataques como XSS, Injeção de SQL (em um nível básico, complementando proteções mais específicas), e entrada de dados malformados. 😊

Este módulo consolida e expande as funcionalidades que antes poderiam estar dispersas em `Shared.Validation.InputValidator` e `Shared.Validation.InputSanitizer`.

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Validação de Tipos de Dados:**
    *   Verificar se os dados correspondem aos tipos esperados (string, integer, boolean, float, list, map, etc.).
    *   Validação de formatos específicos: email, URL, UUID, data, hora, datetime.
    *   Validação de números: inteiros, floats, ranges (mínimo, máximo).
*   **Validação de Strings:**
    *   Comprimento (mínimo, máximo).
    *   Conformidade com expressões regulares (regex).
    *   Valores permitidos (enumeração).
*   **Sanitização de Dados:**
    *   Remoção ou escape de caracteres HTML/JavaScript perigosos para prevenir XSS.
    *   Normalização de strings (ex: trim de espaços, conversão de case).
    *   Remoção de caracteres de controle ou inválidos.
    *   Oferecer diferentes níveis de sanitização (ex: `strict`, `moderate`, `allow_safe_html`).
*   **Validação de Estruturas (Mapas e Listas):**
    *   Verificar a presença de chaves obrigatórias em mapas.
    *   Validar os tipos dos valores dentro de mapas e listas.
    *   Permitir ou proibir chaves/campos desconhecidos (validação estrita de schema).
    *   Validação de tamanho para listas (número mínimo/máximo de elementos).
*   **Verificação de Padrões Potencialmente Maliciosos (Nível Básico):**
    *   Detecção de padrões comuns de injeção de SQL simples (complementar a outras camadas de proteção).
    *   Detecção de padrões comuns de injeção de comandos shell simples.
*   **Geração de Erros Padronizados:**
    *   Retornar mensagens de erro claras e estruturadas quando a validação falha, indicando o campo, o valor e o motivo da falha.
*   **Suporte a Schemas de Validação:**
    *   Permitir a definição de schemas reutilizáveis para validar estruturas de dados complexas.
    *   Integração com bibliotecas de validação de schema (ex: `Vex`, `Params`, ou schemas baseados em Ecto.Changeset mesmo sem persistência).
*   **Contextualização:**
    *   Permitir que as regras de validação e sanitização possam variar de acordo com o contexto (ex: API pública vs. API interna).

## 🏗️ 3. Arquitetura e Design

O `DeeperHub.Core.InputValidator` atuará como uma fachada que pode utilizar diferentes estratégias ou motores de validação/sanitização.

*   **Interface Pública (`DeeperHub.Core.InputValidator`):** Funções como `validate/3`, `sanitize/3`, `check_format/3`.
*   **Módulos de Validação Específicos (ex: `InputValidator.FormatValidators`, `InputValidator.StringValidators`):** Contêm a lógica para tipos específicos de validação.
*   **Módulos de Sanitização (ex: `InputValidator.Sanitizers.HTMLSanitizer`, `InputValidator.Sanitizers.SQLSanitizer`):** Contêm a lógica para diferentes tipos de sanitização.
*   **Schema de Validação:** Pode ser um mapa Elixir descrevendo as regras, ou integrar-se com structs/changesets Ecto (mesmo para dados não-persistidos) ou bibliotecas de schema.
*   **Integração com `Core.ConfigManager`:** Para obter configurações globais de validação, como listas de tags HTML seguras, níveis de sanitização padrão.
*   **Integração com `Core.Logger`:** Para logar tentativas de entrada de dados maliciosos ou falhas de validação significativas.

**Padrões de Design:**

*   **Fachada (Facade):** Simplifica o uso do sistema de validação.
*   **Strategy (Opcional):** Para diferentes motores de schema de validação ou níveis de sanitização.
*   **Chain of Responsibility (Opcional):** Para aplicar múltiplas regras de validação/sanitização em sequência.

### 3.1. Componentes Principais

*   **`DeeperHub.Core.InputValidator`:** A fachada principal.
*   **`DeeperHub.Core.InputValidator.Schema` (ou integração com Ecto.Schema/Changeset):** Define como as regras de validação são especificadas.
*   **`DeeperHub.Core.InputValidator.Validators`:** Namespace para módulos validadores específicos (ex: `EmailValidator`, `URLValidator`, `NumberValidator`).
*   **`DeeperHub.Core.InputValidator.Sanitizers`:** Namespace para módulos sanitizadores específicos (ex: `HTMLSanitizer`).
*   **`DeeperHub.Core.InputValidator.ErrorFormatter`:** Responsável por formatar erros de validação de forma padronizada.

### 3.3. Decisões de Design Importantes

*   **Escolha da Biblioteca de Schema/Validação:** Decidir se usar uma biblioteca externa (`Vex`, `Params`), alavancar `Ecto.Changeset` para validações de dados não-Ecto, ou construir um sistema de schema próprio. `Ecto.Changeset` é uma escolha poderosa e familiar no ecossistema Elixir.
*   **Níveis de Sanitização:** Definir claramente o que cada nível de sanitização (`:basic`, `:strict`, etc.) implica.
*   **Extensibilidade:** O sistema deve ser facilmente extensível para adicionar novos validadores e sanitizadores customizados.

## 🛠️ 4. Casos de Uso Principais

*   **Validação de Payload de API:** Um controller da API `DeeperHub.API` recebe um payload JSON e usa `InputValidator.validate(payload, user_creation_schema)` antes de passá-lo para o serviço de contas.
*   **Sanitização de Comentário de Usuário:** Antes de exibir um comentário de usuário na interface, o sistema usa `InputValidator.sanitize(comment_text, type: :html, level: :allow_safe_tags)`.
*   **Verificação de Parâmetros de Query:** Um endpoint da API que aceita parâmetros de query usa `InputValidator.validate(conn.query_params, search_filter_schema)` para validar os filtros.
*   **Validação de Argumentos de Comandos do Console:** O `DeeperHub.Console` usa `InputValidator` para validar os argumentos fornecidos aos comandos.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Validação de um Mapa com Schema:**

1.  O chamador invoca `DeeperHub.Core.InputValidator.validate(data_map, schema_definition, opts)`.
2.  O `InputValidator` itera sobre os campos definidos no `schema_definition`.
3.  Para cada campo:
    *   Verifica se é obrigatório e se está presente no `data_map`.
    *   Verifica o tipo de dado do valor fornecido contra o tipo esperado no schema.
    *   Aplica quaisquer outras validações específicas do campo (ex: min/max length para string, range para número, formato regex).
    *   Se a sanitização estiver habilitada (`opts[:sanitize]`), aplica as regras de sanitização configuradas para o tipo/campo.
4.  Se `opts[:strict]` for verdadeiro, verifica se há campos no `data_map` que não estão definidos no `schema_definition` e os marca como erro.
5.  Agrega todos os erros de validação.
6.  Se houver erros, retorna `{:error, formatted_errors}`.
7.  Se não houver erros, retorna `{:ok, validated_and_sanitized_data}`.

## 📡 6. API (Se Aplicável)

### 6.1. `DeeperHub.Core.InputValidator.validate/3`

*   **Descrição:** Valida um conjunto de dados de entrada contra um schema definido e opções.
*   **`@spec`:** `validate(data :: map() | Keyword.t(), schema :: map() | atom(), opts :: Keyword.t()) :: {:ok, map()} | {:error, list()}`
    *   `schema` pode ser um mapa definindo as regras, ou um átomo referenciando um schema pré-definido.
*   **Parâmetros:**
    *   `data` (map | Keyword.t()): Os dados de entrada a serem validados.
    *   `schema` (map | atom): A definição do schema de validação.
    *   `opts` (Keyword.t()): Opções adicionais.
        *   `:strict` (boolean): Se `true`, campos não definidos no schema geram erro. (Padrão: `false`)
        *   `:sanitize` (boolean): Se `true`, aplica sanitização aos campos válidos. (Padrão: `true`)
        *   `:context` (atom | map()): Contexto para validações condicionais.
*   **Retorno:**
    *   `{:ok, validated_data_map}`: Se a validação for bem-sucedida. `validated_data_map` contém os dados validados (e possivelmente sanitizados e com tipos convertidos).
    *   `{:error, errors_list}`: Se a validação falhar. `errors_list` é uma lista de tuplas `{field, message, meta}`.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    user_params = %{\"name\" => \"John Doe\", \"email\" => \"john.doe@example.com\", \"age\" => \"30\"}
    user_schema = %{
      name: [type: :string, required: true, validators: [length: %{min: 2, max: 50}]],
      email: [type: :string, required: true, format: :email],
      age: [type: :integer, required: false, validators: [number: %{gte: 18}]],
      extra_field: [type: :string] # não obrigatório
    }

    opts = [strict: true] # Rejeitará \"extra_field\" se não estiver no schema ou se for opcional e não fornecido

    case DeeperHub.Core.InputValidator.validate(user_params, user_schema, opts) do
      {:ok, valid_user} ->
        # valid_user pode ser %{name: \"John Doe\", email: \"john.doe@example.com\", age: 30}
        IO.inspect(valid_user)
      {:error, errors} ->
        # errors pode ser [{:age, \"must be an integer\", []}, {:extra_field, \"is an unknown field\", []}] (se strict)
        IO.inspect(errors)
    end
    ```

### 6.2. `DeeperHub.Core.InputValidator.sanitize/3`

*   **Descrição:** Aplica regras de sanitização a um dado de entrada.
*   **`@spec`:** `sanitize(data :: String.t() | map() | list(), type :: atom(), opts :: Keyword.t()) :: {:ok, sanitized_data :: any()} | {:error, atom()}`
*   **Parâmetros:**
    *   `data`: O dado a ser sanitizado.
    *   `type` (atom): O tipo de dado/contexto para aplicar a sanitização (ex: `:html`, `:sql_identifier`, `:generic_string`).
    *   `opts` (Keyword.t()): Opções específicas para o tipo de sanitização.
        *   `:level` (atom): Nível de sanitização (ex: `:strict`, `:allow_safe_html`).
*   **Retorno:**
    *   `{:ok, sanitized_data}`: Os dados após a sanitização.
    *   `{:error, reason}`: Se a sanitização falhar.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    html_input = \"<script>alert('XSS');</script><p>Hello</p>\"
    case DeeperHub.Core.InputValidator.sanitize(html_input, :html, level: :strip_all_tags) do
      {:ok, safe_html} -> IO.puts(safe_html) # => \"Hello\"
      {:error, _} -> IO.puts(\"Erro de sanitização\")
    end

    user_comment = \"This is <b>bold</b> and <i>italic</i>.\"
    case DeeperHub.Core.InputValidator.sanitize(user_comment, :html, level: :allow_safe_html, safe_tags: [\"b\", \"i\"]) do
      {:ok, safe_comment} -> IO.puts(safe_comment) # => \"This is <b>bold</b> and <i>italic</i>.\"
      {:error, _} -> IO.puts(\"Erro de sanitização\")
    end
    ```

### 6.3. `DeeperHub.Core.InputValidator.check_format/3`

*   **Descrição:** Verifica se uma string corresponde a um formato esperado.
*   **`@spec`:** `check_format(value :: String.t(), format_type :: atom(), opts :: Keyword.t()) :: :ok | {:error, atom()}`
*   **Parâmetros:**
    *   `value` (String): A string a ser verificada.
    *   `format_type` (atom): O tipo de formato (ex: `:email`, `:url`, `:uuid`, `:date_iso8601`).
    *   `opts` (Keyword.t()): Opções adicionais específicas do formato.
*   **Retorno:**
    *   `:ok`: Se o valor corresponde ao formato.
    *   `{:error, reason}`: Se não corresponder ou houver erro.
*   **Exemplo de Uso (Elixir):**
    ```elixir
    DeeperHub.Core.InputValidator.check_format(\"test@example.com\", :email) # => :ok
    DeeperHub.Core.InputValidator.check_format(\"not-an-email\", :email) # => {:error, :invalid_email_format}
    DeeperHub.Core.InputValidator.check_format(\"2023-10-26\", :date_iso8601) # => :ok
    ```

## ⚙️ 7. Configuração

*   **ConfigManager:**
    *   `[:core, :input_validator, :default_sanitize_level]`: Nível de sanitização padrão se não especificado. (Padrão: `:strict_strip`)
    *   `[:core, :input_validator, :html_safe_tags]`: Lista de tags HTML consideradas seguras para o nível `:allow_safe_html`. (Padrão: `[\"b\", \"i\", \"u\", \"em\", \"strong\", \"p\", \"br\", \"a\"]`)
    *   `[:core, :input_validator, :max_string_length]`: Comprimento máximo padrão para strings, se não especificado no schema. (Padrão: `2048`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter configurações globais de validação.
*   `DeeperHub.Core.Logger`: Para logar tentativas de entrada de dados maliciosos.
*   `DeeperHub.Shared.Utils.StringUtils`, `DeeperHub.Shared.Utils.ValidationUtils`: Podem ser usados internamente para algumas verificações e manipulações.

### 8.2. Bibliotecas Externas

*   Opcionalmente, uma biblioteca de sanitização HTML como `HtmlSanitizeEx`.
*   Opcionalmente, uma biblioteca de schema de validação como `Vex` ou `Params` (se não usar Ecto.Changeset).
*   Biblioteca para validação de formatos específicos se necessário (ex: validação de CPF/CNPJ).

## 🤝 9. Como Usar / Integração

Este módulo deve ser usado na fronteira do sistema, onde os dados externos são recebidos.

**Exemplo em um Controller Phoenix:**
```elixir
defmodule DeeperHubWeb.UserController do
  use DeeperHubWeb, :controller
  alias DeeperHub.Core.InputValidator
  alias DeeperHub.Accounts

  # Schema de validação para criação de usuário
  @user_create_schema %{
    email: [type: :string, required: true, format: :email, sanitizers: [:trim, :downcase]],
    password: [type: :string, required: true, validators: [length: %{min: 8}]],
    full_name: [type: :string, required: true, sanitizers: [:strip_tags, :trim], validators: [length: %{max: 100}]]
  }

  def create(conn, params) do
    case InputValidator.validate(params, @user_create_schema) do
      {:ok, valid_params} ->
        case Accounts.register_user(valid_params) do
          {:ok, _response} ->
            conn |> put_status(:created) |> json(%{data: \"User created\"})
          {:error, changeset} ->
            conn |> put_status(:unprocessable_entity) |> json(%{errors: changeset.errors})
        end
      {:error, errors} ->
        conn |> put_status(:bad_request) |> json(%{errors: errors})
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários extensivos para cada tipo de validador e sanitizador.
*   Testar diferentes cenários de entrada, incluindo dados válidos, inválidos e maliciosos.
*   Verificar a formatação correta das mensagens de erro.
*   Localização: `test/deeper_hub/core/input_validator/`

### 10.2. Métricas

*   `deeper_hub.core.input_validator.validation.attempt.count` (Contador): Número total de validações tentadas. Tags: `schema_name` (se aplicável), `context`.
*   `deeper_hub.core.input_validator.validation.success.count` (Contador): Validações bem-sucedidas. Tags: `schema_name`, `context`.
*   `deeper_hub.core.input_validator.validation.failure.count` (Contador): Validações falhas. Tags: `schema_name`, `context`, `field_name` (para o primeiro erro).
*   `deeper_hub.core.input_validator.sanitization.attempt.count` (Contador): Número de sanitizações tentadas. Tags: `type`, `level`.
*   `deeper_hub.core.input_validator.malicious_pattern.detected.count` (Contador): Detecções de padrões maliciosos (SQLi, XSS). Tags: `pattern_type`.

### 10.3. Logs

*   `Logger.warning(\"Falha na validação de entrada\", %{schema: schema_name, errors: errors, input_preview: preview})`
*   `Logger.error(\"Padrão malicioso detectado na entrada\", %{pattern_type: type, input_preview: preview, source_ip: ip})`

### 10.4. Telemetria

*   `[:deeper_hub, :core, :input_validator, :validate, :start | :stop | :exception]`
*   `[:deeper_hub, :core, :input_validator, :sanitize, :start | :stop | :exception]`

## ❌ 11. Tratamento de Erros

*   A função `validate/3` retorna `{:error, list_of_errors}` com detalhes sobre cada campo que falhou na validação.
*   A função `sanitize/3` retorna `{:error, reason}` se um erro irrecuperável ocorrer durante a sanitização.
*   Erros de formato em `check_format/3` retornam `{:error, :invalid_<format_type>_format}`.

## 🛡️ 12. Considerações de Segurança

*   **Defesa em Profundidade:** Este módulo é uma camada importante de defesa, mas não deve ser a única. Proteções específicas (ex: Ecto para SQLi, CSP para XSS) ainda são necessárias.
*   **Níveis de Sanitização:** A escolha do nível de sanitização deve ser cuidadosa. Sanitização muito agressiva pode corromper dados válidos, enquanto sanitização muito permissiva pode deixar passar vetores de ataque.
*   **Atualização de Regras:** As regras de detecção de padrões maliciosos e listas de tags seguras devem ser mantidas atualizadas.
*   **Não Confie na Entrada do Cliente:** Sempre valide e sanitize os dados no backend, mesmo que haja validação no frontend.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos validadores ou sanitizadores, crie módulos específicos dentro dos namespaces `Validators` ou `Sanitizers`.
*   Garanta que novos componentes sejam cobertos por testes unitários.
*   Siga o padrão de retorno `{:ok, ...}` ou `{:error, ...}`.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar suporte para validação assíncrona (ex: verificar se um email já existe no banco de dados).
*   [ ] Adicionar mais formatos de validação pré-definidos (ex: IBAN, CEP, etc.).
*   [ ] Permitir a definição de mensagens de erro customizadas por schema ou por campo.
*   [ ] Integrar com um serviço de análise de conteúdo para detectar spam ou conteúdo abusivo.
*   [ ] Permitir a composição de schemas de validação.

---

*Última atualização: YYYY-MM-DD*

---

Como estamos indo? Gostaria de continuar com os módulos do Core ou pular para algum de domínio?"""),
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
                types.Part.from_text(text="""Ótimo! O próximo módulo que sugeri como novo dentro do `Core` foi o `DeeperHub.Core.Internationalization (I18n)`.

Na verdade, já detalhamos este na resposta anterior (foi o segundo que fizemos). Para recapitular brevemente:

**Módulo: `DeeperHub.Core.Internationalization` 🌍**
*   **Visão Geral:** Responsável por fornecer suporte a múltiplos idiomas e localização (tradução de strings, formatação de datas, números, moedas).
*   **Responsabilidades:** Tradução, localização, gerenciamento de locales, armazenamento de traduções, fallback, etc.

Se você quiser que eu gere o README para outro módulo ou revise algum detalhe do `Core.Internationalization`, me diga!

Caso contrário, podemos passar para o próximo módulo que identificamos como faltando um README principal:

*   **`DeeperHub.Audit`**
*   **`DeeperHub.FeatureFlags`**
*   **`DeeperHub.Console`**
*   **`DeeperHub.Biometrics`**
*   **`DeeperHub.ModuleInspector`**
*   **`DeeperHub.GeoIP`**
*   **`DeeperHub.Mailer`**

Qual deles você gostaria de abordar agora? Ou prefere que eu siga a ordem?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""vai na ordem, e mostre todos os qwue faltaram ate o fim
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Entendido! Vamos seguir a ordem dos módulos de aplicação/domínio que identificamos como faltando um README principal.

Começando com `DeeperHub.Audit`.

---

