# Documentação Deeper Studio API: Gerenciamento de Reações

Este documento descreve os endpoints da API de Administração (\"Studio API\") para auditar as reações dadas a diferentes tipos de conteúdo.

**Objetivo Principal:** Permitir que administradores visualizem o resumo das reações e a lista de usuários que deram uma reação específica a um item. Remoção administrativa de reações é menos comum.

## Entidades Relevantes:

*   `sys_objects_reaction` (ou similar)
*   Tabelas `table_main` (ex: `generic_reactions_summary`) e `table_track` (ex: `generic_reactions_track`).

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Interactions.ReactionsRepo`: Funções para listar reações individuais e resumos.

## Endpoints da API de Admin (`/api/v1/admin/moderation/reactions/{reaction_object_name}/object/{object_id}`):

### 1. Obter Resumo Detalhado de Reações para um Objeto (Visão Admin)

*   **Endpoint:** `GET /api/v1/admin/moderation/reactions/{reaction_object_name}/object/{object_id}/summary`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"object_id\": 123,
        \"reactions\": {
          \"like\": { \"count\": 55, \"users_sample\": [{\"profile_id\": 1, \"fullname\": \"User A\"}, {\"profile_id\": 2, \"fullname\": \"User B\"}] },
          \"love\": { \"count\": 23, \"users_sample\": [{\"profile_id\": 3, \"fullname\": \"User C\"}] },
          \"haha\": { \"count\": 5, \"users_sample\": [] }
        },
        \"available_reactions\": [\"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\"]
      }
    }
```

```json
    {
      \"data\": [
        {
          \"reaction_track_id\": 1,
          \"object_id\": 123,
          \"user_profile\": { \"profile_id\": 789, \"fullname\": \"Jane Doe\" },
          \"reaction_type\": \"love\",
          \"date_timestamp\": 1679000000
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

    *   `users_sample`: Uma pequena amostra de usuários que deram essa reação (opcional).

### 2. Listar Usuários que Deram uma Reação Específica a um Objeto

*   **Endpoint:** `GET /api/v1/admin/moderation/reactions/{reaction_object_name}/object/{object_id}/who-reacted/{reaction_type}`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `date_desc`).
*   **Resposta de Sucesso (200 OK):**