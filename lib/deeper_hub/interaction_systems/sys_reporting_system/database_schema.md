# Documentação Deeper: Esquema do BD para Sistema de Denúncias Genérico (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite da tabela de configuração `sys_objects_report` e exemplos de tabelas de sumário (`table_main`) e rastreamento (`table_track`) usadas pelo sistema de denúncias genérico do UNA.

## Tabela: `sys_objects_report` (Configuração)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_report (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  name TEXT NOT NULL UNIQUE, -- Nome único do objeto de denúncia, ex: 'bx_persons_reports'
  module TEXT NOT NULL,
  table_main TEXT NOT NULL, -- Tabela de sumário das denúncias (ex: bx_persons_reports)
  table_track TEXT NOT NULL, -- Tabela de rastreamento de denúncias individuais (ex: bx_persons_reports_track)
  pruning INTEGER NOT NULL DEFAULT 31536000, -- Em segundos (1 ano)
  is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se este sistema está ativo)
  base_url TEXT, -- URL base para links de denúncias
  object_comment TEXT, -- Nome de um objeto sys_objects_cmts para comentários nas denúncias (para admins)
  trigger_table TEXT, -- Tabela de conteúdo principal a ser atualizada
  trigger_field_id TEXT, -- Nome da coluna ID na TriggerTable
  trigger_field_author TEXT,
  trigger_field_count TEXT, -- Nome da coluna de contagem de denúncias na TriggerTable
  class_name TEXT,
  class_file TEXT
  -- FK para Module (sys_modules.name)
  -- FK para object_comment (sys_objects_cmts.Name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_report_name ON sys_objects_report(name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_report_module ON sys_objects_report(Module);
```

```sql
-- EXEMPLO: Se sys_objects_report.table_main = 'bx_example_content_reports'
CREATE TABLE IF NOT EXISTS bx_example_content_reports (
  -- A PK no UNA varia. Às vezes é um 'id' autoincrementável, às vezes 'object_id' é a PK.
  -- Adotaremos 'object_id' como PK para simplicidade, já que é 1:1 com o item de conteúdo.
  object_id INTEGER PRIMARY KEY NOT NULL, -- ID do item de conteúdo que foi denunciado
  count INTEGER NOT NULL DEFAULT 0 -- Número total de denúncias para este objeto
  -- A FK para object_id dependeria do tipo de conteúdo específico.
);
-- Se object_id não for PK, um índice UNIQUE é necessário:
-- CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_example_reports_object_id ON bx_example_content_reports(object_id);
```

```sql
-- EXEMPLO: Se sys_objects_report.table_track = 'bx_example_content_reports_track'
CREATE TABLE IF NOT EXISTS bx_example_content_reports_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object_id INTEGER NOT NULL, -- ID do item de conteúdo que foi denunciado
  author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem denunciou)
  author_nip INTEGER, -- IP do autor como inteiro
  type TEXT NOT NULL DEFAULT '', -- Tipo da denúncia (ex: 'spam', 'abuso')
  \"text\" TEXT NOT NULL, -- Detalhes da denúncia
  date INTEGER NOT NULL, -- Unix Timestamp
  checked_by INTEGER DEFAULT 0, -- ID do admin que verificou (FK para sys_profiles.id ou sys_accounts.id)
  status INTEGER NOT NULL DEFAULT 0, -- Status da denúncia (ex: 0=pendente, 1=aceita, 2=rejeitada)
  -- A FK para object_id dependeria do tipo de conteúdo.
  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- FK para checked_by pode ser para sys_profiles(id) ou sys_accounts(id)
);
CREATE INDEX IF NOT EXISTS idx_bx_example_reports_track_object_id ON bx_example_content_reports_track(object_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_reports_track_author_id ON bx_example_content_reports_track(author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_reports_track_status_date ON bx_example_content_reports_track(status, date);
-- Para evitar múltiplas denúncias idênticas do mesmo autor para o mesmo objeto (pode ser desejável permitir, ou não):
-- CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_example_reports_track_obj_auth_type ON bx_example_content_reports_track(object_id, author_id, type);
```

*   Define cada sistema de \"denúncias\" para diferentes partes do site.

## Exemplo de Tabela de Sumário de Denúncias (`table_main`)

O nome desta tabela é dinâmico, vindo de `sys_objects_report.table_main`. Ex: `bx_persons_reports`.

*   Armazena dados agregados das denúncias para cada item de conteúdo.

## Exemplo de Tabela de Rastreamento de Denúncias (`table_track`)

O nome desta tabela é dinâmico, vindo de `sys_objects_report.table_track`. Ex: `bx_persons_reports_track`.

*   Registra cada denúncia individual.
*   A coluna `text` está entre aspas.