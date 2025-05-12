# Módulo: `DeeperHub.Security.ResponseSanitizer` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.ResponseSanitizer`

O módulo `DeeperHub.Security.ResponseSanitizer` é responsável por **sanitizar as respostas da API e das páginas web** antes que sejam enviadas aos clientes. Seu principal objetivo é prevenir o vazamento de dados sensíveis ou a inclusão de conteúdo malicioso que poderia ser explorado no lado do cliente (embora o foco principal de XSS seja na entrada, a sanitização de saída é uma defesa adicional).

Este módulo trabalha em conjunto com `DeeperHub.Security.DataMasking` para aplicar regras de mascaramento a dados sensíveis e pode também filtrar ou modificar cabeçalhos HTTP para reforçar a segurança. A ideia é garantir que apenas as informações necessárias e seguras cheguem ao usuário final. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Sanitização do Corpo da Resposta (`sanitize_response/2`):**
    *   Analisar o corpo da resposta (JSON, HTML, etc.) e aplicar regras de sanitização.
    *   Integrar com `DeeperHub.Security.DataMasking` para mascarar campos sensíveis identificados em respostas JSON ou estruturas de dados antes da serialização.
    *   Para respostas HTML (embora menos comum para APIs puras), aplicar sanitização XSS como uma camada de defesa adicional, mesmo que os templates já devam fazer escaping.
*   **Filtragem de Campos Sensíveis (`filter_sensitive_fields/2`):**
    *   Remover ou substituir campos explicitamente marcados como sensíveis e que não deveriam ser expostos em uma determinada resposta de API, mesmo que o usuário tenha permissão para a entidade principal.
*   **Sanitização de Cabeçalhos HTTP (`sanitize_headers/2`):**
    *   Remover ou modificar cabeçalhos HTTP de resposta que possam vazar informações sensíveis sobre o servidor ou a aplicação (ex: `Server`, `X-Powered-By`, versões detalhadas de software).
    *   Garantir que cabeçalhos de segurança (CSP, HSTS, etc., gerenciados por outros módulos como `XssProtection` ou um plug de segurança HTTP) estejam corretamente configurados e não sejam sobrescritos indevidamente.
*   **Configurabilidade de Regras de Sanitização:**
    *   Permitir a definição de quais campos são sensíveis por tipo de resposta ou endpoint.
    *   Configurar o comportamento da sanitização (remover campo, mascarar, substituir por placeholder).
*   **Integração com `Core.APIResponder`:**
    *   Potencialmente, ser chamado pelo `APIResponder` antes de serializar a resposta final para o cliente.
*   **Observabilidade:**
    *   Registrar métricas sobre o número de respostas sanitizadas e os tipos de dados modificados.
    *   Logar quando dados sensíveis são ativamente removidos ou mascarados de uma resposta.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.ResponseSanitizer` (Fachada Pública / Módulo Funcional):**
    *   Ponto de entrada para as funcionalidades de sanitização de respostas.
    *   Contém a lógica para orquestrar a sanitização do corpo e dos cabeçalhos.
    *   **Interações:**
        *   `DeeperHub.Security.DataMasking`: Para aplicar regras de mascaramento a campos específicos.
        *   `DeeperHub.Core.ConfigManager` / `SecurityPolicyManager`: Para obter a lista de campos sensíveis por contexto, cabeçalhos a serem removidos/modificados, e outras políticas de sanitização.
        *   `DeeperHub.Core.Logger` e `Core.Metrics`: Para observabilidade.
2.  **Configurações (via `Core.ConfigManager` / `SecurityPolicyManager`):**
    *   Listas de chaves sensíveis globais e por endpoint/tipo de resposta.
    *   Lista de cabeçalhos HTTP a serem removidos ou com valores fixos.
    *   Padrões de sanitização para diferentes tipos de conteúdo.

### 3.2. Estrutura de Diretórios (Proposta)

Como este módulo tende a ser mais funcional e depende fortemente de configurações, pode ser simples:
```
lib/deeper_hub/security/response_sanitizer.ex  # Contém a fachada e a lógica de serviço
```
Se a lógica se tornar muito complexa com diferentes estratégias de sanitização:
```
lib/deeper_hub/security/response_sanitizer/
├── response_sanitizer.ex             # Fachada Pública
│
└── services/
    └── response_sanitizer_service.ex # Lógica principal
