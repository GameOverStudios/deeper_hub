# Documentação Deeper Studio API: Gerenciamento de Favoritos

Este documento descreve os endpoints da API de Administração (\"Studio API\") para auditar quem favoritou quais itens de conteúdo.

**Objetivo Principal:** Permitir que administradores visualizem a lista de usuários que favoritaram um item específico. A remoção administrativa de favoritos individuais ou em massa é geralmente uma ação menos comum.

## Entidades Relevantes:

*   `sys_objects_favorite`
*   Tabelas `table_track` (ex: `bx_persons_favorites_track`).

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Interactions.FavoritesRepo`: Função `list_who_favorited_object_admin` (similar à pública, mas sem a checagem `is_public`).

## Endpoints da API de Admin (`/api/v1/admin/moderation/favorites/{favorite_object_name}/object/{object_id}`):

### 1. Listar Usuários que Favoritaram um Objeto

*   **Endpoint:** `GET /api/v1/admin/moderation/favorites/{favorite_object_name}/object/{object_id}/who-favorited`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `date_desc`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"favorited_track_id\": 1, // ID da tabela de rastreamento
          \"object_id\": 123,
          \"user_profile\": { \"profile_id\": 789, \"fullname\": \"Jane Doe\" },
          \"date_timestamp\": 1679000000
        }
      ],
      \"pagination\": { /* ... */ },
      \"total_favorites_count\": 75 // Da trigger_table ou contagem de table_track
    }
```