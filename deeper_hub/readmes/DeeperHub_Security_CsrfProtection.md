# Módulo: `Deeper_Hub.Security.CsrfProtection` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Security.CsrfProtection`

O módulo `Deeper_Hub.Security.CsrfProtection` é responsável por proteger a aplicação Deeper_Hub contra ataques de **Cross-Site Request Forgery (CSRF)**. Um ataque CSRF ocorre quando um site malicioso, email, blog, mensagem instantânea ou programa faz com que o navegador de um usuário autenticado realize uma ação indesejada em um site confiável.

Para mitigar isso, este módulo implementa o padrão de **token sincronizador (Synchronizer Token Pattern)**. Ele gera tokens únicos e imprevisíveis por sessão que são embutidos em formulários e verificados em requisições que modificam o estado (POST, PUT, DELETE, PATCH), garantindo que a requisição se originou da própria aplicação e não de uma fonte externa maliciosa. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Geração de Tokens CSRF (`generate_token/2`):**
    *   Gerar tokens CSRF únicos, seguros e específicos para cada sessão de usuário.
    *   Os tokens devem ser suficientemente aleatórios e difíceis de adivinhar.
    *   Associar tokens a um contexto opcional (ex: nome do formulário) para maior segurança (double submit cookie com token no corpo/header).
*   **Armazenamento e Gerenciamento de Tokens:**
    *   Armazenar o token CSRF esperado de forma segura, tipicamente na sessão do usuário ou em um cookie seguro (HttpOnly, SameSite).
    *   Gerenciar o ciclo de vida dos tokens, incluindo expiração (opcional, mas recomendado) e invalidação.
*   **Validação de Tokens CSRF (`validate_token/3`):**
    *   Verificar se o token CSRF enviado em uma requisição (ex: em um header `X-CSRF-Token` ou campo de formulário `_csrf_token`) corresponde ao token esperado para a sessão do usuário.
    *   Rejeitar a requisição se o token estiver ausente, for inválido ou não corresponder.
*   **Integração com a Aplicação Web (Plugs):**
    *   Fornecer um Plug Phoenix (ex: `CsrfProtectionPlug`) para automatizar a geração e verificação de tokens para rotas relevantes.
    *   Facilitar a inclusão de tokens em formulários HTML (ex: `form_field/2`).
    *   Fornecer tokens para serem incluídos em cabeçalhos de requisições AJAX por aplicações frontend (ex: `security_headers/2`).
*   **Configurabilidade:**
    *   Permitir a configuração do nome do cookie/header/campo de formulário para o token.
    *   Configurar o tempo de vida dos tokens.
    *   Definir quais métodos HTTP requerem verificação CSRF (geralmente todos exceto GET, HEAD, OPTIONS, TRACE).
*   **Invalidação de Tokens:**
    *   Invalidar tokens CSRF após o uso (para tokens de uso único, se aplicável) ou quando a sessão do usuário é encerrada (`invalidate_tokens/1`).
*   **Observabilidade:**
    *   Registrar métricas sobre tokens gerados, validados, falhas de validação.
    *   Logar tentativas de CSRF bloqueadas.
