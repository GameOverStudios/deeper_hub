# Documentação Deeper: Permalinks e Roteamento Base da API (`sys_permalinks`)

Este documento discute como o sistema \"Deeper\" lidará com o conceito de permalinks (URLs amigáveis) originário do UNA, armazenado na tabela `sys_permalinks`, e como isso se relaciona com o roteamento da API RESTful implementada com Phoenix.

**Distinção Importante:**
*   **UNA PHP:** Usa `sys_permalinks` e `sys_rewrite_rules` para traduzir URLs amigáveis (ex: `/m/persons/home`) em chamadas de serviço internas PHP (ex: `page.php?i=bx_persons_home`).
*   **Deeper API (Elixir/Phoenix):** Terá seu próprio sistema de roteamento definido no `router.ex` do Phoenix. Os endpoints da API (ex: `/api/v1/pages?uri=bx_persons_home` ou `/api/v1/profiles/persons/{id}`) serão a interface primária.

**Objetivo desta Seção para \"Deeper\":**

1.  Definir se e como a API \"Deeper\" precisará **consultar** a tabela `sys_permalinks`.
2.  Esclarecer que o **roteamento de requisições HTTP para os controllers da API** será responsabilidade do Phoenix, não de uma replicação direta do sistema de permalinks do UNA.
3.  Considerar cenários onde o cliente possa precisar gerar ou entender permalinks.

## Cenários de Interação com `sys_permalinks`:

1.  **Resolver um Permalink para um Identificador de Conteúdo/Página (Opcional):**
    *   Pode haver casos onde um cliente (ou outra parte do sistema) tenha um permalink do UNA (ex: `/m/persons/view/john_doe`) e precise descobrir o ID do conteúdo subjacente (ex: `bx_persons_data.id` para \"john_doe\") ou o nome do objeto de página associado.
    *   A API poderia oferecer um endpoint para essa resolução: `GET /api/v1/resolve-permalink?permalink=/m/persons/view/john_doe`.
2.  **Fornecer Informações de Permalink para o Cliente (Opcional):**
    *   Ao retornar dados de um recurso (ex: um perfil de pessoa), a API poderia incluir o permalink \"canônico\" do UNA associado a esse recurso, se existir e for útil para o cliente (ex: para fins de SEO se o cliente for uma aplicação web que também gera HTML, ou para referência).
3.  **Geração de URLs pelo Cliente:**
    *   Se o cliente precisar construir URLs amigáveis no formato do UNA (por exemplo, para interoperação ou para manter a consistência visual), ele precisaria da lógica para isso. A API \"Deeper\" não seria diretamente responsável por essa geração no cliente, mas poderia fornecer os componentes (ex: o `uri` do módulo de `sys_modules`, o `uri` do objeto de página de `sys_objects_page`).

## Roteamento no Phoenix:

*   O arquivo `lib/deeper_web/router.ex` no projeto Phoenix definirá as rotas da API.
*   Exemplos:

```elixir
    # lib/deeper_web/router.ex
    scope \"/api/v1\", DeeperWeb do
      pipe_through :api

      # Autenticação
      post \"/auth/register\", AuthController, :register
      post \"/auth/login\", AuthController, :login

      # Contas (requer auth)
      get \"/accounts/me\", AccountController, :show_me
      put \"/accounts/me\", AccountController, :update_me
      put \"/accounts/me/password\", AccountController, :update_password

      # Perfis (alguns públicos, outros requerem auth)
      get \"/profiles/me\", ProfileController, :show_me # Perfil do usuário logado
      put \"/profiles/me\", ProfileController, :update_me
      get \"/profiles/persons\", ProfileController, :index_persons # Lista pública de pessoas
      get \"/profiles/persons/:id_or_username\", ProfileController, :show_person # Perfil público

      # Páginas (baseado no 'object' da página UNA)
      get \"/pages\", PageController, :show_by_object_name # ex: /api/v1/pages?object_name=bx_persons_home

      # Configurações
      get \"/options/:option_name\", OptionsController, :show_value
      get \"/options\", OptionsController, :index_by_category # ex: /api/v1/options?category=general

      # Localização
      get \"/localization/languages\", LocalizationController, :index_languages
      get \"/localization/strings/:lang_code\", LocalizationController, :index_strings # /strings/en?category=system
    end
```

*   Este roteamento do Phoenix é independente do `sys_permalinks` para o *processamento interno* da API.

## Esquema do Banco de Dados (SQLite - Tabela `sys_permalinks`)

A definição `CREATE TABLE` para `sys_permalinks` será detalhada no arquivo `database_schema.md` dentro desta pasta. A tabela `sys_rewrite_rules` é menos provável de ser usada diretamente pela API \"Deeper\", pois sua lógica de reescrita é específica do ambiente PHP/Apache do UNA.

## Módulos de Acesso a Dados (`data_access_modules.md`)

Descreverá o `Deeper.SystemCore.PermalinksRepo` com funções para:
*   `resolve_permalink_to_standard(permalink_uri)`: Converte uma URL amigável para sua forma \"padrão\" do UNA (ex: `page.php?i=...`).
*   `get_permalink_info(permalink_uri)`: Busca informações da tabela `sys_permalinks`.

## Endpoints da API (Opcionais)

*   `GET /api/v1/permalinks/resolve?uri=/path/to/permalink`: Para resolver um permalink.
*   Outros endpoints podem ser considerados se houver necessidade de gerenciar permalinks via API (mais provável no escopo do `07_studio_admin_api`).

## Conclusão sobre Permalinks para \"Deeper\":

A principal funcionalidade da tabela `sys_permalinks` no contexto do \"Deeper\" será para **consulta e resolução**, caso o cliente ou outras partes do sistema precisem traduzir uma URL no estilo UNA para um identificador que a API \"Deeper\" entenda, ou vice-versa. O roteamento principal da API será gerenciado pelo Phoenix.