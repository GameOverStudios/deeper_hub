# Módulo: `DeeperHub.Core.APIResponder` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Core.APIResponder`

O módulo `DeeperHub.Core.APIResponder` é um componente utilitário central no DeeperHub, responsável por **padronizar a estrutura e o formato de todas as respostas HTTP da API REST**. Ele fornece um conjunto de funções para gerar respostas JSON consistentes para diferentes cenários, incluindo sucessos, erros de aplicação, erros de validação e outras condições.

Ao centralizar a formatação de respostas, o `APIResponder` garante que os clientes da API (frontends, aplicativos móveis, serviços de terceiros) recebam dados de uma maneira previsível e fácil de consumir, melhorando a experiência de integração e reduzindo a complexidade no tratamento de respostas no lado do cliente. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Formatação de Respostas de Sucesso (`format_success/3`):**
    *   Envelopar os dados de sucesso em uma estrutura JSON padrão, incluindo um status (`\"success\"`), os dados principais (`data`), uma mensagem opcional e metadados opcionais (ex: para paginação).
*   **Formatação de Respostas de Erro (`format_error/3`):**
    *   Gerar respostas de erro estruturadas, incluindo um status (`\"error\"`), um motivo ou código de erro, detalhes adicionais e uma mensagem descritiva.
    *   Mapear diferentes tipos de erro internos para códigos de status HTTP apropriados (`error_to_http_status/1`).
*   **Formatação de Erros de Validação (`format_validation_error/2`):**
    *   Formatar especificamente erros de validação (ex: de Ecto.Changesets) em uma estrutura clara que detalhe os campos e as mensagens de erro.
*   **Consistência de Estrutura JSON:**
    *   Garantir que todas as respostas da API sigam um esquema JSON comum (ex: `{\"status\": \"...\", \"data\": ..., \"error\": ..., \"message\": ..., \"meta\": ...}`).
*   **Codificação e Decodificação JSON (Opcional, ou delegação):**
    *   Fornecer funções utilitárias para codificar termos Elixir para JSON (`encode/2`, `encode!/2`) e decodificar JSON para termos Elixir (`decode/2`, `decode!/2`), embora isso possa ser delegado a bibliotecas como `Jason` diretamente nos controllers. A inclusão aqui seria por conveniência e padronização de opções.
*   **Suporte a Padrões de API (Opcional):**
    *   Facilitar a conformidade com padrões de API como JSON:API, se adotado pelo projeto, embora a estrutura padrão descrita seja mais simples.
