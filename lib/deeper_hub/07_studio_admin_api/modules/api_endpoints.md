# Endpoints da API de Admin para Gerenciamento de Módulos

Endpoints para listar, visualizar e gerenciar o estado dos módulos do sistema. Todos os endpoints aqui requerem autenticação de Administrador.

## Endpoints (`/api/v1/admin/modules`):

### 1. Listar Todos os Módulos (Visão Administrativa)

*   **Endpoint:** `GET /api/v1/admin/modules`
*   **Descrição:** Retorna uma lista de todos os módulos instalados, incluindo habilitados e desabilitados, com informações detalhadas.
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:**
    *   `filter_enabled` (boolean, opcional): Filtrar por status (`true` ou `false`).
    *   `filter_type` (string, opcional): Filtrar por tipo de módulo (ex: `module`, `template`).
    *   `filter_vendor` (string, opcional): Filtrar por fornecedor.
    *   `filter_name_like` (string, opcional): Filtrar por nome do módulo.
    *   `sort_by` (string, opcional): Campo para ordenação (ex: `name`, `title`, `type`, `enabled`).
    *   `sort_order` (string, opcional): `asc` ou `desc`.
    *   `page`, `per_page` (inteiros, opcional): Para paginação.
    *   `lang` (string, opcional): Código do idioma para traduzir `title` e outras chaves de tradução.
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
          \"class_prefix\": \"BxPersons\",
          \"db_prefix\": \"bx_persons_\",
          \"lang_category\": \"Persons\",
          \"enabled\": true,
          \"pending_uninstall\": false,
          \"dependencies_str\": \"bx_timeline,bx_polyglot\", // sys_modules.dependencies
          \"date_installed_timestamp\": 1609459200,
          \"help_url\": \"https://una.io/page/view-module?name=bx_persons\"
        }
        // ... outros módulos ...
      ],
      \"pagination\": {
        \"total_items\": 50,
        \"total_pages\": 3,
        \"current_page\": 1,
        \"per_page\": 20
      }
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
        \"dependencies_str\": \"bx_timeline,bx_polyglot\", // sys_modules.dependencies
        \"date_installed_timestamp\": 1609459200,
        \"enabled\": true,
        \"pending_uninstall\": false,
        \"module_hash\": \"abcdef1234567890\", // sys_modules.hash
        \"last_updated_timestamp\": 1678886400 // sys_modules.updated
      }
    }
```

```json
    {
      \"data\": { /* ... dados do módulo atualizado ... */ },
      \"message\": \"Module '{module_name}' enabled successfully.\"
    }
```

```json
    {
      \"data\": { /* ... dados do módulo atualizado ... */ },
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
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do módulo atualizado (com `enabled: true`).

*   **Respostas de Erro:**
    *   `404 Not Found`: Módulo não encontrado.
    *   `409 Conflict`: Módulo já habilitado. (Opcional: se tentar habilitar um módulo cujas dependências não estão habilitadas - lógica avançada).
*   **Lógica do Backend:** Chama `Deeper.SystemCore.ModulesRepo.set_module_enabled_status(module_name, true)`. Invalida caches relevantes (ex: cache de módulos habilitados).

### 4. Desabilitar um Módulo

*   **Endpoint:** `PUT /api/v1/admin/modules/{module_name}/disable`
*   **Path Parameter:** `module_name`.
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do módulo atualizado (com `enabled: false`).

*   **Respostas de Erro:**
    *   `404 Not Found`: Módulo não encontrado.
    *   `409 Conflict`: Módulo já desabilitado. (Opcional: se tentar desabilitar um módulo do qual outros módulos habilitados dependem - lógica avançada).
*   **Lógica do Backend:** Chama `Deeper.SystemCore.ModulesRepo.set_module_enabled_status(module_name, false)`. Invalida caches relevantes.

### Considerações sobre Endpoints Futuros (Fora do Escopo Inicial):

*   **Instalar Módulo:** Exigiria upload de arquivo do módulo, descompactação, execução de instalador (SQL, registro de componentes).
*   **Desinstalar Módulo:** Exigiria execução de desinstalador (remoção de tabelas, desregistro de componentes). Marcar `pending_uninstall`.
*   **Atualizar Módulo:** Similar à instalação, mas com lógica de atualização de esquema e dados.
*   **Verificar Dependências:** Um endpoint para verificar se as dependências de um módulo estão satisfeitas.

Estes endpoints fornecem a base para o gerenciamento do estado dos módulos pela interface de administração da \"Deeper\".