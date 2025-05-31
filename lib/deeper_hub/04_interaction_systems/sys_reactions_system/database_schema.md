# Documentação Deeper: Esquema do BD para Sistema de Reações Genérico (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema de reações genérico, incluindo uma tabela de configuração hipotética `sys_objects_reaction` e exemplos de tabelas de sumário e rastreamento.

## Tabela: `sys_objects_reaction` (Configuração - Hipotética/Adaptada)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_reaction (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE, -- Nome único do objeto de reação, ex: 'bx_posts_reactions'
  module TEXT NOT NULL,
  -- Lista de reações disponíveis (ex: JSON array ou string separada por vírgula, ou referência a sys_form_pre_lists.key)
  reactions_available TEXT NOT NULL DEFAULT '[\"like\", \"love\", \"haha\", \"wow\", \"sad\", \"angry\"]',
  table_summary TEXT NOT NULL, -- Tabela de sumário de reações (ex: bx_posts_reactions_summary)
  table_track TEXT NOT NULL, -- Tabela de rastreamento de reações (ex: bx_posts_reactions_track)
  is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se reação pode ser desfeita/alterada)
  is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  trigger_table TEXT,
  trigger_field_id TEXT,
  -- TriggerField para contagem total de reações ou campos separados por tipo de reação
  trigger_field_reactions_count TEXT, -- Ex: um campo JSON na trigger_table ou campos individuais
  class_name TEXT,
  class_file TEXT
  -- FK para Module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_name ON sys_objects_reaction(name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_reaction_module ON sys_objects_reaction(Module);
```

```sql
-- EXEMPLO: Se sys_objects_reaction.table_summary = 'bx_example_content_reactions_summary'
CREATE TABLE IF NOT EXISTS bx_example_content_reactions_summary (
  object_id INTEGER NOT NULL, -- ID do item de conteúdo que recebeu reações
  reaction_type TEXT NOT NULL, -- Tipo da reação (ex: 'like', 'love')
  count INTEGER NOT NULL DEFAULT 0, -- Número total desta reação para este objeto
  PRIMARY KEY (object_id, reaction_type)
  -- A FK para object_id dependeria do tipo de conteúdo.
);
CREATE INDEX IF NOT EXISTS idx_bx_example_reactions_summary_object_id ON bx_example_content_reactions_summary(object_id);
```

```sql
-- EXEMPLO: Se sys_objects_reaction.table_track = 'bx_example_content_reactions_track'
CREATE TABLE IF NOT EXISTS bx_example_content_reactions_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object_id INTEGER NOT NULL, -- ID do item de conteúdo que recebeu a reação
  author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem reagiu)
  reaction_type TEXT NOT NULL, -- Tipo da reação (ex: 'like', 'love')
  date INTEGER NOT NULL, -- Unix Timestamp
  -- A FK para object_id dependeria do tipo de conteúdo.
  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- Garante que um autor dê apenas uma reação para um objeto.
-- Se o usuário puder mudar a reação, a lógica da aplicação faria um UPDATE na reaction_type.
CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_example_reactions_track_object_author ON bx_example_content_reactions_track(object_id, author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_reactions_track_object_id ON bx_example_content_reactions_track(object_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_reactions_track_author_id ON bx_example_content_reactions_track(author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_reactions_track_object_reaction ON bx_example_content_reactions_track(object_id, reaction_type);
```

*   Define cada sistema de \"reações\".
*   `reactions_available`: Define quais reações são permitidas para este objeto.

## Exemplo de Tabela de Sumário de Reações (`table_summary`)

O nome desta tabela é dinâmico, vindo de `sys_objects_reaction.table_summary`.

*   Armazena a contagem de cada tipo de reação para cada item de conteúdo.

## Exemplo de Tabela de Rastreamento de Reações (`table_track`)

O nome desta tabela é dinâmico, vindo de `sys_objects_reaction.table_track`.

*   Registra cada reação individual.
*   `reaction_type` deve ser um dos valores definidos em `sys_objects_reaction.reactions_available`.