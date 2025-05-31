# Documentação Deeper: Sistema de Denúncias Genérico

Este documento descreve a API \"Deeper\" para o sistema genérico de \"Denúncias\" (Reports), permitindo que os usuários denunciem diferentes tipos de conteúdo (perfis, posts, comentários, etc.) como inapropriados, spam, etc.

## Sistema de Denúncias no UNA:

O UNA gerencia denúncias através de:

*   **`sys_objects_report`**: Define \"objetos de denúncia\" para diferentes módulos ou tipos de conteúdo.
    *   `name`: Nome único do sistema de denúncias (ex: `bx_persons`, `bx_posts`, `sys_cmts` para comentários em geral).
    *   `module`: Módulo associado.
    *   `table_main`: Tabela que armazena os dados agregados das denúncias (ex: `bx_persons_reports`). Contém colunas como `object_id`, `count`.
    *   `table_track`: Tabela que armazena as denúncias individuais dos usuários (ex: `bx_persons_reports_track`). Contém colunas como `object_id`, `author_id`, `author_nip`, `type` (tipo da denúncia), `text` (comentário da denúncia), `date`.
    *   `object_comment`: Se o sistema de denúncias está associado a um sistema de comentários (para denunciar comentários específicos).
    *   `trigger_table`, `trigger_field_id`, `trigger_field_count`: Para atualizar o contador de denúncias no conteúdo pai (ex: em `bx_persons_data.reports`).

*   **Tabelas de Denúncias:**
    *   **Tabela de Agregação (ex: `bx_persons_reports`):** `id` (PK), `object_id` (ID do conteúdo denunciado), `count`.
    *   **Tabela de Rastreamento (ex: `bx_persons_reports_track`):** `id` (PK), `object_id`, `author_id`, `author_nip`, `type`, `text`, `date`, `checked_by` (ID do admin que verificou), `status` (da denúncia: pendente, aceita, rejeitada).

## Estratégia da API \"Deeper\" para Denúncias:

A API \"Deeper\" fornecerá endpoints genéricos para usuários submeterem denúncias. A gestão e processamento dessas denúncias (pela administração) será parte da \"API do Studio/Admin\" (`07_studio_admin_api/`).

A rota da API incluirá um identificador para o `report_object_name` (que corresponde a `sys_objects_report.name`).

### Módulo de Acesso a Dados (`Deeper.Interactions.ReportingRepo`):

Este repositório genérico operará nas tabelas `table_main` e `table_track` corretas e atualizará a `trigger_table` dinamicamente.

**Funções Principais e SQLs Esperados (Parametrizados por `table_main`, `table_track`, etc.):**

*   **`get_report_system_config(report_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração de `sys_objects_report`.
    *   SQL: `SELECT * FROM sys_objects_report WHERE name = ? LIMIT 1;`
    *   Retorna `config` incluindo `table_main`, `table_track`, `trigger_table`, `trigger_field_id`, `trigger_field_count`.

*   **`has_user_reported_object(report_object_name, object_id, author_profile_id)`**
    *   Verifica se um usuário já denunciou um objeto específico.
    *   Busca `config` para obter `table_track`.
    *   SQL: `SELECT 1 FROM #{table_track} WHERE object_id = ? AND author_id = ? LIMIT 1;`
    *   Retorna `true` ou `false`.

*   **`submit_report(report_object_name, author_profile_id, author_nip, params :: map())`**
    *   `params`: `object_id :: integer()`, `type :: String.t()`, `text :: String.t()` (opcional).
    1.  Busca `config`.
    2.  Verifica se o usuário já denunciou este objeto (usando `has_user_reported_object`). Se sim, pode retornar `{:error, :already_reported}` ou permitir múltiplas denúncias dependendo da política. O UNA geralmente permite uma denúncia por usuário por objeto.
    3.  **Inicia Transação.**
    4.  Insere em `table_track`:
        *   `current_time = System.os_time(:second)`
        *   SQL: `INSERT INTO #{config.table_track} (object_id, author_id, author_nip, type, text, date, status) VALUES (?, ?, ?, ?, ?, ?, 0);` (Status 0 para pendente).
        *   (Se múltiplas denúncias não são permitidas, usar `INSERT OR IGNORE` e verificar linhas afetadas, ou a checagem prévia é suficiente).
    5.  Se a inserção foi bem-sucedida (e se a política é incrementar o contador geral mesmo que seja a primeira denúncia do usuário):
        *   Atualiza `table_main` (agregação):
            *   SQL:

```json
        {
          \"type\": \"spam\", // Tipo da denúncia (ex: 'spam', 'inappropriate', 'copyright')
          \"text\": \"Este conteúdo é claramente spam e publicidade não solicitada.\" // Comentário opcional
        }
```

```json
        {
          \"data\": {
            \"message\": \"Report submitted successfully.\",
            \"object_id\": 123,
            \"report_type\": \"spam\"
          }
        }
```

```json
        {
          \"data\": {
            \"object_id\": 123,
            \"has_reported\": true, // ou false
            \"report_details\": { // Se has_reported for true
              \"type\": \"spam\",
              \"text\": \"...\",
              \"date\": 1678886400,
              \"status\": 0 // Status da denúncia (0=pendente, 1=aceita, 2=rejeitada)
            }
          }
        }
```