*   **Integração com Controllers Phoenix:**
    *   Ser facilmente utilizável pelos controllers Phoenix para enviar respostas HTTP (ex: `json(conn, APIResponder.format_success(data))`).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Core.APIResponder` (Módulo Funcional):**
    *   **Responsabilidade:** Contém todas as funções públicas para formatação de respostas.
    *   É stateless e suas funções são puras (dado os mesmos inputs, produzem os mesmos outputs), exceto pela possível geração de timestamps.
    *   **Interações:**
        *   Pode utilizar uma biblioteca JSON como `Jason` internamente para codificação (se essa funcionalidade for incluída aqui).
        *   Pode consultar `DeeperHub.Core.ConfigManager` para formatos de data/hora padrão ou outras preferências de formatação de resposta.

### 3.2. Estrutura de Diretórios (Proposta)

```
lib/deeper_hub/core/api_responder.ex  # Contém todas as funções de formatação
```
Este módulo é tipicamente simples e autocontido, não necessitando de uma estrutura de diretórios complexa, GenServers ou supervisores.

### 3.3. Decisões de Design Importantes

*   **Estrutura de Resposta Padrão:** Definir uma estrutura JSON clara e consistente para todas as respostas. Uma sugestão comum é:
    ```json
    // Sucesso
    {
      \"status\": \"success\", // ou um código HTTP numérico como 200, 201
      \"data\": { /* dados principais */ },
      \"message\": \"Operação realizada com sucesso.\", // opcional
      \"meta\": { \"pagination\": { /* ... */ } } // opcional
    }

    // Erro
    {
      \"status\": \"error\", // ou um código HTTP numérico como 400, 404, 500
      \"error\": {
        \"code\": \"ERROR_CODE_INTERNAL\", // um código de erro da aplicação
        \"message\": \"Uma descrição do erro.\",
        \"details\": { /* informações adicionais sobre o erro, ex: campos de validação */ }
      },
      \"data\": null,
      \"message\": \"Uma descrição do erro.\", // pode ser o mesmo que error.message
      \"meta\": null
    }
    ```
*   **Mensagens de Erro Claras:** Mensagens de erro devem ser úteis para o desenvolvedor que consome a API, mas não devem vazar informações sensíveis do sistema.
*   **Códigos de Status HTTP:** Usar códigos de status HTTP semanticamente corretos é fundamental. O `APIResponder` pode ajudar a mapear erros internos para esses códigos.
*   **Internacionalização (i18n) de Mensagens:** Mensagens de erro e sucesso podem precisar ser traduzidas. O `APIResponder` pode integrar com `DeeperHub.Core.Internationalization` para isso.

## 🛠️ 4. Casos de Uso Principais

*   **Controller Retorna uma Lista de Recursos:**
    *   `UserController` busca uma lista de usuários.
    *   Chama `APIResponder.format_success(list_of_users_maps, \"Usuários listados com sucesso.\", %{total: count})`.
    *   Envia a resposta JSON resultante com status 200.
*   **Controller Cria um Novo Recurso:**
    *   `ServerController` cria um novo servidor.
    *   Chama `APIResponder.format_success(new_server_map, \"Servidor criado com sucesso.\")`.
    *   Envia a resposta JSON resultante com status 201 Created.
*   **Controller Lida com um Erro de Validação:**
    *   `AccountService` retorna `{:error, changeset}`.
    *   Controller chama `APIResponder.format_validation_error(changeset.errors, \"Dados inválidos fornecidos.\")`.
    *   Envia a resposta JSON resultante com status 422 Unprocessable Entity.
*   **Controller Lida com Recurso Não Encontrado:**
    *   `ServerService` retorna `{:error, :not_found}`.
    *   Controller chama `APIResponder.format_error(:not_found, \"O servidor solicitado não existe.\")`.
    *   Determina o status HTTP (404) e envia a resposta.
*   **Controller Lida com Erro Interno:**
    *   Ocorre uma exceção inesperada. Um Plug de tratamento de exceções captura a exceção.
    *   O Plug chama `APIResponder.format_error(:internal_server_error, \"Ocorreu um erro inesperado. Tente novamente mais tarde.\")`.
    *   Envia a resposta JSON com status 500.

## 🌊 5. Fluxos Importantes

### Fluxo de Formatação de Resposta de Sucesso em um Controller Phoenix

1.  **Serviço de Domínio:** Retorna dados para o controller (ex: `{:ok, user_data_map}`).
2.  **Controller:**
    *   Recebe `user_data_map`.
    *   Prepara metadados de paginação, se aplicável.
    *   Chama `formatted_response_body = DeeperHub.Core.APIResponder.format_success(user_data_map, \"Usuário recuperado.\", pagination_meta)`.
    *   Usa a função `json/2` do Phoenix: `json(conn |> put_status(200), formatted_response_body)`.
3.  **Phoenix/Plug:** Serializa `formatted_response_body` para JSON e envia a resposta HTTP.

### Fluxo de Formatação de Resposta de Erro de Validação

1.  **Serviço de Domínio:** Tenta criar/atualizar um recurso e o changeset Ecto é inválido. Retorna `{:error, changeset}`.
2.  **Controller:**
    *   Recebe `{:error, changeset}`.
    *   Extrai os erros: `errors = Ecto.Changeset.traverse_errors(changeset, & MyAppWeb.ErrorHelpers.translate_error/1)`.
    *   Chama `formatted_error_body = DeeperHub.Core.APIResponder.format_validation_error(errors, \"Por favor, corrija os erros indicados.\")`.
    *   Chama `status_code = DeeperHub.Core.APIResponder.error_to_http_status(:validation_error)` (que retornaria 422).
    *   Usa `json(conn |> put_status(status_code), formatted_error_body)`.
3.  **Phoenix/Plug:** Envia a resposta.

## 📡 6. API (Funções Públicas do Módulo)

*(Baseado na documentação original, com ênfase na estrutura de resposta unificada)*

### 6.1. `DeeperHub.Core.APIResponder.format_success(data :: term(), message :: String.t() | nil, meta :: map() | nil) :: map()`

*   **Descrição:** Formata uma resposta de sucesso.
*   **Retorno:** Mapa estruturado para sucesso (ex: `%{status: \"success\", data: data, message: message, meta: meta}`).

### 6.2. `DeeperHub.Core.APIResponder.format_error(error_code :: atom() | String.t(), details :: term() | nil, user_message :: String.t() | nil) :: map()`

*   **Descrição:** Formata uma resposta de erro genérica.
*   **`error_code`:** Um código de erro interno da aplicação (ex: `:resource_not_found`, `\"AUTH_002\"`).
*   **`details`:** Informações técnicas adicionais sobre o erro (evitar vazar dados sensíveis).
*   **`user_message`:** Mensagem amigável para o usuário. Se `nil`, uma mensagem padrão pode ser derivada do `error_code`.
*   **Retorno:** Mapa estruturado para erro (ex: `%{status: \"error\", error: %{code: error_code, message: user_message, details: details}}`).

### 6.3. `DeeperHub.Core.APIResponder.format_validation_error(errors :: map() | list(), user_message :: String.t() | nil) :: map()`

*   **Descrição:** Formata uma resposta específica para erros de validação.
*   **`errors`:** Mapa de erros (ex: `%{field_name: [\"error message\"]}`) ou lista de strings de erro.
*   **Retorno:** Mapa estruturado para erro de validação (ex: `%{status: \"error\", error: %{code: \"VALIDATION_ERROR\", message: user_message, fields: errors_map}}`).

### 6.4. `DeeperHub.Core.APIResponder.error_to_http_status(error_code :: atom() | String.t()) :: integer()`

*   **Descrição:** Mapeia um código de erro interno da aplicação para um código de status HTTP apropriado.
*   **Exemplo:** `:not_found` -> `404`, `:unauthenticated` -> `401`, `:unauthorized` -> `403`, `:validation_error` -> `422`, `:internal_server_error` -> `500`.

### 6.5. `DeeperHub.Core.APIResponder.encode(data :: term(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}` (Opcional)

*   **Descrição:** Wrapper para `Jason.encode/2` com opções padrão do sistema.

### 6.6. `DeeperHub.Core.APIResponder.decode(json_string :: String.t(), opts :: keyword()) :: {:ok, term()} | {:error, term()}` (Opcional)

*   **Descrição:** Wrapper para `Jason.decode/2` com opções padrão do sistema.

## ⚙️ 7. Configuração

Geralmente, este módulo tem poucas configurações diretas, mas pode depender de:

*   `[:core, :api_responder, :default_error_message]` (String): Mensagem de erro padrão se nenhuma específica for fornecida.
*   `[:core, :api_responder, :include_trace_id_in_errors]` (Boolean): Se o `trace_id` (de `DistributedTracing`) deve ser incluído automaticamente em respostas de erro para facilitar a correlação. (Padrão: `false` para prod, `true` para dev).
*   `[:core, :internationalization, :default_locale]` (String): Usado se as mensagens de erro/sucesso forem traduzidas.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.Internationalization` (opcional): Se as mensagens forem traduzidas.
*   `DeeperHub.Core.ConfigManager` (opcional): Para obter configurações de formatação.

### 8.2. Bibliotecas Externas

*   `Jason` (ou outra biblioteca JSON): Se as funções `encode/decode` forem implementadas aqui. Caso contrário, os controllers usariam `Jason` diretamente.

## 🤝 9. Como Usar / Integração

Os controllers Phoenix são os principais consumidores deste módulo.

**Exemplo em um Controller Phoenix:**
```elixir
defmodule DeeperHubWeb.API.V1.UserController do
  use DeeperHubWeb, :controller
  alias DeeperHub.Core.APIResponder
  alias DeeperHub.Accounts

  action_fallback DeeperHubWeb.API.FallbackController # Para tratamento centralizado de erros não capturados

  def show(conn, %{\"id\" => id}) do
    case Accounts.get_user(id) do
      {:ok, nil} ->
        conn
        |> put_status(APIResponder.error_to_http_status(:not_found))
        |> json(APIResponder.format_error(:not_found, nil, \"Usuário não encontrado.\"))
      {:ok, user} ->
        # Poderia haver uma função para transformar a struct User em um mapa seguro para API
        user_map_for_api = MyApp.UserView.render(\"show.json\", %{user: user}) 
        json(conn, APIResponder.format_success(user_map_for_api, \"Usuário recuperado.\"))
      {:error, reason} ->
        conn
        |> put_status(APIResponder.error_to_http_status(:internal_error))
        |> json(APIResponder.format_error(:internal_error, reason, \"Erro ao buscar usuário.\"))
    end
  end

  def create(conn, %{\"user\" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        user_map_for_api = MyApp.UserView.render(\"show.json\", %{user: user})
        conn
        |> put_status(:created) # 201
        |> json(APIResponder.format_success(user_map_for_api, \"Usuário criado com sucesso.\"))
      {:error, changeset} ->
        errors = Ecto.Changeset.traverse_errors(changeset, &MyAppWeb.ErrorHelpers.translate_error/1)
        conn
        |> put_status(APIResponder.error_to_http_status(:validation_error)) # 422
        |> json(APIResponder.format_validation_error(errors, \"Falha na validação.\"))
    end
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar cada função de formatação (`format_success`, `format_error`, `format_validation_error`) com diferentes inputs para garantir que a estrutura JSON de saída seja a esperada.
*   Testar a função `error_to_http_status` com vários códigos de erro.
*   Se as funções `encode/decode` estiverem aqui, testá-las.
*   Localização: `test/deeper_hub/core/api_responder_test.exs`.

### 10.2. Métricas

Este módulo em si geralmente não gera muitas métricas, pois é um utilitário de formatação. As métricas relevantes (taxa de erro da API, status codes) seriam geradas pelo `DeeperHub.API` ou pelos Plugs de HTTP.

### 10.3. Logs

Normalmente, o `APIResponder` não faz logging direto. Os controllers ou o `FallbackController` seriam responsáveis por logar os erros antes de chamar o `APIResponder` para formatar a resposta.

### 10.4. Telemetria

Não aplicável diretamente para um módulo de formatação puro. A telemetria estaria associada ao ciclo de vida da requisição HTTP.

## ❌ 11. Tratamento de Erros

*   As funções de formatação devem ser robustas e não falhar mesmo com entradas inesperadas (ex: `nil` para `data` em `format_success`). Elas devem retornar uma estrutura de erro válida ou uma representação padrão.
*   Falhas na codificação JSON (se feitas aqui) devem ser tratadas e logadas.

## 🛡️ 12. Considerações de Segurança

*   **Não Vazar Informações Sensíveis:** A principal consideração é garantir que as funções `format_error` e `format_validation_error` *não* incluam informações sensíveis do sistema (como stack traces, queries SQL, ou valores de variáveis internas) nas respostas enviadas ao cliente em ambiente de produção. A chave `:details` em `format_error` deve ser usada com cautela.
*   **Consistência:** Manter a estrutura de resposta consistente ajuda a evitar que invasores tentem adivinhar informações com base em variações no formato de erro.

## 🧑‍💻 13. Contribuição

*   Mantenha a estrutura de resposta JSON bem definida e documentada.
*   Ao adicionar novos códigos de erro internos, atualize `error_to_http_status/1` se necessário.
*   Considere a internacionalização das mensagens de usuário.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar suporte mais explícito para o padrão JSON:API se for uma direção desejada para a API.
*   [ ] Integrar mais profundamente com `DeeperHub.Core.Internationalization` para que `user_message` possa ser um código de tradução.
*   [ ] Fornecer uma maneira de configurar a estrutura de resposta padrão (ex: chaves `status`, `data`, `error`) através do `ConfigManager` para maior flexibilidade.
*   [ ] Criar helpers Phoenix para os controllers que combinem a formatação da resposta e o envio da mesma (ex: `respond_success(conn, data, status_code \\\\ 200)`).

---

*Última atualização: 2025-05-12*

---

Este módulo é mais um utilitário, mas fundamental para a experiência do desenvolvedor que consome a API.

Próximo? Que tal `DeeperHub.Shared.Utils` para agruparmos os utilitários gerais, ou prefere um módulo de domínio como `DeeperHub.Accounts` (que já começamos) ou `DeeperHub.UserProfiles` (mencionado na documentação original)?"""),
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
                types.Part.from_text(text="""Ok, vamos agrupar e detalhar os utilitários genéricos que podem ser usados em toda a aplicação sob um namespace `DeeperHub.Shared.Utils`. A documentação original listou vários (`DateUtils`, `FileUtils`, `ListUtils`, `MapUtils`, `SecurityUtils`, `StringUtils`, `ValidationUtils`).

Criaremos um README \"guarda-chuva\" para `DeeperHub.Shared.Utils` e, em seguida, podemos detalhar cada um deles como se fossem submódulos ou arquivos dentro desse contexto. Para este exercício, vou criar um README para o módulo `DeeperHub.Shared.Utils` como um todo, mencionando seus componentes, e depois detalhar um deles, por exemplo, `DeeperHub.Shared.Utils.StringUtils`.

---

