# Módulo: `DeeperHub.Shared.Utils.ValidationUtils` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Shared.Utils.ValidationUtils`

O módulo `DeeperHub.Shared.Utils.ValidationUtils` fornece um conjunto de **funções utilitárias para validação de formatos de dados comuns e verificação de requisitos básicos**. Ele é usado em várias partes do sistema DeeperHub para garantir que os dados de entrada, antes de serem processados ou persistidos, atendam a certos critérios de formato e presença.

Este módulo foca em validações genéricas e reutilizáveis. Validações mais complexas ou específicas de regras de negócio devem residir nos schemas Ecto dos módulos de domínio ou em serviços de validação dedicados (como `DeeperHub.API.Validation.APIRequestValidator` ou `DeeperHub.Security.Validation.SecurityInputValidation` para contextos específicos). 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Validação de Formatos Comuns:**
    *   Verificar se uma string é um endereço de email válido (formato básico) (`validate_email/1`).
    *   Verificar se uma string é um número de telefone válido (formato básico) (`validate_phone/1`).
    *   Verificar se uma string é uma URL válida (`validate_url/2`).
    *   Verificar se uma string representa uma data/hora válida em um formato específico (`validate_date/3`).
    *   Verificar se uma string representa um número de documento válido (CPF, CNPJ) para um tipo e país (básico) (`validate_document/3`).
    *   Verificar se uma string é um JSON válido (`validate_json/3`).
*   **Validação de Requisitos de Dados:**
    *   Verificar se um valor está presente (não `nil`, não string vazia/em branco) (`validate_required/1`).
    *   Validar a complexidade básica de uma senha (comprimento, presença de tipos de caracteres) (`validate_password/2`). (Nota: Validação de política de senha mais robusta estaria em `DeeperHub.Auth` ou `SecurityPolicyManager`).
    *   Validar o formato e comprimento de um nome de usuário (`validate_username/2`).
*   **Validação de Estrutura de Mapas:**
    *   Verificar se um mapa contém um conjunto específico de chaves obrigatórias (`validate_map/2`).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

*   **`DeeperHub.Shared.Utils.ValidationUtils` (Módulo Funcional):**
    *   Contém todas as funções de utilidade para validação.
    *   Utiliza regex e funções de string/tipo do Elixir para as verificações.
    *   Pode, para validações mais complexas (como documentos específicos de país), delegar para bibliotecas especializadas se necessário, mas o objetivo aqui é manter utilitários leves.

### 3.2. Estrutura de Diretórios