```sql
                INSERT INTO #{config.table_main} (object_id, count)
                VALUES (?, 1)
                ON CONFLICT(object_id) DO UPDATE SET
                  count = count + 1;
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_report (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL UNIQUE,
      module TEXT NOT NULL,
      table_main TEXT NOT NULL, -- Tabela de agregação, ex: bx_persons_reports
      table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: bx_persons_reports_track
      pruning INTEGER NOT NULL DEFAULT 0, -- Dias para manter denúncias em track (0 = para sempre)
      is_on INTEGER NOT NULL DEFAULT 1,
      base_url TEXT, -- URL base no UNA PHP
      object_comment TEXT, -- Nome do sys_objects_cmts se for para denunciar comentários
      trigger_table TEXT,
      trigger_field_id TEXT,
      trigger_field_author TEXT, -- Não usualmente para denúncias, mas presente
      trigger_field_count TEXT, -- Coluna para contagem de denúncias
      class_name TEXT,
      class_file TEXT
    );
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_reports (
      id INTEGER PRIMARY KEY AUTOINCREMENT, -- Diferente do schema UNA que usa object_id como PK
      object_id INTEGER NOT NULL UNIQUE, -- FK para bx_persons_data.id
      count INTEGER NOT NULL DEFAULT 0
      -- FOREIGN KEY (object_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE -- Opcional
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_object_id ON bx_persons_reports(object_id);
```

```sql
    CREATE TABLE IF NOT EXISTS bx_persons_reports_track (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object_id INTEGER NOT NULL, -- FK para bx_persons_data.id (ou ID do comentário, etc.)
      author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do denunciante
      author_nip INTEGER, -- IP como inteiro
      type TEXT NOT NULL, -- Tipo da denúncia (ex: 'spam', 'inappropriate')
      text TEXT NOT NULL DEFAULT '', -- Comentário/justificativa da denúncia
      date INTEGER NOT NULL, -- Unix Timestamp
      checked_by INTEGER NOT NULL DEFAULT 0, -- ID do admin que verificou
      status INTEGER NOT NULL DEFAULT 0 -- 0=pendente, 1=aceita, 2=rejeitada
    );
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_object_author ON bx_persons_reports_track(object_id, author_id);
    CREATE INDEX IF NOT EXISTS idx_bx_persons_reports_track_status_date ON bx_persons_reports_track(status, date);
```

        *   Se `config.trigger_table` definido:
            *   SQL: `UPDATE #{config.trigger_table} SET #{config.trigger_field_count} = #{config.trigger_field_count} + 1 WHERE #{config.trigger_field_id} = ?;`
    6.  **Commita Transação.**
    7.  Retorna `{:ok, :report_submitted}`.

*   **Funções para Admin (parte de `07_studio_admin_api/`):**
    *   `list_pending_reports(report_object_name, opts)`
    *   `get_report_details(report_object_name, report_track_id)`
    *   `update_report_status(report_object_name, report_track_id, new_status, checked_by_admin_id)`

### Endpoints da API (`/api/v1/reports/{report_object_name}`):

O `{report_object_name}` na rota corresponde a `sys_objects_report.name` (ex: `bx_persons`, `bx_posts_entity_reports`).

*   **Submeter uma Denúncia:**
    *   **Endpoint:** `POST /api/v1/reports/{report_object_name}/object/{object_id}`
    *   **Path Parameters:** `report_object_name`, `object_id`.
    *   **Autenticação:** Requer JWT.
    *   **Corpo da Requisição (JSON):**

    *   **Resposta de Sucesso (201 Created ou 200 OK):**

    *   **Respostas de Erro:** `400 Bad Request` (tipo de denúncia inválido, texto muito longo), `401 Unauthorized`, `403 Forbidden` (ex: já denunciou e não pode denunciar novamente), `404 Not Found` (se `report_object_name` ou `object_id` não for válido).

*   **(Opcional) Verificar se o Usuário Já Denunciou:**
    *   **Endpoint:** `GET /api/v1/reports/{report_object_name}/object/{object_id}/my-status`
    *   **Autenticação:** Requer JWT.
    *   **Resposta de Sucesso (200 OK):**

## Tabelas de Denúncias (Esquema SQLite):

*   **`sys_objects_report` (Configuração):**

*   **Exemplo de Tabela de Agregação (`bx_persons_reports`):**

    *   *Nota: O schema original do UNA para `bx_persons_reports` tem `id` como PK e `object_id` como UNIQUE. Isso permite que um `object_id` possa não existir se não tiver denúncias, enquanto nossa versão com `object_id` como PK (ou `UNIQUE` e sendo a chave lógica) é mais comum para tabelas de agregação. Manteremos a fidelidade ao `id` PK e `object_id UNIQUE`.*

*   **Exemplo de Tabela de Rastreamento (`bx_persons_reports_track`):**

## Considerações:

*   **Tipos de Denúncia:** A lista de `type`s válidos para denúncias pode ser configurável (ex: através de uma lista pré-definida no `sys_form_pre_lists` do UNA) ou codificada. A API deve validar o tipo fornecido.
*   **Atomicidade:** Submeter uma denúncia e atualizar contadores deve ser uma operação atômica.
*   **Notificações para Admins:** Uma nova denúncia deve idealmente gerar uma notificação para os administradores/moderadores do sistema.
*   **Anonimato:** Algumas denúncias podem ser anônimas. Se `author_id` for 0, `author_nip` se torna mais importante para rastreamento (com considerações de privacidade). O UNA geralmente requer login para denunciar.

Este sistema de denúncias fornece aos usuários uma maneira de sinalizar conteúdo problemático, com a gestão das denúncias sendo uma tarefa administrativa.