```

### 3.3. Decisões de Design Importantes

*   **Integração Transparente:** Idealmente, a sanitização de respostas deve ser integrada de forma transparente no fluxo de resposta da API (ex: através de um Plug Phoenix ou como parte do `APIResponder`).
*   **Performance:** A sanitização não deve adicionar uma sobrecarga significativa à geração de respostas. Regexes ou iterações em grandes estruturas de dados devem ser eficientes.
*   **Configurabilidade Detalhada:** Administradores devem poder configurar facilmente quais campos são considerados sensíveis para diferentes contextos de API sem alterar o código.
*   **Não Substitui a Lógica de Negócio:** O `ResponseSanitizer` não deve ser usado para implementar lógica de autorização de campo (ou seja, decidir se um usuário *pode ver* um campo). Essa decisão pertence à camada de serviço/controller. O sanitizer apenas garante que, se um campo sensível *estiver* presente, ele seja tratado (mascarado/removido) antes de sair.

## 🛠️ 4. Casos de Uso Principais

*   **API Retorna Detalhes do Usuário:**
    *   Um endpoint `/api/v1/users/me` retorna os dados do usuário.
    *   Antes de enviar, `ResponseSanitizer.sanitize_response(user_data_map, opts)` é chamado.
    *   Se `user_data_map` contiver `%{password_hash: \"...\"}`, este campo é removido ou substituído por `\"[FILTERED]\"`. Campos como CPF ou data de nascimento podem ser mascarados usando `DataMasking`.
*   **API de Administração Exibe Lista de Usuários:**
    *   Um endpoint `/admin/api/users` retorna uma lista de usuários.
    *   Para cada usuário na lista, campos como `last_login_ip` ou `email_secundario_nao_verificado` podem ser removidos ou mascarados se a política para essa API de admin assim definir.
*   **Remoção de Cabeçalhos HTTP Padrão:**
    *   O `ResponseSanitizer` (ou um Plug que o utiliza) remove ou modifica cabeçalhos como `Server: Cowboy` ou `X-Powered-By: Elixir/Phoenix` para evitar fingerprinting do servidor.

## 🌊 5. Fluxos Importantes

### Fluxo de Sanitização de uma Resposta JSON de API (Exemplo com Plug)

1.  **Controller Prepara Dados:** O Controller de API prepara um mapa `response_data` para ser enviado como JSON.
2.  **Plug `ResponseSanitizerPlug` (no final do pipeline, antes da serialização JSON):**
    *   Recebe a `conn` e o `response_data` (talvez armazenado em `conn.assigns.response_body` pelo controller).
    *   Chama `DeeperHub.Security.ResponseSanitizer.sanitize_response(response_data, %{context: conn.request_path, endpoint_config_key: \"api.users.get_details\"})`.
3.  **`ResponseSanitizer.sanitize_response/2`:**
    *   Obtém as regras de sanitização para o `context` ou `endpoint_config_key` do `ConfigManager` (ex: lista de campos sensíveis a serem removidos/mascarados).
    *   Itera sobre o `response_data`.
    *   Para campos marcados como sensíveis e que devem ser mascarados, chama `DeeperHub.Security.DataMasking` (ex: `DataMasking.mask_email(value)`).
    *   Para campos marcados como sensíveis e que devem ser removidos, os remove do mapa.
    *   Chama `DeeperHub.Security.ResponseSanitizer.sanitize_headers(conn.resp_headers, opts)` para limpar cabeçalhos.
4.  **Plug `ResponseSanitizerPlug`:**
    *   Atualiza `conn.assigns.response_body` com os dados sanitizados.
    *   Atualiza `conn.resp_headers` com os cabeçalhos sanitizados.
5.  **Serialização e Envio:** O `APIResponder` (ou o renderizador Phoenix) pega os dados sanitizados e os envia para o cliente.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `DeeperHub.Security.ResponseSanitizer.sanitize_response(data :: map() | list() | String.t(), opts :: keyword()) :: {:ok, sanitized_data :: term()} | {:error, term()}`

*   **Descrição:** Sanitiza o corpo de uma resposta. Se for um mapa ou lista, aplica `filter_sensitive_fields` e `DataMasking`. Se for uma string HTML (menos comum para APIs), pode aplicar `XssProtection.sanitize_html`.
*   **`opts`:**
    *   `:content_type` (String.t): Tipo de conteúdo da resposta (ex: `\"application/json\"`, `\"text/html\"`). Influencia a estratégia de sanitização.
    *   `:sensitive_keys` (list(atom() | String.t)): Lista de chaves a serem filtradas/mascaradas se `data` for um mapa/lista. Sobrescreve as configurações globais para esta chamada.
    *   `:masking_options_for_key` (map): `%{key => data_masking_opts}` para aplicar opções de mascaramento específicas por chave.
    *   `:html_sanitize_options` (keyword): Opções para `XssProtection.sanitize_html` se for uma resposta HTML.

### 6.2. `DeeperHub.Security.ResponseSanitizer.filter_sensitive_fields(data :: map() | list(), keys_to_filter :: list(atom() | String.t()), replacement_value :: String.t() | nil) :: map() | list()`

*   **Descrição:** Remove (se `replacement_value` for `nil`) ou substitui os valores das chaves especificadas em `keys_to_filter`.
*   **`replacement_value`:** (Padrão: `\"[FILTERED]\"`)

### 6.3. `DeeperHub.Security.ResponseSanitizer.sanitize_headers(headers :: list({String.t(), String.t()}), opts :: keyword()) :: list({String.t(), String.t()})`

*   **Descrição:** Remove ou modifica cabeçalhos HTTP sensíveis da lista de cabeçalhos de resposta.
*   **`opts`:**
    *   `:headers_to_remove` (list(String.t)): Lista de nomes de cabeçalhos (case-insensitive) a serem completamente removidos.
    *   `:headers_to_overwrite` (map): `%{header_name => new_value}` para sobrescrever valores de cabeçalhos.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :response_sanitizer, :enabled]`** (Boolean): Habilita/desabilita a sanitização de respostas. (Padrão: `true`)
*   **`[:security, :response_sanitizer, :default_sensitive_keys]`** (List de Strings/Atoms): Lista global de chaves que devem ser filtradas/mascaradas em respostas JSON/mapa, a menos que um contexto específico diga o contrário.
    *   Ex: `[\"password_hash\", \"internal_token\", \"user_salt\"]`
*   **`[:security, :response_sanitizer, :default_replacement_value]`** (String): Placeholder padrão para campos filtrados. (Padrão: `\"[FILTERED]\"`)
*   **`[:security, :response_sanitizer, :headers_to_remove_default]`** (List de Strings): Cabeçalhos HTTP que devem ser sempre removidos das respostas.
    *   Ex: `[\"X-Powered-By\", \"Server\", \"X-AspNet-Version\"]`
*   **`[:security, :response_sanitizer, :endpoint_policies, <request_path_pattern>]`** (Map): Políticas específicas por endpoint ou padrão de path.
    *   Ex: `%{ \"/api/v1/users/me\": %{allow_fields: [\"id\", \"email\", \"profile\"], mask_fields: %{cpf: :partial}}, \"/admin/users\": %{remove_fields: [\"password_hash\"]} }`
    *   Isto permite um controle granular sobre o que é exposto em cada API.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para obter políticas e listas de campos sensíveis.
*   `DeeperHub.Core.Logger`: Para logar ações de sanitização.
*   `DeeperHub.Security.DataMasking`: Para aplicar mascaramento específico a tipos de dados.
*   `DeeperHub.Security.XssProtection`: Se for necessário sanitizar respostas HTML.

### 8.2. Bibliotecas Externas

*   Nenhuma específica, mas pode usar bibliotecas de manipulação de mapas/listas eficientes.

## 🤝 9. Como Usar / Integração

*   **Plug Phoenix:** A forma mais comum de integrar é através de um Plug no final do pipeline de API, antes da resposta ser enviada.
    ```elixir
    # lib/deeper_hub_web/plugs/response_sanitizer_plug.ex
    defmodule DeeperHubWeb.Plugs.ResponseSanitizerPlug do
      import Plug.Conn
      alias DeeperHub.Security.ResponseSanitizer

      def init(opts), do: opts

      def call(conn, _opts) do
        # Registrar um before_send para modificar o corpo e cabeçalhos finais
        register_before_send(conn, fn conn_before_send ->
          # Sanitizar corpo (assumindo que está em conn_before_send.resp_body se já foi setado)
          # Esta parte é mais complexa com Phoenix porque o corpo é setado pelo controller.
          # Uma abordagem pode ser ter o APIResponder chamar o sanitizer.
          # Ou, se o corpo for um assign:
          # if assigned_body = conn_before_send.assigns[:response_data_for_client] do
          #   {:ok, sanitized_body} = ResponseSanitizer.sanitize_response(assigned_body, context: conn_before_send.request_path)
          #   conn_before_send = %{conn_before_send | resp_body: Jason.encode!(sanitized_body)} # Exemplo, a serialização real é feita depois
          # end
          
          # Sanitizar Cabeçalhos
          sanitized_headers = ResponseSanitizer.sanitize_headers(conn_before_send.resp_headers)
          
          # Reconstruir conn com headers sanitizados
          # Esta é uma simplificação; a manipulação de resp_headers precisa ser feita com cuidado.
          Enum.reduce(conn_before_send.resp_headers, conn_before_send, fn {key, _val}, c -> delete_resp_header(c, key) end)
          |> Enum.reduce(sanitized_headers, fn {key, val}, c -> put_resp_header(c, key, val) end)
        end)
      end
    end

    # No APIResponder
    defmodule DeeperHub.Core.APIResponder do
      alias DeeperHub.Security.ResponseSanitizer
      # ...
      def send_success(conn, status, data_map) do
        # Supondo que 'data_map' são os dados ANTES de qualquer mascaramento para o cliente
        endpoint_policy_key = # Derivar da conn.request_path ou rota
        {:ok, sanitized_data} = ResponseSanitizer.sanitize_response(data_map, %{policy_key: endpoint_policy_key})
        
        # ... então formatar 'sanitized_data' na estrutura de resposta padrão e enviar ...
        json(conn |> put_status(status), %{status: \"success\", data: sanitized_data})
      end
    end
    ```
    A integração mais limpa para o corpo da resposta é geralmente dentro do `APIResponder` ou uma função de renderização customizada, antes da serialização final.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar `sanitize_response` com diferentes tipos de dados (mapas, listas, strings) e diferentes configurações de `sensitive_keys` e opções de mascaramento.
*   Testar `sanitize_headers` para garantir que os cabeçalhos corretos são removidos/modificados.
*   Verificar a lógica de fallback para políticas de endpoint vs. globais.
*   Localização: `test/deeper_hub/security/response_sanitizer/`.

### 10.2. Métricas

*   `deeper_hub.security.response_sanitizer.responses_processed.count` (tags: `endpoint_pattern`)
*   `deeper_hub.security.response_sanitizer.fields_filtered.count` (tags: `field_key`, `endpoint_pattern`)
*   `deeper_hub.security.response_sanitizer.fields_masked.count` (tags: `field_key`, `masking_type`)
*   `deeper_hub.security.response_sanitizer.headers_removed.count` (tags: `header_name`)

### 10.3. Logs

*   **Nível DEBUG:** Detalhes sobre quais campos/cabeçalhos foram sanitizados em uma resposta específica (cuidado com o volume de logs).
*   **Nível INFO:** Carregamento de novas políticas de sanitização.
*   **Nível WARNING:** Tentativa de sanitizar um tipo de conteúdo não suportado ou configuração de política de sanitização ausente para um endpoint.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :response_sanitizer, :sanitize_body, :stop]`
    *   Metadados: `%{request_path: path, fields_filtered_count: count, fields_masked_count: count}`
*   `[:deeper_hub, :security, :response_sanitizer, :sanitize_headers, :stop]`
    *   Metadados: `%{request_path: path, headers_removed_count: count}`

## ❌ 11. Tratamento de Erros

*   Se a sanitização de uma resposta falhar (ex: erro ao aplicar uma regra de mascaramento complexa), o sistema deve, idealmente, logar o erro e retornar uma resposta de erro genérica para o cliente, em vez de vazar dados não sanitizados ou quebrar a requisição.
*   Falhas ao carregar políticas de sanitização do `ConfigManager` devem levar ao uso de políticas padrão restritivas.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Definição Correta de \"Sensível\":** A eficácia do `ResponseSanitizer` depende inteiramente da correta identificação e configuração de quais campos e cabeçalhos são sensíveis em diferentes contextos. Esta é uma tarefa contínua.
*   **Não Confiar Apenas na Sanitização de Saída:** A sanitização de saída é uma camada de defesa. A lógica de negócio primária não deve carregar ou processar dados sensíveis desnecessariamente, e a autorização de acesso a campos deve ocorrer antes da fase de sanitização.
*   **Complexidade vs. Performance:** Regras de sanitização muito complexas ou a necessidade de inspecionar profundamente grandes volumes de dados de resposta podem impactar a latência.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos endpoints de API ou modificar os dados retornados, revise e atualize as políticas de `ResponseSanitizer` no `ConfigManager` para garantir que nenhum novo dado sensível seja exposto acidentalmente.
*   Mantenha a lista de `default_sensitive_keys` e `headers_to_remove_default` atualizada com as melhores práticas.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Permitir políticas de sanitização baseadas no papel do usuário autenticado (ex: admins veem mais dados que usuários regulares).
*   [ ] Integração com um sistema de \"Data Loss Prevention\" (DLP) mais amplo, se aplicável.
*   [ ] Adicionar a capacidade de \"anotar\" campos em schemas Ecto com metadados sobre sua sensibilidade, para que o `ResponseSanitizer` possa usar essas anotações para aplicar regras automaticamente.
*   [ ] Desenvolver ferramentas de teste que verifiquem automaticamente as respostas da API contra uma lista de padrões de dados sensíveis que não deveriam vazar.

---

*Última atualização: 2025-05-12*

---

Com isso, temos uma boa cobertura da sanitização de respostas.

Para o próximo, que tal `DeeperHub.Core.BackgroundTaskManager` para explorarmos a execução de tarefas assíncronas, ou prefere continuar com algum outro módulo de segurança como `HashingService` ou `AtRestEncryptionService` (que já tocamos um pouco)?"""),
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
                types.Part.from_text(text="""Entendido! Vamos detalhar o `DeeperHub.Core.BackgroundTaskManager`. Este é um componente de infraestrutura vital para executar operações que não precisam bloquear o ciclo de requisição-resposta ou que são de longa duração.

---