*   **Auditoria:**
    *   Registrar eventos de falha na validação de CSRF no sistema de auditoria.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Security.CsrfProtection` (Fachada Pública):**
    *   Ponto de entrada para as funcionalidades de CSRF.
    *   Delega para o `CsrfProtectionService`.
2.  **`Deeper_Hub.Security.CsrfProtection.Services.CsrfProtectionService` (GenServer ou Módulo Funcional):**
    *   **Responsabilidade:** Lógica principal para geração, armazenamento (se não for puramente na sessão do cliente/cookie) e validação de tokens.
    *   **Estado (se GenServer, para tokens stateful ou estatísticas):** Pode manter um registro de tokens emitidos recentemente ou estatísticas de validação, embora o padrão mais comum seja stateless no backend e o token esperado seja armazenado na sessão do usuário.
    *   **Interações:**
        *   `Deeper_Hub.Auth.SessionManager` ou `Plug.Session`: Para obter/definir o token CSRF esperado na sessão do usuário.
        *   `Deeper_Hub.Shared.Utils.SecurityUtils`: Para gerar bytes aleatórios seguros para os tokens.
        *   `Deeper_Hub.Core.ConfigManager`: Para obter configurações (nome do cookie, TTL, etc.).
3.  **`Deeper_Hub.Security.CsrfProtection.Plug.CsrfProtectionPlug` (Phoenix Plug):**
    *   **Responsabilidade:** Middleware para ser adicionado aos pipelines do Phoenix Router.
    *   **No fluxo de entrada:** Para requisições que modificam estado (POST, PUT, etc.), extrai o token da requisição (header ou corpo) e o valida contra o token na sessão. Se inválido, rejeita a requisição (ex: retorna 403).
    *   **No fluxo de saída (opcional, para garantir que o token esteja sempre disponível):** Pode garantir que um token CSRF seja gerado e enviado ao cliente (ex: em um cookie) se ainda não existir na sessão.
4.  **Funções Helper (em `CsrfProtection` ou em um módulo de views/templates):**
    *   `form_field/2`: Para gerar o campo `<input type=\"hidden\">` em formulários HTML.
    *   `security_headers/2`: Para fornecer o token a ser incluído em headers por clientes JavaScript.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/csrf_protection/
