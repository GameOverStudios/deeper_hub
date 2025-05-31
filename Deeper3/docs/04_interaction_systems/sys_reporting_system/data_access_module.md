# Documentação Deeper: Módulo de Acesso a Dados para Denúncias (`ReportingRepo`)

Este documento descreve o módulo Elixir `Deeper.InteractionSystems.ReportingRepo` (ou similar), responsável por encapsular a lógica de consulta e manipulação de dados para o sistema de denúncias genérico do UNA.

Ele interage com `sys_objects_report` (para configuração) e dinamicamente com as tabelas de sumário (`table_main`) e rastreamento (`table_track`) especificadas na configuração do objeto de denúncia.

**Localização do Código:** `lib/deeper/interaction_systems/reporting_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Configuração do Objeto de Denúncia

*   **`get_report_system_config(object_report_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a configuração de um sistema de denúncias específico de `sys_objects_report`.
    *   **Argumentos:**
        *   `object_report_name`: O nome do objeto de denúncia (de `sys_objects_report.name`).
    *   **Retorno:** `{:ok, config_map}` contendo todas as colunas de `sys_objects_report`.
    *   **SQL:** `SELECT * FROM sys_objects_report WHERE name = ? AND is_on = 1 LIMIT 1;`
    *   Usada internamente por outras funções do `ReportingRepo`.

### 2. Adicionar uma Nova Denúncia

*   **`add_report(object_report_name :: String.t(), item_id :: integer(), author_profile_id :: integer(), author_nip_integer :: integer() | nil, report_data :: map()) :: {:ok, map()} | {:error, :already_reported_by_user | :invalid_data | any()}`**
    *   Registra uma nova denúncia para um item de conteúdo.
    *   **Argumentos:**
        *   `report_data`: Mapa contendo `type` (tipo da denúncia) e `text` (detalhes).
    *   **Retorno:** O registro da denúncia criada ou um status.
    *   **Lógica Interna:**
        1.  Chamar `get_report_system_config(object_report_name)` para obter `config`.
        2.  Validar `report_data.type` e `report_data.text` (ex: não vazios).
        3.  **(Opcional) Verificar se este `author_profile_id` já denunciou este `item_id` com o mesmo `type` recentemente para evitar duplicatas, se essa for a política.**
            *   SQL: `SELECT id FROM #{config.table_track} WHERE object_id = ? AND author_id = ? AND type = ? LIMIT 1;`
            *   Se encontrado, pode retornar `{:error, :already_reported_by_user_with_same_type}`.
        4.  **Em uma transação:**
            a.  **Inserir em `config.table_track`:**
                *   SQL: `INSERT INTO #{config.table_track} (object_id, author_id, author_nip, type, \"text\", date, status) VALUES (?, ?, ?, ?, ?, ?, 0);` (date é timestamp atual, status 0 = pendente).
                *   Parâmetros: `item_id`, `author_profile_id`, `author_nip_integer`, `report_data.type`, `report_data.text`, `current_timestamp`.
            b.  **Atualizar/Inserir em `config.table_main` (sumário):**
                *   Lógica de UPSERT para incrementar o contador de denúncias para o `item_id`.
                *   SQL (Exemplo com UPSERT para SQLite 3.24.0+):

```sql
                    INSERT INTO #{config.table_main} (object_id, count) VALUES (?, 1)
                    ON CONFLICT(object_id) DO UPDATE SET count = count + 1;
```

```sql
                SELECT
                    rt.id as report_id, rt.object_id, rt.type as report_type, rt.\"text\" as report_text, rt.date as report_date, rt.status as report_status,
                    author_prof.fullname as reporter_fullname,
                    admin_prof.fullname as checker_fullname,
                    content_item.#{config.trigger_field_title} as item_title -- Assumindo que config tem TriggerFieldTitle
                FROM #{config.table_track} rt
                JOIN sys_profiles author_prof ON rt.author_id = author_prof.id
                LEFT JOIN sys_profiles admin_prof ON rt.checked_by = admin_prof.id AND rt.checked_by != 0
                LEFT JOIN #{config.trigger_table} content_item ON rt.object_id = content_item.#{config.trigger_field_id} -- Se TriggerTable e TriggerFieldId estão definidos
                -- WHERE ... (filtros baseados em opts)
                ORDER BY rt.date DESC
                LIMIT ? OFFSET ?;
```

            c.  **Atualizar `TriggerTable` (contador na tabela de conteúdo principal):**
                *   Se `config.trigger_table` e `config.trigger_field_count` estiverem definidos:
                *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = #{config.trigger_field_count} + 1 WHERE #{config.trigger_field_id} = ?;`
                *   Parâmetro: `item_id`.
        5.  Retornar o registro da denúncia inserida na `table_track` (ou um simples `{:ok, :report_submitted}`).

### 3. Listar Denúncias (Para Administração)

*   **`list_reports(object_report_name :: String.t() | nil, opts :: map()) :: {:ok, %{data: list(map()), pagination: map()}} | {:error, any()}`**
    *   Lista denúncias, geralmente para um painel de administração/moderação.
    *   **Argumentos:**
        *   `object_report_name`: (Opcional) Para filtrar denúncias de um sistema específico.
        *   `opts`: Mapa de opções, como:
            *   `item_id :: integer()` (para listar denúncias de um item específico).
            *   `status :: integer()` (para filtrar por status da denúncia: 0=pendente, 1=aceita, 2=rejeitada).
            *   `page :: integer()`, `per_page :: integer()`.
            *   `sort_by :: String.t()` (ex: `date_desc`).
    *   **Retorno:** Lista de denúncias com detalhes do item denunciado e do autor da denúncia.
    *   **Lógica Interna:**
        1.  Se `object_report_name` fornecido, chamar `get_report_system_config` para obter `config` e usar `config.table_track`. Se não, a query precisaria ser mais complexa para buscar de múltiplas tabelas de track ou esta função seria restrita a um `object_report_name`. Assumindo `object_report_name` é fornecido.
        2.  Construir query SQL para `config.table_track` com JOINs para `sys_profiles` (para `author_id` e `checked_by`) e para a `config.trigger_table` (para obter o título/link do item denunciado).
            *   **SQL (Exemplo conceitual):**

        3.  Executar query de dados e query de contagem total para paginação.
        4.  Mapear e retornar.

### 4. Atualizar Status de uma Denúncia (Para Administração)

*   **`update_report_status(object_report_name :: String.t(), report_track_id :: integer(), new_status :: integer(), admin_profile_id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Permite que um administrador atualize o status de uma denúncia (ex: de pendente para resolvida).
    *   **Lógica Interna:**
        1.  Chamar `get_report_system_config(object_report_name)` para obter `config`.
        2.  SQL: `UPDATE #{config.table_track} SET status = ?, checked_by = ?, date = ? WHERE id = ? RETURNING *;` (atualiza `date` para refletir quando foi checado/modificado).
        3.  Parâmetros: `new_status`, `admin_profile_id`, `current_timestamp`, `report_track_id`.

### 5. Obter Contagem de Denúncias para um Item

*   **`get_reports_count_for_item(object_report_name :: String.t(), item_id :: integer()) :: {:ok, integer()} | {:error, any()}`**
    *   Retorna o número de denúncias para um item.
    *   **Lógica Interna:**
        1.  Chamar `get_report_system_config(object_report_name)`.
        2.  Consultar `config.table_main`:
            *   SQL: `SELECT count FROM #{config.table_main} WHERE object_id = ?;`
        3.  Ou, se a tabela de sumário não for confiável ou para denúncias com status específico, contar de `config.table_track`:
            *   SQL: `SELECT COUNT(id) FROM #{config.table_track} WHERE object_id = ? AND status = 0;` (ex: apenas pendentes).

### Considerações:

*   **Nomes de Tabela Dinâmicos:** Validação e uso seguro dos nomes de tabela são cruciais.
*   **Transações:** `add_report` deve ser transacional.
*   **Notificações:** Após uma denúncia ser submetida, o sistema UNA geralmente envia notificações para administradores/moderadores. A API \"Deeper\" pode precisar integrar-se com um sistema de enfileiramento de notificações.
*   **Privacidade:** A listagem de denúncias (`list_reports`) é uma função administrativa e deve ser rigorosamente protegida por ACL.