```
shared/utils/validation_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Retorno Consistente:** As funções de validação devem ter um padrão de retorno consistente, por exemplo:
    *   Retornar `true`/`false` para verificações simples.
    *   Retornar `{:ok, validated_value}` ou `{:error, reason_atom | {reason_atom, details_map}}` para validações que podem retornar o valor validado ou detalhes do erro. A documentação original usava ambos os estilos. Padronizar em `{:ok, ...} | {:error, ...}` pode ser mais robusto.
*   **Regex Simples vs. Bibliotecas:** Para validações como email e URL, usar regex simples e bem testadas para formatos comuns. Para validações muito complexas ou que exigem conformidade estrita com RFCs, o uso de bibliotecas dedicadas pode ser considerado, mas adiciona dependências.
*   **Não Substitui Validação de Schema Ecto:** Este módulo complementa, mas não substitui, as validações realizadas por Ecto Changesets nos módulos de domínio. Ele é útil para validações rápidas em camadas de serviço ou antes de criar changesets.
*   **Configurabilidade Limitada:** Algumas funções podem aceitar opções (ex: `min_length` para senha), mas configurações globais para esses utilitários são menos comuns e geralmente pertencem a módulos de política.

## 🛠️ 4. Casos de Uso Principais

*   **Validação de Formulário na API antes de criar Changeset:**
    *   Um controller recebe `params = %{\"email\" => \"test\", \"password\" => \"123\"}`.
    *   Antes de passar para `Accounts.create_user(params)`:
        ```elixir
        if !ValidationUtils.validate_email(params[\"email\"]), do: errors = [email: \"Formato inválido\" | errors]
        if !ValidationUtils.validate_password(params[\"password\"], min_length: 8), do: errors = [password: \"Muito curta\" | errors]
        ```
*   **Verificar se um campo obrigatório foi enviado:**
    *   `if !ValidationUtils.validate_required(params[\"user_agent\"]), do: # tratar erro`
*   **Sanitizar e depois validar uma URL de um perfil externo:**
    *   `clean_url = SomeSanitizer.sanitize_url(user_input_url)`
    *   `case ValidationUtils.validate_url(clean_url, allowed_protocols: [\"http\", \"https\"]) do ... end`

## 🌊 5. Fluxos Importantes

Não aplicável no mesmo sentido que módulos com estado. O fluxo é a execução da função com os dados de entrada e o retorno do resultado da validação.

## 📡 6. API (Funções Públicas do Módulo)

*(Baseado na documentação original, com sugestão de padronizar retornos para `{:ok, ...} | {:error, ...}` onde apropriado para maior clareza do que apenas booleanos)*

### 6.1. `DeeperHub.Shared.Utils.ValidationUtils.validate_email(email :: String.t() | nil) :: {:ok, String.t()} | {:error, :invalid_format | :missing}`

*   **Descrição:** Valida o formato básico de um endereço de email.
*   **Retorno:** `{:ok, email}` se válido, `{:error, :missing}` se `nil` ou vazio, `{:error, :invalid_format}` para outros erros.

### 6.2. `DeeperHub.Shared.Utils.ValidationUtils.validate_phone(phone :: String.t() | nil, opts :: keyword()) :: {:ok, String.t()} | {:error, :invalid_format | :missing}`

*   **Descrição:** Valida o formato básico de um número de telefone.
*   **`opts`:** `:country_code` (atom, ex: `:BR`, `:US` para aplicar regras específicas de comprimento/formato, se implementado), `:min_digits` (integer).
*   **Retorno:** `{:ok, phone}` se válido, `{:error, :missing}` se `nil` ou vazio, `{:error, :invalid_format}` ou `{:error, :too_short}`.

### 6.3. `DeeperHub.Shared.Utils.ValidationUtils.validate_url(url :: String.t() | nil, opts :: keyword()) :: {:ok, String.t()} | {:error, :invalid_format | :missing | :disallowed_protocol}`

*   **Descrição:** Valida o formato de uma URL.
*   **`opts`:**
    *   `:require_protocol` (boolean, Padrão: `true`).
    *   `:allowed_protocols` (list(String.t), Padrão: `[\"http\", \"https\"]`).

### 6.4. `DeeperHub.Shared.Utils.ValidationUtils.validate_date(date_string :: String.t() | nil, format_string :: String.t() \\\\ \"YYYY-MM-DD\", opts :: keyword()) :: {:ok, Date.t() | NaiveDateTime.t()} | {:error, :invalid_format | :missing | :invalid_date}`

*   **Descrição:** Valida se `date_string` corresponde ao `format_string` e representa uma data/hora válida. Tenta converter para `NaiveDateTime` ou `Date`.
*   **`opts`:** `:return_type` (`:naive_datetime`, `:date`, `:datetime_utc` - este último exigiria timezone info ou assumiria UTC).

### 6.5. `DeeperHub.Shared.Utils.ValidationUtils.validate_document(doc_string :: String.t() | nil, type :: atom(), opts :: keyword()) :: {:ok, String.t()} | {:error, :invalid_format | :missing | :invalid_checksum}`

*   **Descrição:** Validação básica para números de documento (ex: CPF, CNPJ). A lógica de checksum seria simplificada ou delegada se complexa.
*   **`type`:** Ex: `:cpf_br`, `:cnpj_br`.
*   **`opts`:** `:validate_checksum` (boolean, Padrão: `true`).

### 6.6. `DeeperHub.Shared.Utils.ValidationUtils.validate_password(password :: String.t() | nil, opts :: keyword()) :: {:ok, String.t()} | {:error, atom()}`

*   **Descrição:** Valida a complexidade básica de uma senha.
*   **`opts`:** `:min_length` (Padrão: 8), `:require_uppercase` (Padrão: `true`), `:require_lowercase` (Padrão: `true`), `:require_digit` (Padrão: `true`), `:require_special` (Padrão: `false`).
*   **Retorno de Erro:** Ex: `:missing`, `:too_short`, `:missing_uppercase`, `:missing_lowercase`, `:missing_digit`, `:missing_special`.

### 6.7. `DeeperHub.Shared.Utils.ValidationUtils.validate_username(username :: String.t() | nil, opts :: keyword()) :: {:ok, String.t()} | {:error, atom()}`

*   **Descrição:** Valida o formato e comprimento de um nome de usuário.
*   **`opts`:** `:min_length` (Padrão: 3), `:max_length` (Padrão: 30), `:allowed_chars_regex` (Padrão: `~r/^[a-zA-Z0-9_]+$/u`).
*   **Retorno de Erro:** Ex: `:missing`, `:too_short`, `:too_long`, `:invalid_chars`.

### 6.8. `DeeperHub.Shared.Utils.ValidationUtils.validate_required(value :: term()) :: boolean()`

*   **Descrição:** Verifica se um valor é considerado \"presente\" (não `nil`, não string vazia, não string só com espaços).
*   **Retorno:** `true` ou `false`.

### 6.9. `DeeperHub.Shared.Utils.ValidationUtils.validate_map_keys(map_data :: map(), required_keys :: list(atom() | String.t()), opts :: keyword()) :: {:ok, map()} | {:error, {:missing_keys, list()} | :not_a_map}` (Renomeado de `validate_map`)

*   **Descrição:** Verifica se `map_data` é um mapa e contém todas as `required_keys`.
*   **`opts`:** `:allow_nil_values_for_required_keys` (boolean, Padrão: `false` - ou seja, a chave deve existir E ter um valor não-nil se esta opção for false).

## ⚙️ 7. Configuração

Geralmente, os padrões para validações (ex: comprimento mínimo de senha, regex de username) podem ser configurados via `Core.ConfigManager` para permitir ajustes sem alterar o código.

*   `[:shared, :utils, :validation, :password, :min_length]`
*   `[:shared, :utils, :validation, :username, :allowed_chars_regex]`
*   ... etc.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager` (para obter padrões configuráveis).

### 8.2. Bibliotecas Externas

*   Pode usar bibliotecas para validações mais complexas se forem adicionadas (ex: `ExCpfCnpj` para documentos brasileiros, `NimbleParsec` para formatos customizados). Para o básico, funções de `String`, `Regex` e `Integer` do Elixir são suficientes.

## 🤝 9. Como Usar / Integração

Em controllers ou serviços, antes de processar dados de entrada ou criar changesets Ecto.

```elixir
defmodule MyApp.RegistrationController do
  alias DeeperHub.Shared.Utils.ValidationUtils

  def create(conn, %{\"user\" => user_params}) do
    with {:ok, email} <- ValidationUtils.validate_email(user_params[\"email\"]),
         {:ok, pass}  <- ValidationUtils.validate_password(user_params[\"password\"], min_length: 10),
         {:ok, uname} <- ValidationUtils.validate_username(user_params[\"username\"]) do
      # Prossiga com a criação do usuário com email, pass, uname
      # ...
    else
      {:error, :missing} -> # Lidar com campo ausente
      {:error, :invalid_format} -> # Lidar com email/username inválido
      {:error, :too_short} -> # Lidar com senha curta
      # ... outros erros ...
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários exaustivos para cada função de validação, cobrindo:
    *   Entradas válidas.
    *   Diferentes tipos de entradas inválidas (formato, comprimento, ausência, etc.).
    *   Casos de borda.
    *   Comportamento com `nil` e strings vazias.
    *   Efeito das diferentes opções (`opts`).
*   Localização: `test/deeper_hub/shared/utils/validation_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Geralmente não aplicável para um módulo de utilitários puros. O chamador seria responsável por logar/metricar falhas de validação se relevante para o seu contexto.

## ❌ 11. Tratamento de Erros

*   As funções devem retornar tuplas `{:ok, valid_value}` ou `{:error, reason_atom | {reason_atom, details}}` para permitir que o chamador trate os erros de forma programática.
*   Evitar levantar exceções para entradas inválidas, a menos que seja um erro de programação (ex: tipo de argumento incorreto para a própria função de validação).

## 🛡️ 12. Considerações de Segurança

*   **Não é uma Defesa Completa:** Estas validações de formato são uma primeira linha de defesa, mas não substituem a sanitização de entrada (para XSS, SQLi) ou validações de lógica de negócio mais profundas.
*   **Regexes:** Se usar regexes, garantir que sejam bem testadas e não vulneráveis a ReDoS (Regular Expression Denial of Service).
*   **Falsos Negativos/Positivos:** Estar ciente das limitações das validações baseadas em regex (ex: `validate_email` pode permitir alguns emails tecnicamente inválidos ou rejeitar alguns válidos, mas obscuros).

## 🧑‍💻 13. Contribuição

*   Ao adicionar novas funções de validação, garanta que sejam genéricas e que o comportamento de erro seja consistente com as existentes.
*   Adicione testes unitários completos.
*   Documente claramente os formatos esperados e as opções.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar mais validadores para tipos comuns (ex: UUID, ISBN, IBAN).
*   [ ] Para validações mais complexas (ex: CPF/CNPJ com lógica de checksum completa), considerar a integração de bibliotecas dedicadas ou a criação de validadores mais robustos.
*   [ ] Permitir que as mensagens de erro retornadas por `{:error, reason}` sejam códigos de i18n para tradução na camada de apresentação.
*   [ ] Criar um validador `validate_number_range(number, min, max, opts)`.

---

*Última atualização: 2025-05-12*

---

Com isso, cobrimos um bom conjunto de utilitários.

Próximo? Podemos detalhar `DeeperHub.Shared.Utils.FileUtils` e `SecurityUtils` para completar os Utils, ou prefere agora ir para um módulo de domínio como `DeeperHub.OAuth` ou `DeeperHub.MFA`?"""),
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
                types.Part.from_text(text="""Ok, vamos continuar com os utilitários e detalhar o `DeeperHub.Shared.Utils.FileUtils`. Este módulo é útil se a sua aplicação DeeperHub precisar interagir diretamente com o sistema de arquivos do servidor.

---

