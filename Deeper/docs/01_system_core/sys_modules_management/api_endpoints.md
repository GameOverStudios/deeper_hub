# Documentação Deeper: Endpoints da API para Gerenciamento de Módulos

Este documento especifica os endpoints da API RESTful \"Deeper\" para listar e (potencialmente, para administradores) gerenciar módulos do sistema.

Estes endpoints interagem com o `Deeper.SystemCore.ModulesRepo`.

## Endpoints da API:

### 1. Listar Módulos

*   **Endpoint:** `GET /api/v1/system/modules`
*   **Descrição:** Retorna uma lista de módulos instalados, com opções de filtro.
*   **Autenticação:** Opcional. Se não autenticado, pode retornar apenas módulos habilitados e um conjunto limitado de informações. Se autenticado como admin, retorna todos os módulos e mais detalhes.
*   **Query Parameters:**
    *   `enabled` (boolean): Filtrar por status habilitado/desabilitado (requer admin para ver desabilitados).
    *   `type` (string): Filtrar por tipo de módulo (ex: `module`, `template`).
    *   `lang`: Código do idioma para traduzir títulos.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"name\": \"bx_persons\",
          \"title\": \"Pessoas\", // Traduzido
          \"version\": \"13.0.0\",
          \"vendor\": \"UNA\",
          \"uri\": \"persons\",
          \"enabled\": true,
          \"type\": \"module\"
        },
        {
          \"name\": \"protean\",
          \"title\": \"Protean Template\", // Traduzido
          \"version\": \"13.0.1\",
          \"vendor\": \"UNA\",
          \"uri\": \"template-protean\", // Exemplo
          \"enabled\": true,
          \"type\": \"template\"
        }
        // ... outros módulos ...
      ]
      // \"pagination\": { ... } // Se a lista for muito grande e paginada
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"name\": \"bx_persons\",
        \"title\": \"Pessoas\", // Traduzido
        \"vendor\": \"UNA\",
        \"version\": \"13.0.0\",
        \"type\": \"module\",
        \"path\": \"boonex/persons/\",
        \"uri\": \"persons\",
        \"class_prefix\": \"BxPersons\",
        \"db_prefix\": \"bx_persons_\",
        \"lang_category\": \"Persons\",
        \"dependencies\": \"bx_timeline,bx_ πολυ\", // Exemplo
        \"enabled\": true,
        \"is_pending_uninstall\": false,
        \"date_installed_timestamp\": 1609459200,
        \"last_updated_timestamp\": 1678886400
      }
    }
```

### 2. Obter Detalhes de um Módulo Específico

*   **Endpoint:** `GET /api/v1/system/modules/{module_name}`
*   **Path Parameter:** `module_name` (o nome único do módulo).
*   **Autenticação:** Opcional/Admin (similar ao de listagem).
*   **Query Parameters:** `lang`.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `404 Not Found`.

---
### Endpoints de Administração (Requerem permissão de Admin)

*(Estes seriam parte da API de Admin - `07_studio_admin_api/`)*

### 3. Habilitar um Módulo

*   **Endpoint:** `PUT /api/v1/admin/modules/{module_name}/enable`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do módulo atualizado.
*   **Respostas de Erro:** `404 Not Found`, `403 Forbidden`, `409 Conflict` (ex: se dependências não estiverem resolvidas - lógica complexa não coberta inicialmente).

### 4. Desabilitar um Módulo

*   **Endpoint:** `PUT /api/v1/admin/modules/{module_name}/disable`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):** Retorna os detalhes do módulo atualizado.
*   **Respostas de Erro:** `404 Not Found`, `403 Forbidden`.

**Nota Importante sobre Habilitar/Desabilitar:** Conforme mencionado no `ModulesRepo`, a API \"Deeper\" inicialmente apenas alterará o flag `enabled` no banco de dados. A execução dos scripts `on_enable`/`on_disable` do UNA PHP (que podem realizar tarefas críticas como registrar componentes, limpar caches, etc.) não será replicada sem um esforço de portabilidade significativo dessa lógica para Elixir. A interface de administração que consome esta API deve estar ciente dessa limitação.