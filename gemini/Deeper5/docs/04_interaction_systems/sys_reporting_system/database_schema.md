# Documentação Deeper: Esquema do Banco de Dados para Sistema de Denúncias (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema genérico de denúncias no \"Deeper\".

## Tabela: `deeper_report_types` (Tipos de Denúncia Predefinidos - Opcional)

Esta tabela é opcional. Se os tipos de denúncia forem fixos e poucos, podem ser gerenciados na lógica da aplicação. Se forem dinâmicos ou muitos, uma tabela é melhor.

```sql
CREATE TABLE IF NOT EXISTS deeper_report_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  type_key TEXT NOT NULL UNIQUE, -- Ex: 'spam', 'harassment', 'copyright_violation'
  title_lkey TEXT NOT NULL, -- Chave de tradução para o título do tipo de denúncia
  description_lkey TEXT, -- Chave de tradução para a descrição
  active INTEGER NOT NULL DEFAULT 1,
  \"order\" INTEGER NOT NULL DEFAULT 0
);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_reports_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL, -- Identificador do sistema de denúncias (ex: 'deeper_articles_report')
  object_id INTEGER NOT NULL, -- ID da entidade sendo denunciada
  reporter_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id de quem denunciou
  -- report_type_id INTEGER, -- FK para deeper_report_types.id (se usar a tabela acima)
  report_type_key TEXT NOT NULL, -- Chave do tipo de denúncia (ex: 'spam', 'abuse'). Mais simples se não usar a tabela de tipos.
  comment TEXT, -- Comentário adicional do denunciante
  status TEXT NOT NULL DEFAULT 'new' CHECK(status IN ('new', 'pending_review', 'acknowledged', 'resolved_action_taken', 'resolved_no_action', 'rejected')),
  reported_at INTEGER NOT NULL, -- Unix Timestamp
  checked_by_admin_profile_id INTEGER, -- FK para sys_profiles.id do admin/moderador que analisou
  checked_at INTEGER, -- Unix Timestamp da análise
  admin_notes TEXT, -- Notas do admin sobre a resolução
  -- UNIQUE (system_name, object_id, reporter_profile_id, report_type_key), -- Um usuário pode denunciar um objeto por diferentes tipos. Se apenas uma denúncia por objeto, remover report_type_key da UNIQUE.
  FOREIGN KEY (reporter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (checked_by_admin_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
  -- FOREIGN KEY (report_type_id) REFERENCES deeper_report_types(id) ON DELETE RESTRICT ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_drpt_system_object_status ON deeper_reports_track(system_name, object_id, status);
CREATE INDEX IF NOT EXISTS idx_drpt_reporter ON deeper_reports_track(reporter_profile_id);
CREATE INDEX IF NOT EXISTS idx_drpt_status_reported_at ON deeper_reports_track(status, reported_at);
```

```sql
  -- ... outras colunas ...
  reports_active_count INTEGER NOT NULL DEFAULT 0, -- Contagem de denúncias não resolvidas/rejeitadas
  -- ...
```

## Tabela: `deeper_reports_track` (Rastreamento de Denúncias Individuais)

*   **`system_name`, `object_id`**: Identificam o item denunciado.
*   **`reporter_profile_id`**: Quem fez a denúncia.
*   **`report_type_key`**: O tipo da denúncia (ex: \"spam\", \"harassment\"). Se usar a tabela `deeper_report_types`, esta seria `report_type_id` com uma FK.
*   **`comment`**: Detalhes fornecidos pelo denunciante.
*   **`status`**: Ciclo de vida da denúncia.
*   **`checked_by_admin_profile_id`, `checked_at`, `admin_notes`**: Para rastrear a moderação.
*   A constraint `UNIQUE` pode ser ajustada:
    *   Se um usuário só pode denunciar um objeto uma única vez, independentemente do tipo: `UNIQUE (system_name, object_id, reporter_profile_id)`
    *   Se um usuário pode denunciar o mesmo objeto por tipos diferentes: `UNIQUE (system_name, object_id, reporter_profile_id, report_type_key)` (como está comentado).

## Atualização de Contadores nas Tabelas de Entidade:

Quando uma denúncia é feita (e talvez quando seu status muda para algo como \"resolvida\"), um campo de contador na tabela da entidade principal (ex: `deeper_articles_entries.reports_active_count` ou `bx_persons_data.reports`) pode ser atualizado.

**Exemplo para `deeper_articles_entries`:**

A atualização pode ser feita na lógica da aplicação Elixir ou com triggers.