# Documentação Deeper: Módulo de Acesso a Dados para Sistema de Denúncias Genérico (`Deeper.Interactions.ReportingRepo`)

Este documento descreve o módulo Elixir `Deeper.Interactions.ReportingRepo`. Ele é projetado para ser um repositório genérico que lida com a submissão e (potencialmente no futuro, para admin) listagem de denúncias para diferentes sistemas definidos em `sys_objects_report`.

Ele operará dinamicamente nas tabelas `table_main` e `table_track` corretas e usará as configurações apropriadas (como `trigger_table` para atualizar contadores) com base no `report_object_name` fornecido.

## Responsabilidades Principais:

*   Obter configurações de um sistema de denúncias específico de `sys_objects_report`.
*   Verificar se um usuário já denunciou um `object_id` (se a política for de uma denúncia por usuário).
*   Registrar uma nova denúncia na `table_track` correta.
*   Atualizar a contagem de denúncias na `table_main` e na `trigger_table` do conteúdo pai.
*   (Para Admin API) Listar denúncias pendentes.
*   (Para Admin API) Atualizar o status de uma denúncia.

## Funções Auxiliares Chave (Internas):

*   **`get_report_system_config(report_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_report`.
    *   SQL: `SELECT * FROM sys_objects_report WHERE name = ? LIMIT 1;`
    *   Retorna mapa com `name`, `table_main`, `table_track`, `trigger_table`, `trigger_field_id`, `trigger_field_count`.
    *   Pode ser cacheado.

## Funções Públicas Principais e Lógica SQL:

*(Todas as funções públicas aceitarão `report_object_name` como primeiro argumento).*

*   **`submit_report(report_object_name :: String.t(), author_profile_id :: integer(), author_nip :: integer() | nil, params :: map()) :: {:ok, :report_submitted} | {:error, any()}`**
    *   `params`: `object_id :: integer()`, `type :: String.t()`, `text :: String.t()` (opcional).
    1.  `{:ok, config} = get_report_system_config(report_object_name)`
    2.  `table_track = config[\"table_track\"]`
    3.  `table_main = config[\"table_main\"]`
    4.  (Opcional) Verificar se o usuário já denunciou este `object_id` se a política for limitar a uma denúncia por usuário/objeto.
        *   SQL: `SELECT 1 FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
        *   Se encontrado e política é de uma denúncia, retorna `{:error, :already_reported}`.
    5.  **Inicia Transação (`Repo.transaction/1`)**
    6.  `current_time = System.os_time(:second)`
    7.  `report_text = Map.get(params, :text, \"\")`
    8.  `status_pending = 0`
    9.  Insere na tabela de rastreamento:
        *   SQL: `INSERT INTO #{table_track} (object_id, author_id, author_nip, type, text, date, status) VALUES (?, ?, ?, ?, ?, ?, ?);`
           (Valores: `params.object_id`, `author_profile_id`, `author_nip`, `params.type`, `report_text`, `current_time`, `status_pending`).
    10. Se a inserção for bem-sucedida (e se a política é incrementar o contador mesmo para múltiplas denúncias do mesmo usuário, ou se é a primeira denúncia):
        *   Atualiza a tabela de agregação `table_main`:
            *   SQL:

```sql
                INSERT INTO #{table_main} (object_id, count)
                VALUES (?, 1)
                ON CONFLICT(object_id) DO UPDATE SET
                  count = count + 1;
```

                (Usando `params.object_id`).
        *   Se `config.trigger_table` e `config.trigger_field_count` estiverem definidos:
            *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = #{config.trigger_field_count} + 1 WHERE #{config.trigger_field_id} = ?;`
               (Usando `params.object_id`).
    11. **Commita Transação.**
    12. Retorna `{:ok, :report_submitted}`.

*   **`get_user_report_for_object(report_object_name :: String.t(), object_id :: integer(), author_profile_id :: integer()) :: {:ok, report_details :: map() | nil} | {:error, any()}`**
    1.  `{:ok, config} = get_report_system_config(report_object_name)`
    2.  `table_track = config[\"table_track\"]`
    3.  SQL: `SELECT type, text, date, status FROM #{table_track} WHERE object_id = ? AND author_id = ? ORDER BY date DESC LIMIT 1;`
    4.  Mapeia o resultado para um mapa ou retorna `nil`.

---
### Funções para Administração (a serem usadas pela API de Admin)

*   **`list_reports_by_status(report_object_name :: String.t(), status_code :: integer(), opts :: Keyword.t()) :: {:ok, {reports :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   `opts`: `limit`, `offset`, `sort_by` (ex: `date_asc`).
    1.  Busca `config`.
    2.  SQL: `SELECT rt.*, reporter_profile.fullname AS reporter_fullname, target_content.[title_or_name_column] AS target_content_title FROM #{config.table_track} rt LEFT JOIN sys_profiles reporter_sp ON rt.author_id = reporter_sp.id LEFT JOIN bx_persons_data reporter_profile ON reporter_sp.content_id = reporter_profile.id AND reporter_sp.type = 'bx_persons' /* JOIN com a tabela do conteúdo alvo para obter um título/link */ LEFT JOIN #{config.trigger_table} target_content ON rt.object_id = target_content.#{config.trigger_field_id} WHERE rt.status = ? ORDER BY rt.date ASC LIMIT ? OFFSET ?;`
        *   O JOIN com `target_content` é complexo e depende da estrutura da `trigger_table`.
    3.  Retorna a lista de denúncias e metadados de paginação.

*   **`get_report_details_admin(report_object_name :: String.t(), report_track_id :: integer()) :: {:ok, report_details :: map()} | {:error, :not_found | any()}`**
    *   Similar à query acima, mas filtrando por `rt.id = report_track_id`.

*   **`update_report_status_admin(report_object_name :: String.t(), report_track_id :: integer(), new_status_code :: integer(), admin_profile_id :: integer()) :: {:ok, updated_report :: map()} | {:error, any()}`**
    1.  Busca `config`.
    2.  SQL: `UPDATE #{config.table_track} SET status = ?, checked_by = ?, date = ? /* (opcional: atualizar data para data de checagem) */ WHERE id = ? RETURNING *;`
        (Valores: `new_status_code`, `admin_profile_id`, `System.os_time(:second)`, `report_track_id`).
    3.  **Lógica Adicional:** Se `new_status_code` for \"aceita\" e isso implica em uma ação no conteúdo denunciado (ex: despublicar, deletar), essa lógica precisaria ser acionada. Se for \"rejeitada\", o contador em `table_main` e `trigger_table` *poderia* ser decrementado se as denúncias rejeitadas não contarem para o total visível (política a definir).

## Considerações:

*   **Tipos de Denúncia (`type`):** A API deve validar os tipos de denúncia permitidos. Estes podem vir de uma lista pré-definida (ex: `sys_form_pre_lists` do UNA com a chave `bx_report_type` ou similar).
*   **Fluxo de Moderação:** A API de usuário apenas submete denúncias. A API de administração é que lida com o processamento, visualização e alteração de status das denúncias.

Este `ReportingRepo` genérico estabelece a base para a funcionalidade de denúncias em \"Deeper\".