# API de Administração: Gerenciamento de Módulos (Conceitual)

Esta seção da API de Administração \"Deeper\" lida com o conceito de \"módulos\" do sistema. No UNA (PHP), os módulos são unidades de funcionalidade dinamicamente carregadas, instaladas e gerenciadas através da tabela `sys_modules`.

No backend Elixir \"Deeper\", a natureza dos \"módulos\" é diferente:
*   São principalmente contextos ou agrupamentos lógicos de funcionalidades dentro da aplicação Elixir compilada.
*   Não haverá um processo de \"instalação\" ou \"desinstalação\" de módulos em tempo de execução da mesma forma que no PHP.
*   No entanto, a tabela `sys_modules` do banco de dados original do UNA ainda existe e contém informações sobre os módulos que *compunham* o sistema UNA.

**Objetivos da API de Gerenciamento de Módulos (Conceitual) para \"Deeper\":**

*   **Listar Módulos Definidos:** Fornecer uma visão dos módulos conceituais que foram portados ou mapeados para funcionalidades no backend \"Deeper\", possivelmente lendo da tabela `sys_modules` como uma referência histórica ou de mapeamento.
*   **Habilitar/Desabilitar Funcionalidades (via `sys_options`):** Em vez de habilitar/desabilitar módulos Elixir (o que não é prático em uma aplicação compilada), funcionalidades associadas a esses \"módulos\" conceituais podem ser ativadas ou desativadas através de configurações em `sys_options`. Esta API pode fornecer um atalho para essas configurações específicas de \"módulo\".
*   **Visualizar Informações do Módulo:** Exibir informações como versão (da implementação \"Deeper\" da funcionalidade), autor/vendor (do módulo original UNA ou do time \"Deeper\").

**Autenticação:** Requerida (nível de superadministrador).

## 1. Endpoints para Módulos (`/api/v1/admin/modules`)

### `GET /api/v1/admin/modules`
*   **Descrição:** Lista todos os \"módulos\" conceituais do sistema \"Deeper\", possivelmente baseando-se nas entradas da tabela `sys_modules` do banco de dados original para fins de referência e mapeamento.
*   **Query Parameters:**
    *   `status` (string, ex: `\"enabled\"`, `\"disabled\"` - refletindo o status de uma `sys_option` de controle).
    *   `search_term` (string, busca no nome ou título).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"name\": \"bx_persons\", // sys_modules.name (identificador do módulo original)
          \"title\": \"Persons Profiles\", // sys_modules.title
          \"version\": \"1.0.0\", // Versão da implementação \"Deeper\" desta funcionalidade
          \"vendor\": \"Deeper Team (orig. UNA Vendor)\", // sys_modules.vendor
          \"is_enabled\": true, // Lido de uma sys_option como \"bx_persons_enabled\"
          \"description\": \"Manages individual user profiles and related data.\", // Descrição da funcionalidade em Deeper
          \"path_uri_original\": \"persons\", // sys_modules.uri (informativo)
          \"has_settings\": true // Indica se há opções em sys_options para este módulo
        },
        {
          \"name\": \"bx_market\",
          \"title\": \"Marketplace\",
          \"version\": \"1.0.0\",
          \"vendor\": \"Deeper Team\",
          \"is_enabled\": false, // Exemplo: funcionalidade desabilitada
          \"description\": \"Marketplace for users to list items.\",
          \"path_uri_original\": \"mkt\",
          \"has_settings\": true
        }
        // ... mais módulos conceituais
      ]
    }
```

```json
    {
      \"data\": {
        \"name\": \"bx_persons\",
        \"title\": \"Persons Profiles\",
        // ... outros campos ...
        \"is_enabled\": true,
        \"related_options\": [ // Opcional, link para as opções de configuração
          { \"name\": \"bx_persons_default_privacy_view\", \"caption\": \"Default View Privacy\" },
          { \"name\": \"bx_persons_max_profile_photos\", \"caption\": \"Max Profile Photos\" }
        ]
      }
    }
```

```json
    {
      \"action\": \"enable\" // ou \"disable\"
    }
```

```json
    {
      \"data\": {
        \"name\": \"bx_persons\",
        // ...
        \"is_enabled\": true // ou false, dependendo da ação
      }
    }
```

### `GET /api/v1/admin/modules/{module_name}`
*   **Descrição:** Obtém detalhes de um \"módulo\" conceitual específico.
*   **`{module_name}`:** O `name` do módulo (ex: \"bx_persons\").
*   **Resposta de Sucesso (200 OK):** Detalhes do módulo, similar ao item da lista acima. Pode incluir uma lista de `sys_options` relacionadas a este módulo.

*   **Respostas de Erro:** `404 Not Found`.

### `POST /api/v1/admin/modules/{module_name}/action`
*   **Descrição:** Executa uma ação em um \"módulo\" conceitual, como habilitar ou desabilitar sua funcionalidade principal (geralmente alterando uma `sys_option`).
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:**
    1.  Identifica a `sys_option` principal que controla a ativação desta funcionalidade (ex: `module_name_enabled`).
    2.  Atualiza o valor dessa `sys_option` para `\"on\"` ou `\"off\"` (ou `1`/`0`).
    3.  Invalida/recarrega o cache de configurações.
*   **Resposta de Sucesso (200 OK):** Detalhes atualizados do módulo.

*   **Respostas de Erro:** `400 Bad Request` (ação inválida), `404 Not Found`.

## Considerações para a API de Admin de Módulos no \"Deeper\":

*   **Mapeamento para `sys_modules`:** A API pode ler da tabela `sys_modules` para obter a lista inicial de \"módulos\" e suas informações descritivas originais. No entanto, o status `enabled` e a \"versão\" seriam específicos da implementação \"Deeper\".
*   **Configurações Específicas do Módulo:** Em vez de gerenciar configurações complexas através desta API de \"módulos\", é preferível que as configurações detalhadas de cada funcionalidade (\"módulo\") sejam gerenciadas através da API de Configurações do Sistema (`/api/v1/admin/system-settings/options?category_key=module_name_...`). O endpoint `GET /api/v1/admin/modules/{module_name}` pode listar as `sys_options` relevantes para facilitar a navegação.
*   **Sem Instalação/Desinstalação:** A API não suportará \"instalar\" ou \"desinstalar\" módulos no sentido do UNA PHP. A adição de novas funcionalidades principais ao \"Deeper\" é um processo de desenvolvimento e deploy da aplicação Elixir.

Esta API de \"módulos\" serve mais como uma interface de alto nível para visualizar as principais funcionalidades do sistema e controlar sua ativação básica através de `sys_options`, mantendo alguma familiaridade com o conceito de módulos do UNA para administradores.