├── csrf_protection.ex                # Fachada Pública
│
├── services/
│   └── csrf_protection_service.ex    # Lógica principal de geração/validação
│
├── plug/                             # (Pode estar em deeper_hub_web/plugs se usando Phoenix)
│   └── csrf_protection_plug.ex
│
└── supervisor.ex                     # Supervisor (se CsrfProtectionService for GenServer)
```
*(Os módulos `CsrfProtectionAdapter` e `CsrfProtectionBehaviour` da documentação original podem ser simplificados se o `CsrfProtectionService` for a implementação principal e a fachada o chamar diretamente.)*

### 3.3. Decisões de Design Importantes

*   **Padrão de Token Sincronizador:** O design mais comum e recomendado é usar o padrão de token sincronizador.
    1.  Na primeira resposta ao cliente (ou quando a sessão é criada), gerar um token CSRF secreto.
    2.  Armazenar este token secreto em um cookie seguro (HttpOnly, SameSite=Lax ou Strict) OU na sessão do servidor.
    3.  Para cada formulário ou requisição AJAX que modifica estado, embutir um token CSRF (que pode ser o mesmo token secreto ou um derivado dele, como um HMAC do token secreto + ID da sessão).
    4.  No servidor, para cada requisição que modifica estado:
        *   Se o token secreto está no cookie: comparar o token do cookie com o token enviado no corpo/header.
        *   Se o token secreto está na sessão do servidor: comparar o token da sessão do servidor com o token enviado no corpo/header.
*   **Stateless vs. Stateful Tokens CSRF no Backend:**
    *   **Stateless (Double Submit Cookie):** O servidor não precisa armazenar o token CSRF. Ele envia um token em um cookie e espera o mesmo token de volta no corpo/header da requisição. Fácil de escalar.
    *   **Stateful (Token na Sessão):** O servidor armazena o token CSRF esperado na sessão do usuário no backend. Mais seguro contra algumas vulnerabilidades de subdomínio, mas requer gerenciamento de sessão no backend.
    *   Para Deeper_Hub, que já tem um `SessionManager`, armazenar o token CSRF esperado na sessão do servidor parece uma abordagem robusta.
*   **Tokens por Requisição vs. Por Sessão:**
    *   **Por Sessão (mais comum):** Um token CSRF é gerado por sessão e é válido para múltiplas requisições dentro dessa sessão.
    *   **Por Requisição (mais seguro, mas mais complexo):** Um novo token é gerado para cada formulário/requisição. Aumenta a complexidade no cliente.
    *   Recomenda-se iniciar com tokens por sessão.
*   **Validação para Métodos Seguros:** A proteção CSRF é crucial para métodos HTTP que alteram estado (`POST`, `PUT`, `DELETE`, `PATCH`). Métodos seguros (`GET`, `HEAD`, `OPTIONS`, `TRACE`) geralmente não precisam de proteção CSRF, pois não devem ter efeitos colaterais.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Submete um Formulário Web:**
    *   Ao renderizar o formulário, `CsrfProtection.form_field/2` é usado para embutir o token CSRF.
    *   Quando o usuário submete o formulário (POST), o token é incluído.
    *   O `CsrfProtectionPlug` intercepta a requisição, extrai o token do formulário e o token da sessão, e os compara. Se forem iguais, a requisição prossegue. Senão, é bloqueada.
*   **Aplicação Frontend (SPA) Envia Requisição AJAX:**
    *   Ao carregar a SPA, o cliente pode solicitar o token CSRF atual (ex: de um endpoint `/api/v1/csrf-token` ou o token é fornecido em um meta tag/cookie não-HttpOnly).
    *   Para cada requisição `POST`, `PUT`, `DELETE`, a SPA inclui o token em um header customizado (ex: `X-CSRF-Token`).
    *   O `CsrfProtectionPlug` no backend verifica este header contra o token na sessão.

## 🌊 5. Fluxos Importantes

### Fluxo de Proteção CSRF para Requisição POST (com token na sessão)

1.  **Cliente (Navegador):**
    *   Usuário acessa uma página com um formulário.
    *   O servidor, ao renderizar a página, garante que um token CSRF (`expected_csrf_token`) está na sessão do usuário e também insere este token (ou um derivado) como um campo oculto no formulário.
2.  **Submissão do Formulário:** Usuário submete o formulário (requisição POST). O navegador envia os cookies da sessão (que podem conter o `expected_csrf_token` se você usar a técnica de cookie também) e os dados do formulário (que incluem o `submitted_csrf_token`).
3.  **`Deeper_Hub.Security.CsrfProtection.Plug.CsrfProtectionPlug` (Backend):**
    *   Intercepta a requisição POST.
    *   Extrai o `expected_csrf_token` da sessão do usuário (via `SessionManager`).
    *   Extrai o `submitted_csrf_token` do corpo do formulário (ou de um header `X-CSRF-Token` para AJAX).
    *   **Validação:** Compara `expected_csrf_token` com `submitted_csrf_token`.
        *   **Match:** A requisição é considerada legítima e prossegue para o controller. Opcionalmente, um novo token CSRF pode ser gerado e atualizado na sessão para a próxima requisição (para tokens de uso único ou rotacionados).
        *   **Mismatch ou Ausente:** A requisição é considerada uma possível tentativa de CSRF. O plug retorna uma resposta de erro (ex: 403 Forbidden) e interrompe o processamento. Um log de segurança/auditoria é gerado.
4.  **Controller (se a validação CSRF passar):** Processa a requisição normalmente.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `Deeper_Hub.Security.CsrfProtection.generate_token(session_id :: String.t(), context :: map() | nil) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Gera (ou recupera da sessão) um token CSRF para a sessão especificada. Se um token já existir na sessão e for válido, pode retorná-lo. Caso contrário, gera um novo, o armazena na sessão e o retorna.
*   **`context`:** Pode ser usado para gerar tokens específicos para diferentes formulários/ações, embora um token por sessão seja mais comum.
*   **Retorno:** O token CSRF como string.

### 6.2. `Deeper_Hub.Security.CsrfProtection.validate_token(session_id :: String.t(), submitted_token :: String.t(), context :: map() | nil) :: :ok | :error`

*   **Descrição:** Valida um token CSRF submetido contra o esperado para a sessão.
*   **Retorno:** `:ok` se válido, `:error` (ou `{:error, :invalid_token}`) se inválido.

### 6.3. `Deeper_Hub.Security.CsrfProtection.form_field(session_id :: String.t(), opts :: keyword()) :: {:ok, String.t()}`

*   **Descrição:** Gera a string HTML para um campo de formulário oculto contendo o token CSRF.
*   **`opts`:** `:field_name` (Nome do campo, padrão: `\"_csrf_token\"`).
*   **Exemplo de Retorno:** `{:ok, \"<input type=\\\"hidden\\\" name=\\\"_csrf_token\\\" value=\\\"random_token_string\\\" />\"}`

