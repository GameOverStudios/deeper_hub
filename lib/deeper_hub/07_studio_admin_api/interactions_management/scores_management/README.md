# Documentação Deeper Studio API: Gerenciamento de Pontuações (Scores)

Este documento descreve os endpoints da API de Administração (\"Studio API\") para auditar e potencialmente gerenciar as pontuações (up/down votes) dadas a diferentes tipos de conteúdo.

**Objetivo Principal:** Permitir que administradores visualizem quem deu up/down votes e, em casos excepcionais, resetem as pontuações de um objeto.

## Entidades Relevantes:

*   `sys_objects_score`
*   Tabelas `TableMain` (ex: `bx_persons_scores`) e `TableTrack` (ex: `bx_persons_scores_track`).

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Interactions.ScoringRepo`: Funções para listar votos de score e resetar scores.

## Endpoints da API de Admin (`/api/v1/admin/moderation/scores/{score_object_name}/object/{object_id}`):

### 1. Listar Votos de Score Individuais para um Objeto

*   **Endpoint:** `GET /api/v1/admin/moderation/scores/{score_object_name}/object/{object_id}/score-votes`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `date_desc`), `filter_type` (`up` ou `down`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"score_track_id\": 1,
          \"object_id\": 123,
          \"voter\": { \"profile_id\": 789, \"fullname\": \"Jane Doe\" },
          \"vote_type\": \"up\", // \"up\" ou \"down\"
          \"date_timestamp\": 1679000000
        }
      ],
      \"pagination\": { /* ... */ },
      \"summary\": {
          \"score\": 75,
          \"count_up\": 100,
          \"count_down\": 25
      }
    }
```

```json
    {
      \"data\": {
        \"message\": \"All score votes for object {object_id} under '{score_object_name}' have been reset.\",
        \"object_id\": 123,
        \"new_score\": 0,
        \"new_count_up\": 0,
        \"new_count_down\": 0
      }
    }
```

### 2. Resetar Todas as Pontuações para um Objeto

*   **Endpoint:** `DELETE /api/v1/admin/moderation/scores/{score_object_name}/object/{object_id}/score-votes`
*   **Autenticação:** Requer JWT de Admin (com alta permissão).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Similar ao reset de votos, limpando `TableTrack`, `TableMain` e atualizando `TriggerTable` para zerar `score`, `sc_up`, `sc_down`.