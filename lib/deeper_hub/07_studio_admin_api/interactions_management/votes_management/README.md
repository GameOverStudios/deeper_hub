# Documentação Deeper Studio API: Gerenciamento de Votos/Avaliações

Este documento descreve os endpoints da API de Administração (\"Studio API\") para auditar e potencialmente gerenciar os votos/avaliações dados a diferentes tipos de conteúdo.

**Objetivo Principal:** Permitir que administradores visualizem quem votou em quê e, em casos excepcionais, resetem as avaliações de um objeto.

## Entidades Relevantes:

*   `sys_objects_vote`
*   Tabelas `TableMain` (ex: `bx_persons_votes`) e `TableTrack` (ex: `bx_persons_votes_track`) definidas em `sys_objects_vote`.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Interactions.VotingRepo`: Precisará de funções para:
    *   Listar todos os votos individuais (`TableTrack`) para um `object_id` específico.
    *   Resetar/deletar todos os votos (`TableTrack` e `TableMain`) para um `object_id` e atualizar a `TriggerTable`.

## Endpoints da API de Admin (`/api/v1/admin/moderation/ratings/{voting_object_name}/object/{object_id}`):

### 1. Listar Votos Individuais para um Objeto

*   **Endpoint:** `GET /api/v1/admin/moderation/ratings/{voting_object_name}/object/{object_id}/votes`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `date_desc`, `value_asc`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"vote_track_id\": 1, // ID da tabela de rastreamento
          \"object_id\": 123,
          \"voter\": {
            \"profile_id\": 789,
            \"fullname\": \"Jane Doe\"
          },
          \"vote_value\": 5,
          \"date_timestamp\": 1679000000,
          \"ip_address\": \"123.123.123.123\" // Ou omitido/anonimizado
        }
        // ... outros votos ...
      ],
      \"pagination\": { /* ... */ },
      \"summary\": { // Resumo da avaliação do objeto
          \"average_rating\": 4.5,
          \"total_votes\": 150
      }
    }
```

```json
    {
      \"data\": {
        \"message\": \"All votes for object {object_id} under '{voting_object_name}' have been reset.\",
        \"object_id\": 123,
        \"new_average_rating\": 0,
        \"new_total_votes\": 0
      }
    }
```

### 2. Resetar Todos os Votos para um Objeto

*   **Endpoint:** `DELETE /api/v1/admin/moderation/ratings/{voting_object_name}/object/{object_id}/votes`
*   **Autenticação:** Requer JWT de Admin (com alta permissão).
*   **Descrição:** Remove todos os registros de votos individuais (`TableTrack`) e zera as contagens na tabela de agregação (`TableMain`) e na tabela gatilho (`TriggerTable`) para o `object_id` especificado.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Busca `config` de `sys_objects_vote`.
    2.  **Inicia Transação.**
    3.  SQL: `DELETE FROM #{config.TableTrack} WHERE object_id = ?;`
    4.  SQL: `DELETE FROM #{config.TableMain} WHERE object_id = ?;` (Ou `UPDATE SET count=0, sum=0`)
    5.  Se `config.TriggerTable` definido:
        *   SQL: `UPDATE #{config.TriggerTable} SET #{config.TriggerFieldRate} = 0, #{config.TriggerFieldRateCount} = 0 WHERE #{config.TriggerFieldId} = ?;`
    6.  **Commita Transação.**