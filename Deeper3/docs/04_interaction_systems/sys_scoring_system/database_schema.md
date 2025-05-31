# Documentação Deeper: Esquema do BD para Sistema de Scores Genérico (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite da tabela de configuração `sys_objects_score` e exemplos de tabelas de sumário (`table_main`) e rastreamento (`table_track`) usadas pelo sistema de scores (upvote/downvote) genérico do UNA.

## Tabela: `sys_objects_score` (Configuração)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_score (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  name TEXT NOT NULL UNIQUE, -- Nome único do objeto de score, ex: 'bx_posts_scores'
  module TEXT NOT NULL,
  table_main TEXT NOT NULL, -- Tabela de sumário dos scores (ex: bx_posts_scores_summary)
  table_track TEXT NOT NULL, -- Tabela de rastreamento de scores individuais (ex: bx_posts_scores_track)
  post_timeout INTEGER NOT NULL DEFAULT 0, -- Em segundos
  pruning INTEGER NOT NULL DEFAULT 31536000, -- Em segundos (1 ano)
  is_undo INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se score pode ser desfeito/alterado)
  is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se este sistema está ativo)
  trigger_table TEXT, -- Tabela de conteúdo principal a ser atualizada
  trigger_field_id TEXT, -- Nome da coluna ID na TriggerTable
  trigger_field_author TEXT,
  trigger_field_score TEXT, -- Nome da coluna para o score total (up - down)
  trigger_field_cup TEXT, -- Nome da coluna para contagem de upvotes
  trigger_field_cdown TEXT, -- Nome da coluna para contagem de downvotes
  class_name TEXT,
  class_file TEXT
  -- FK para Module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_score_name ON sys_objects_score(name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_score_module ON sys_objects_score(Module);
```

```sql
-- EXEMPLO: Se sys_objects_score.table_main = 'bx_example_content_scores_summary'
CREATE TABLE IF NOT EXISTS bx_example_content_scores_summary (
  -- No UNA, bx_persons_scores tem: id (PK), object_id (UNIQUE), count_up, count_down
  object_id INTEGER PRIMARY KEY NOT NULL, -- ID do item de conteúdo que foi pontuado
  count_up INTEGER NOT NULL DEFAULT 0, -- Número total de upvotes
  count_down INTEGER NOT NULL DEFAULT 0 -- Número total de downvotes
  -- A FK para object_id dependeria do tipo de conteúdo específico.
);
-- Se object_id não for PK:
-- CREATE TABLE IF NOT EXISTS bx_example_content_scores_summary (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   object_id INTEGER NOT NULL UNIQUE,
--   count_up INTEGER NOT NULL DEFAULT 0,
--   count_down INTEGER NOT NULL DEFAULT 0
-- );
-- CREATE INDEX IF NOT EXISTS idx_bx_example_scores_summary_object_id ON bx_example_content_scores_summary(object_id);
```

```sql
-- EXEMPLO: Se sys_objects_score.table_track = 'bx_example_content_scores_track'
CREATE TABLE IF NOT EXISTS bx_example_content_scores_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object_id INTEGER NOT NULL, -- ID do item de conteúdo pontuado
  author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem pontuou)
  author_nip INTEGER NOT NULL, -- IP do autor como inteiro
  type TEXT NOT NULL CHECK(type IN ('up', 'down')), -- 'up' ou 'down'
  date INTEGER NOT NULL, -- Unix Timestamp
  -- A FK para object_id dependeria do tipo de conteúdo.
  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- Garante que um autor dê apenas um tipo de score (up OU down) para um objeto.
-- Se um usuário puder mudar de 'up' para 'down', a lógica da aplicação faria um UPDATE.
CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_example_scores_track_object_author ON bx_example_content_scores_track(object_id, author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_scores_track_object_id ON bx_example_content_scores_track(object_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_scores_track_author_id ON bx_example_content_scores_track(author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_scores_track_object_type ON bx_example_content_scores_track(object_id, type);
```

*   Define cada sistema de \"score\" para diferentes partes do site.

## Exemplo de Tabela de Sumário de Scores (`table_main`)

O nome desta tabela é dinâmico, vindo de `sys_objects_score.table_main`. Ex: `bx_persons_scores`.

*   Armazena dados agregados dos scores para cada item de conteúdo.

## Exemplo de Tabela de Rastreamento de Scores (`table_track`)

O nome desta tabela é dinâmico, vindo de `sys_objects_score.table_track`. Ex: `bx_persons_scores_track`.

*   Registra cada score individual (upvote/downvote).