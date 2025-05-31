# Documentação Deeper Studio API: Gerenciamento de Módulos (`sys_modules`)

Este documento descreve os endpoints da API de Administração (\"Studio API\") para listar, visualizar detalhes e gerenciar o estado (habilitado/desabilitado) dos módulos do sistema armazenados na tabela `sys_modules`.

**Objetivo Principal:** Permitir que administradores controlem quais módulos estão ativos na plataforma \"Deeper\" e visualizem informações sobre os módulos instalados.

**Nota:** A funcionalidade de *instalar* ou *desinstalar* novos módulos via API é significativamente mais complexa (envolvendo manipulação de arquivos, execução de scripts de banco de dados do módulo, gerenciamento de dependências) e está fora do escopo inicial desta API. O foco aqui é no gerenciamento de módulos já presentes no sistema de arquivos e registrados no banco de dados.

## Tabelas Relevantes (já definidas e migradas):

*   **`sys_modules`**: O catálogo central de todos os módulos.

## Módulo de Acesso a Dados (`Deeper.SystemCore.ModulesRepo`):

Este repositório (já parcialmente definido em `01_system_core/sys_modules_management/`) será usado para ler e atualizar o status dos módulos. As funções relevantes incluem:

*   `list_modules(filters :: Keyword.t())`
*   `get_module_by_name(module_name :: String.t())`
*   `set_module_enabled_status(module_name :: String.t(), is_enabled :: boolean())`

## Endpoints da API de Administração para Módulos (`/api/v1/admin/modules`):

### 1. Listar Todos os Módulos

*   **Endpoint:** `GET /api/v1/admin/modules`
*   **Descrição:** Retorna uma lista de todos os módulos instalados no sistema, com informações detalhadas e opções de filtro.
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:**
    *   `enabled` (boolean): Filtrar por status habilitado/desabilitado.
    *   `type` (string): Filtrar por tipo de módulo (ex: `module`, `template`, `language`).
    *   `vendor` (string): Filtrar por fornecedor.
    *   `lang`: Código do idioma para traduzir o `title` dos módulos.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"bx_persons\",
          \"title\": \"Pessoas\", // Traduzido
          \"type\": \"module\",
          \"vendor\": \"UNA\",
          \"version\": \"13.0.0\",
          \"path\": \"boonex/persons/\",
          \"uri\": \"persons\",
          \"enabled\": true,
          \"pending_uninstall\": false,
          \"dependencies\": \"bx_timeline,bx_polyglot\", // Exemplo
          \"date_installed_timestamp\": 1609459200
        },
        {
          \"name\": \"protean\",
          \"title\": \"Protean Template\", // Traduzido
          \"type\": \"template\",
          \"vendor\": \"UNA\",
          \"version\": \"13.0.1\",
          \"path\": \"boonex/protean/\",
          \"uri\": \"template-protean\",
          \"enabled\": false,
          \"pending_uninstall\": false,
          \"dependencies\": \"\",
          \"date_installed_timestamp\": 1609559200
        }
        // ... outros módulos ...
      ]
      // \"pagination\": { ... } // Se a lista for paginada
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"type\": \"module\",
        \"subtypes\": 0,
        \"name\": \"bx_persons\",
        \"title\": \"Pessoas\", // Traduzido
        \"vendor\": \"UNA\",
        \"version\": \"13.0.0\",
        \"help_url\": \"https://una.io/page/view-module?name=bx_persons\",
        \"path\": \"boonex/persons/\",
        \"uri\": \"persons\",
        \"class_prefix\": \"BxPersons\",
        \"db_prefix\": \"bx_persons_\",
        \"lang_category\": \"Persons\",
        \"dependencies\": \"bx_timeline,bx_polyglot\",
        \"date_installed_timestamp\": 1609459200,
        \"enabled\": true,
        \"pending_uninstall\": false,
        \"hash\": \"abcdef1234567890\", // Hash dos arquivos do módulo
        \"last_updated_timestamp\": 1678886400
      }
    }
```

```json
    {
      \"data\": { /* ... dados do módulo atualizado com enabled: true ... */ },
      \"message\": \"Module '{module_name}' enabled successfully.\"
    }
```

```json
    {
      \"data\": { /* ... dados do módulo atualizado com enabled: false ... */ },
      \"message\": \"Module '{module_name}' disabled successfully.\"
    }
```

### 2. Obter Detalhes de um Módulo Específico

*   **Endpoint:** `GET /api/v1/admin/modules/{module_name}`
*   **Path Parameter:** `module_name` (o nome único do módulo, ex: `bx_persons`).
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

### 3. Habilitar um Módulo

*   **Endpoint:** `PUT /api/v1/admin/modules/{module_name}/enable`
*   **Path Parameter:** `module_name`.
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do módulo atualizado (similar à resposta do GET).

*   **Respostas de Erro:**
    *   `404 Not Found`: Módulo não encontrado.
    *   `409 Conflict`: Módulo já habilitado, ou falha ao habilitar devido a dependências não resolvidas (lógica avançada, não no escopo inicial).
*   **Lógica do Backend:** Chama `ModulesRepo.set_module_enabled_status(module_name, true)`.

### 4. Desabilitar um Módulo

*   **Endpoint:** `PUT /api/v1/admin/modules/{module_name}/disable`
*   **Path Parameter:** `module_name`.
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do módulo atualizado.

*   **Respostas de Erro:**
    *   `404 Not Found`: Módulo não encontrado.
    *   `409 Conflict`: Módulo já desabilitado, ou falha ao desabilitar devido a outros módulos que dependem dele (lógica avançada).
*   **Lógica do Backend:** Chama `ModulesRepo.set_module_enabled_status(module_name, false)`.

## Considerações Importantes para Habilitar/Desabilitar Módulos:

*   **Impacto no Sistema:** Como já mencionado no `ModulesRepo`, a simples alteração do flag `enabled` pela API \"Deeper\" não executa os scripts `on_enable`/`on_disable` do UNA PHP. Estes scripts podem realizar tarefas cruciais como:
    *   Registrar/desregistrar handlers de alerta (`sys_alerts_handlers`).
    *   Registrar/desregistrar objetos do sistema (páginas, menus, formulários, grids, etc. em `sys_objects_*`).
    *   Criar/remover tabelas de banco de dados específicas do módulo (se não forem criadas na instalação inicial).
    *   Limpar caches específicos do módulo.
*   **Implicações para a API \"Deeper\":**
    *   Se um módulo que fornece um `storage_object` for desabilitado, a API de upload para esse storage pode falhar.
    *   Se um módulo que define um `page_object` for desabilitado, a API de Páginas não deve mais servir essa página.
    *   A lógica em vários `Repo`s da API \"Deeper\" pode precisar verificar se o módulo associado a um objeto (ex: `sys_objects_form.module`) está habilitado antes de processá-lo.
*   **Abordagem Inicial \"Deeper\":**
    *   A API permitirá habilitar/desabilitar o flag.
    *   A interface de administração que consome esta API deve alertar o administrador sobre as possíveis limitações e a necessidade de ações manuais ou de um processo de sincronização mais profundo se a paridade total com o comportamento do UNA PHP for necessária.
    *   Para uma integração mais completa, a API \"Deeper\" precisaria de um sistema para registrar e executar lógicas equivalentes aos `on_enable`/`on_disable` em Elixir, o que é um grande aumento de escopo.

Esta API de gerenciamento de módulos fornece aos administradores controle básico sobre quais funcionalidades estão ativas no sistema \"Deeper\".