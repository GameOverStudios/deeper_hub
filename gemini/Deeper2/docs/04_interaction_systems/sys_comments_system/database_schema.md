# Documentação Deeper: Esquema do BD para Sistema de Comentários Genérico (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas centrais do sistema de comentários genérico do UNA, bem como um exemplo de uma tabela de conteúdo de comentários específica de um módulo.

## Tabela: `sys_objects_cmts` (Configuração)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_cmts (
  ID INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(10) UNSIGNED
  Name TEXT NOT NULL UNIQUE, -- Nome único do objeto de comentários, ex: 'bx_persons_profile_cmts'
  Module TEXT NOT NULL, -- Módulo ao qual este objeto de comentários pertence
  \"Table\" TEXT NOT NULL, -- Nome da tabela SQL que armazena os comentários para este objeto
  CharsPostMin INTEGER NOT NULL DEFAULT 1,
  CharsPostMax INTEGER NOT NULL DEFAULT 2048,
  CharsDisplayMax INTEGER NOT NULL DEFAULT 1000,
  Html INTEGER NOT NULL DEFAULT 0, -- 0 ou 1 (se HTML é permitido nos comentários)
  PerView INTEGER NOT NULL DEFAULT 10, -- Comentários por página/bloco
  PerViewReplies INTEGER NOT NULL DEFAULT 3, -- Respostas por página/bloco
  BrowseType TEXT NOT NULL DEFAULT 'tail', -- Ex: 'head', 'tail', 'popular'
  IsBrowseSwitch INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  PostFormPosition TEXT NOT NULL DEFAULT 'bottom', -- Ex: 'top', 'bottom'
  NumberOfLevels INTEGER NOT NULL DEFAULT 0, -- 0 para ilimitado
  IsDisplaySwitch INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  IsRatable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se comentários podem ser votados)
  ViewingThreshold INTEGER NOT NULL DEFAULT -3, -- Limite de rating para visualização
  IsOn INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se este sistema de comentários está ativo)
  RootStylePrefix TEXT NOT NULL DEFAULT 'cmt',
  BaseUrl TEXT NOT NULL, -- URL base para links de comentários
  ObjectVote TEXT, -- Nome do objeto sys_objects_vote para votos em comentários
  ObjectReaction TEXT, -- Nome do objeto sys_objects_reaction para reações em comentários
  ObjectScore TEXT, -- Nome do objeto sys_objects_score para scores em comentários
  ObjectReport TEXT, -- Nome do objeto sys_objects_report para denúncias de comentários
  TriggerTable TEXT, -- Tabela de conteúdo principal a ser atualizada (ex: bx_persons_data)
  TriggerFieldId TEXT, -- Nome da coluna ID na TriggerTable
  TriggerFieldAuthor TEXT, -- Nome da coluna autor na TriggerTable
  TriggerFieldTitle TEXT, -- Nome da coluna título na TriggerTable
  TriggerFieldComments TEXT, -- Nome da coluna de contagem de comentários na TriggerTable
  ClassName TEXT, -- Classe PHP no UNA
  ClassFile TEXT -- Arquivo da classe PHP no UNA
  -- FK para Module (sys_modules.name)
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_cmts_name ON sys_objects_cmts(Name);
CREATE INDEX IF NOT EXISTS idx_sys_objects_cmts_module ON sys_objects_cmts(Module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_cmts_ids (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- Chave primária interna desta tabela
  system_id INTEGER NOT NULL, -- FK para sys_objects_cmts.ID
  cmt_id INTEGER NOT NULL, -- ID do comentário na sua tabela de conteúdo específica (ex: bx_persons_cmts.cmt_id)
  author_id INTEGER NOT NULL, -- FK para sys_profiles.id (autor do comentário)
  rate REAL NOT NULL DEFAULT 0,
  votes INTEGER NOT NULL DEFAULT 0,
  rrate REAL NOT NULL DEFAULT 0, -- Recursive rate?
  rvotes INTEGER NOT NULL DEFAULT 0, -- Recursive votes?
  score INTEGER NOT NULL DEFAULT 0,
  sc_up INTEGER NOT NULL DEFAULT 0,
  sc_down INTEGER NOT NULL DEFAULT 0,
  reports INTEGER NOT NULL DEFAULT 0,
  status_admin TEXT NOT NULL DEFAULT 'active' CHECK(status_admin IN ('active', 'hidden', 'pending')),
  FOREIGN KEY (system_id) REFERENCES sys_objects_cmts(ID) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE -- Autor pode ser deletado
  -- UNIQUE (system_id, cmt_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_cmts_ids_system_cmt ON sys_cmts_ids(system_id, cmt_id);
CREATE INDEX IF NOT EXISTS idx_sys_cmts_ids_author_id ON sys_cmts_ids(author_id);
```

```sql
-- EXEMPLO: Se sys_objects_cmts.Table = 'bx_sample_content_cmts'
CREATE TABLE IF NOT EXISTS bx_sample_content_cmts (
  cmt_id INTEGER PRIMARY KEY AUTOINCREMENT,
  cmt_parent_id INTEGER NOT NULL DEFAULT 0, -- Para respostas (ID do comentário pai nesta mesma tabela)
  cmt_vparent_id INTEGER NOT NULL DEFAULT 0, -- View parent ID (para UI, geralmente o cmt_id do comentário raiz da thread)
  cmt_object_id INTEGER NOT NULL, -- ID do item de conteúdo que está sendo comentado (ex: bx_persons_data.id, bx_posts.id)
  cmt_author_id INTEGER NOT NULL, -- FK para sys_profiles.id (autor do comentário)
  cmt_level INTEGER NOT NULL DEFAULT 0, -- Nível de aninhamento
  cmt_text TEXT NOT NULL,
  cmt_mood INTEGER NOT NULL DEFAULT 0, -- TINYINT(4)
  cmt_time INTEGER NOT NULL, -- Unix Timestamp
  cmt_replies INTEGER NOT NULL DEFAULT 0, -- Contagem de respostas diretas
  cmt_pinned INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  -- Colunas como cmt_rate, cmt_rate_count, cmt_reports foram movidas para sys_cmts_ids no UNA mais recente.
  -- cmt_cf (Content Filter) pode ainda estar aqui ou ser gerenciado de outra forma.
  FOREIGN KEY (cmt_author_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
  -- A FK para cmt_object_id depende do tipo de conteúdo, não pode ser definida genericamente aqui.
  -- A FK para cmt_parent_id (auto-referência)
);
CREATE INDEX IF NOT EXISTS idx_bx_sample_content_cmts_object_parent ON bx_sample_content_cmts(cmt_object_id, cmt_parent_id);
CREATE INDEX IF NOT EXISTS idx_bx_sample_content_cmts_vparent ON bx_sample_content_cmts(cmt_vparent_id);
CREATE INDEX IF NOT EXISTS idx_bx_sample_content_cmts_author_id ON bx_sample_content_cmts(cmt_author_id);
```

*   Define cada sistema de comentários para diferentes partes do site.
*   A coluna `\"Table\"` é crucial, pois indica qual tabela contém os dados dos comentários.

## Tabela: `sys_cmts_ids` (Metadados e Status dos Comentários)

*   Armazena metadados e status para cada comentário individual, independentemente de qual sistema de comentários ele pertença.
*   `cmt_id` aqui é o ID do comentário na sua tabela de armazenamento real (definida em `sys_objects_cmts.Table`).

## Exemplo de Tabela de Conteúdo de Comentários (Conforme `sys_objects_cmts.Table`)

O nome desta tabela é dinâmico, vindo de `sys_objects_cmts.Table`. Ex: `bx_module_entity_cmts`.
A estrutura é geralmente padronizada.

*   **Importante:** A API \"Deeper\" precisará ler `sys_objects_cmts.Table` para saber qual tabela de conteúdo de comentários consultar para um determinado `object_interaction_name`. As migrações para estas tabelas de conteúdo de comentários podem precisar ser gerenciadas dinamicamente ou criadas para cada objeto de comentário conhecido.

## Outras Tabelas de Suporte (Interações *nos* Comentários)

Se os comentários em si podem ser votados, denunciados, etc. (configurado em `sys_objects_cmts.ObjectVote`, etc.), então as tabelas de tracking dessas interações (ex: `sys_cmts_votes_track`, `sys_cmts_reports_track`) também seriam relevantes. Elas seguem o padrão das tabelas de tracking já vistas (ex: `bx_persons_votes_track`), mas o `object_id` nelas referenciaria o `cmt_id` (via `sys_cmts_ids.id`).

Exemplo: `sys_cmts_votes_track`
*   `object_id` (FK para `sys_cmts_ids.id` - o comentário sendo votado)
*   `author_id` (FK para `sys_profiles.id` - quem votou no comentário)
*   `value`, `date`, etc.

As migrações para essas sub-interações seriam parte de seus respectivos sistemas (ex: o sistema de votos lidaria com `sys_cmts_votes_track` se `sys_objects_vote` apontasse para ele).