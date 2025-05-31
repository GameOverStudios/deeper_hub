# Documentação Deeper: Esquema do BD para Sistema de Votos/Avaliações (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite da tabela de configuração `sys_objects_vote` e exemplos de tabelas de sumário (`TableMain`) e rastreamento (`TableTrack`) usadas pelo sistema de votos/avaliações genérico do UNA.

## Tabela: `sys_objects_vote` (Configuração)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_vote (
  ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11) UNSIGNED
  Name TEXT NOT NULL UNIQUE, -- Nome único do objeto de voto, ex: 'bx_persons_ratings'
  Module TEXT NOT NULL,
  TableMain TEXT NOT NULL, -- Nome da tabela de sumário dos votos (ex: bx_persons_votes)
  TableTrack TEXT NOT NULL, -- Nome da tabela de rastreamento de votos individuais (ex: bx_persons_votes_track)
  PostTimeout INTEGER NOT NULL DEFAULT 0, -- Em segundos
  MinValue INTEGER NOT NULL DEFAULT 1, -- TINYINT(4)
  MaxValue INTEGER NOT NULL DEFAULT 5, -- TINYINT(4)
  Pruning INTEGER NOT NULL DEFAULT 31536000, -- Em segundos (1 ano)
  IsUndo INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se voto pode ser desfeito/alterado)
  IsOn INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se este sistema está ativo)
  TriggerTable TEXT, -- Tabela de conteúdo principal a ser atualizada
  TriggerFieldId TEXT, -- Nome da coluna ID na TriggerTable
  TriggerFieldAuthor TEXT,
  TriggerFieldRate TEXT, -- Nome da coluna para a média da avaliação na TriggerTable
  TriggerFieldRateCount TEXT, -- Nome da coluna para a contagem de votos na TriggerTable
  ClassName TEXT,
  ClassFile TEXT
  -- FK para Module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_vote_name ON sys_objects_vote(Name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_vote_module ON sys_objects_vote(Module);
```

```sql
-- EXEMPLO: Se sys_objects_vote.TableMain = 'bx_example_content_votes'
CREATE TABLE IF NOT EXISTS bx_example_content_votes (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA, a PK pode ser só 'id' ou 'object_id'
  object_id INTEGER NOT NULL UNIQUE, -- ID do item de conteúdo que foi votado
  count INTEGER NOT NULL DEFAULT 0, -- Número total de votos
  sum INTEGER NOT NULL DEFAULT 0 -- Soma de todos os valores de votos
  -- A FK para object_id depende do tipo de conteúdo, não pode ser definida genericamente aqui.
);
CREATE INDEX IF NOT EXISTS idx_bx_example_content_votes_object_id ON bx_example_content_votes(object_id);
```

```sql
-- EXEMPLO: Se sys_objects_vote.TableTrack = 'bx_example_content_votes_track'
CREATE TABLE IF NOT EXISTS bx_example_content_votes_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object_id INTEGER NOT NULL, -- ID do item de conteúdo que foi votado
  author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem votou)
  author_nip INTEGER NOT NULL, -- IP do autor como inteiro
  value INTEGER NOT NULL, -- O valor do voto (ex: 1 a 5)
  date INTEGER NOT NULL, -- Unix Timestamp
  -- A FK para object_id depende do tipo de conteúdo.
  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- UNIQUE (object_id, author_id) para garantir que um autor vote apenas uma vez
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_example_votes_track_object_author ON bx_example_content_votes_track(object_id, author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_votes_track_object_id ON bx_example_content_votes_track(object_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_votes_track_author_id ON bx_example_content_votes_track(author_id);
```

*   Define cada sistema de votação para diferentes partes do site.

## Exemplo de Tabela de Sumário de Votos (`TableMain`)

O nome desta tabela é dinâmico, vindo de `sys_objects_vote.TableMain`. Ex: `bx_persons_votes`.

*   Armazena dados agregados dos votos para cada item de conteúdo.

## Exemplo de Tabela de Rastreamento de Votos (`TableTrack`)

O nome desta tabela é dinâmico, vindo de `sys_objects_vote.TableTrack`. Ex: `bx_persons_votes_track`.

*   Registra cada voto individual.

### Nota sobre Nomes de Tabela Dinâmicos:
As migrações reais para as tabelas `TableMain` e `TableTrack` precisariam ser gerenciadas com base nos valores existentes em `sys_objects_vote` no banco de dados UNA original, ou criadas para cada objeto de voto conhecido durante a configuração do \"Deeper\".