### 6.4. `Deeper_Hub.Security.CsrfProtection.get_token_for_header(session_id :: String.t()) :: {:ok, String.t()}` (Nova Sugestão)

*   **Descrição:** Obtém o token CSRF atual para ser usado em um cabeçalho HTTP (ex: `X-CSRF-Token`) por clientes AJAX. Similar a `generate_token/2` mas com a intenção clara de uso em header.

### 6.5. `Deeper_Hub.Security.CsrfProtection.invalidate_tokens(session_id :: String.t()) :: :ok`

*   **Descrição:** Invalida/remove o token CSRF da sessão do usuário (ex: no logout).

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager` e/ou `Deeper_Hub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :csrf_protection, :enabled]`** (Boolean): Habilita/desabilita a proteção CSRF. (Padrão: `true`)
*   **`[:security, :csrf_protection, :token_name_in_session]`** (String): Chave usada para armazenar o token CSRF na sessão do servidor. (Padrão: `\"_csrf_token_secret\"`)
*   **`[:security, :csrf_protection, :form_field_name]`** (String): Nome do campo de formulário esperado. (Padrão: `\"_csrf_token\"`)
*   **`[:security, :csrf_protection, :header_name]`** (String): Nome do cabeçalho HTTP esperado. (Padrão: `\"X-CSRF-Token\"`)
*   **`[:security, :csrf_protection, :methods_to_protect]`** (List de Strings): Métodos HTTP que requerem validação CSRF. (Padrão: `[\"POST\", \"PUT\", \"DELETE\", \"PATCH\"]`)
*   **`[:security, :csrf_protection, :token_lifespan_seconds]`** (Integer | `:session`): Tempo de vida do token CSRF. Se `:session`, vive enquanto a sessão do usuário viver. (Padrão: `:session`)
*   **`[:security, :csrf_protection, :rotate_token_on_get]`** (Boolean): Se um novo token deve ser gerado e retornado em requisições GET (para SPAs que precisam de um token fresco). (Padrão: `false`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging de falhas.
*   `Deeper_Hub.Core.Metrics`: Para métricas de CSRF.
*   `Deeper_Hub.Auth.SessionManager` (ou `Plug.Session`): Para armazenar/recuperar o token CSRF esperado da sessão do usuário.
*   `Deeper_Hub.Shared.Utils.SecurityUtils`: Para geração de tokens aleatórios seguros.
*   `Deeper_Hub.Audit`: Para registrar tentativas de CSRF bloqueadas.

### 8.2. Bibliotecas Externas

*   Nenhuma específica, mas depende do mecanismo de sessão usado (ex: `Plug.Session`).

## 🤝 9. Como Usar / Integração

*   **Com Phoenix:** Adicionar `Deeper_Hub.Security.CsrfProtection.Plug.CsrfProtectionPlug` ao pipeline de rotas que manipulam o estado (tipicamente o pipeline `:browser` se houver formulários web, ou um pipeline `:api_session_protected` para SPAs que usam sessões).
    ```elixir
    # lib/deeper_hub_web/router.ex
    pipeline :browser_csrf do
      plug :accepts, [\"html\"]
      plug :fetch_session
      plug :fetch_live_flash
      plug Deeper_Hub.Security.CsrfProtection.Plug.CsrfProtectionPlug # Adicionar aqui
      plug :protect_from_forgery # Plug padrão do Phoenix, pode ser redundante ou complementar
    end

    scope \"/\", Deeper_HubWeb do
      pipe_through [:browser, :browser_csrf] # Aplicar ao escopo apropriado
      # ... rotas ...
    end
    ```
*   **Em Formulários HTML (Phoenix):**
    ```eex
    <%= form_for @changeset, @action, fn f -> %>
      <%= Deeper_Hub.Security.CsrfProtection.form_field_tag(conn) %> # Helper para o plug padrão do Phoenix
      <%# Ou se usando a API diretamente: %>
      <%# {:ok, csrf_input} = Deeper_Hub.Security.CsrfProtection.form_field(conn.assigns.session_id) %>
      <%# <%= raw csrf_input %> 
      ...
    <% end %>
    ```
*   **Em Clientes JavaScript (SPAs):**
    1.  Obter o token CSRF do backend (ex: de um endpoint `/api/csrf-token` ou de um cookie não-HttpOnly se a política SameSite permitir).
    2.  Incluir o token em um header customizado (ex: `X-CSRF-Token`) para todas as requisições AJAX que modificam estado.

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar se requisições POST/PUT/DELETE sem token CSRF são bloqueadas.
*   Testar se requisições com token CSRF inválido/incorreto são bloqueadas.
*   Testar se requisições com token CSRF válido são permitidas.
*   Testar a geração e invalidação de tokens.
*   Testar o funcionamento do `CsrfProtectionPlug`.
*   Localização: `test/deeper_hub/security/csrf_protection/`.

### 10.2. Métricas

*   `deeper_hub.security.csrf.tokens_generated.count`
*   `deeper_hub.security.csrf.validation.success.count`
*   `deeper_hub.security.csrf.validation.failure.count` (tags: `reason` (`missing_token`, `invalid_token`))
*   `deeper_hub.security.csrf.requests_blocked.count`

### 10.3. Logs

*   **Nível WARNING:** Falha na validação do token CSRF, requisição bloqueada.
*   **Nível INFO:** Token CSRF gerado para nova sessão (se relevante).

### 10.4. Telemetria

*   `[:deeper_hub, :security, :csrf, :validation, :start | :stop | :exception]`
    *   Metadados: `%{path: path, method: method, session_id_present: boolean, token_source: :header | :form | :missing}`
    *   No `:stop`: `%{result: :valid | :invalid | :missing}`

## ❌ 11. Tratamento de Erros

*   Falhas na validação CSRF devem resultar em uma resposta de erro clara para o cliente (ex: 403 Forbidden) e a requisição não deve ser processada.
*   Erros na geração ou armazenamento do token na sessão devem ser logados criticamente, pois podem comprometer a proteção.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Força do Token:** Os tokens CSRF devem ser gerados usando uma fonte de aleatoriedade criptograficamente segura e ter entropia suficiente.
*   **Armazenamento Seguro do Token Esperado:** Se armazenado na sessão do servidor, a segurança do mecanismo de sessão é crucial. Se usando o padrão double-submit cookie, o cookie que armazena o token deve ser HttpOnly (se possível, embora isso impeça o JS de lê-lo para AJAX) e SameSite.
*   **HTTPS:** Sempre usar HTTPS para proteger os tokens CSRF em trânsito.
*   **Não Vazar Tokens:** Tokens CSRF não devem ser expostos em URLs ou logs.
*   **Verificação de `Origin` e `Referer` Headers:** Como uma camada adicional de defesa, verificar esses headers pode ajudar, mas eles não são totalmente confiáveis e não substituem os tokens CSRF.

## 🧑‍💻 13. Contribuição

*   Garantir que o `CsrfProtectionPlug` seja aplicado a todas as rotas relevantes que modificam estado.
*   Assegurar que todos os formulários e chamadas AJAX que modificam estado incluam o token CSRF.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar rotação automática de tokens CSRF após um certo número de requisições ou tempo, mesmo dentro da mesma sessão, para maior segurança.
*   [ ] Adicionar suporte para tokens CSRF específicos por formulário/ação (aumenta a complexidade, mas também a segurança).
*   [ ] Investigar o uso de cabeçalhos como `Sec-Fetch-Site` como um indicador adicional na validação CSRF (para navegadores que suportam).
*   [ ] Fornecer helpers mais robustos para integração com frameworks frontend JavaScript populares.

---

*Última atualização: 2025-05-12*

---

Proteção CSRF é essencial para aplicações web!

O próximo poderia ser `Deeper_Hub.Security.XssProtection` para continuarmos com as defesas contra ataques web comuns, ou prefere outro?"""),
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
                types.Part.from_text(text="""Excelente! Vamos agora detalhar o `Deeper_Hub.Security.XssProtection`, que é fundamental para proteger os usuários contra ataques de Cross-Site Scripting.

---

