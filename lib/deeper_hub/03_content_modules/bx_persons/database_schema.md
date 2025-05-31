# Documentação Deeper: Esquema do BD Adicional para Pessoas (`bx_persons`) (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas específicas do módulo `bx_persons` do UNA que ainda não foram cobertas nas seções anteriores (como `sys_accounts`, `sys_profiles`, `bx_persons_data`).

## Tabela: `bx_persons_pictures`

```sql
CREATE TABLE IF NOT EXISTS bx_persons_pictures (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  profile_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil da pessoa à qual a foto pertence)
  remote_id TEXT, -- No UNA é VARCHAR(128) NOT NULL (ID do arquivo no storage)
  path TEXT NOT NULL, -- No UNA é VARCHAR(255)
  file_name TEXT NOT NULL, -- No UNA é VARCHAR(255)
  mime_type TEXT NOT NULL, -- No UNA é VARCHAR(128)
  ext TEXT NOT NULL, -- No UNA é VARCHAR(32)
  size INTEGER NOT NULL, -- No UNA é BIGINT(20)
  dimensions TEXT, -- Ex: '800x600'. No UNA é VARCHAR(12)
  added INTEGER NOT NULL, -- Unix Timestamp
  modified INTEGER NOT NULL, -- Unix Timestamp
  private INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é INT(11)
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- UNIQUE KEY remote_id (remote_id) no UNA original. Se remote_id for um UUID ou hash único, pode ser UNIQUE.
);
CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_profile_id ON bx_persons_pictures(profile_id);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_pictures_remote_id ON bx_persons_pictures(remote_id) WHERE remote_id IS NOT NULL AND remote_id != ''; -- Condicional para permitir nulos/vazios se não forem UNIQUE
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_pictures_resized (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  profile_id INTEGER NOT NULL, -- FK para sys_profiles.id
  remote_id TEXT NOT NULL, -- ID do arquivo redimensionado no storage
  path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  ext TEXT NOT NULL,
  size INTEGER NOT NULL, -- BIGINT(20)
  added INTEGER NOT NULL, -- Unix Timestamp
  modified INTEGER NOT NULL, -- Unix Timestamp
  private INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- UNIQUE KEY remote_id (remote_id) no UNA original.
);
CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_resized_profile_id ON bx_persons_pictures_resized(profile_id);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_persons_pictures_resized_remote_id ON bx_persons_pictures_resized(remote_id);
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_views_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil que foi visto)
  viewer_id INTEGER NOT NULL DEFAULT 0, -- FK para sys_profiles.id (o perfil do visualizador, 0 se anônimo)
  viewer_nip INTEGER, -- IP do visualizador como inteiro. No UNA é INT(11) UNSIGNED
  date INTEGER NOT NULL, -- Unix Timestamp
  FOREIGN KEY (object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- FK para viewer_id (sys_profiles.id) - CUIDADO: viewer_id pode ser 0 (anônimo), então FK pode falhar ou precisar de condição.
  -- Melhor não ter FK estrita em viewer_id se 0 for permitido.
);
CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_object_id ON bx_persons_views_track(object_id);
CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_viewer_id ON bx_persons_views_track(viewer_id) WHERE viewer_id != 0;
CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_date ON bx_persons_views_track(date);
```

```sql
-- Se o UNA usa uma tabela de comentários específica para pessoas, em vez de um sistema genérico.
-- Se usar o sistema genérico sys_cmts_*, esta tabela pode não ser necessária ou seria um stub.
-- Para este exemplo, vamos assumir que existe para demonstrar.
CREATE TABLE IF NOT EXISTS bx_persons_cmts (
  cmt_id INTEGER PRIMARY KEY AUTOINCREMENT,
  cmt_parent_id INTEGER NOT NULL DEFAULT 0, -- Para respostas aninhadas
  cmt_vparent_id INTEGER NOT NULL DEFAULT 0, -- View parent ID
  cmt_object_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil que está sendo comentado)
  cmt_author_id INTEGER NOT NULL, -- FK para sys_profiles.id (o autor do comentário)
  cmt_level INTEGER NOT NULL DEFAULT 0,
  cmt_text TEXT NOT NULL,
  cmt_mood INTEGER NOT NULL DEFAULT 0, -- TINYINT(4)
  cmt_rate INTEGER NOT NULL DEFAULT 0,
  cmt_rate_count INTEGER NOT NULL DEFAULT 0,
  cmt_time INTEGER NOT NULL, -- Unix Timestamp
  cmt_replies INTEGER NOT NULL DEFAULT 0,
  cmt_pinned INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  cmt_cf INTEGER NOT NULL DEFAULT 1, -- Content Filter ID?
  FOREIGN KEY (cmt_object_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (cmt_author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_object_parent ON bx_persons_cmts(cmt_object_id, cmt_parent_id);
CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_author_id ON bx_persons_cmts(cmt_author_id);
-- FULLTEXT KEY search_fields (cmt_text) do MySQL -> Usar FTS do SQLite se necessário.
```

*   Armazena informações sobre as imagens da galeria de um perfil de pessoa.
*   `profile_id` refere-se ao `sys_profiles.id` da pessoa.
*   `remote_id`, `path`, etc., referem-se a um sistema de armazenamento de arquivos (que será detalhado em `06_file_management/` com `sys_files`).

## Tabela: `bx_persons_pictures_resized`

*   Armazena informações sobre versões redimensionadas das imagens de `bx_persons_pictures`.

## Tabela: `bx_persons_views_track`

*   Rastreia visualizações de perfis. `object_id` é o `sys_profiles.id` do perfil visualizado.

## Tabela: `bx_persons_cmts` (Comentários Específicos de Pessoas)

*   **Nota:** O UNA moderno tende a usar um sistema de comentários genérico (`sys_cmts_*` e `sys_objects_cmts`). Se for o caso, esta tabela `bx_persons_cmts` seria substituída pela configuração de um objeto `sys_objects_cmts` chamado, por exemplo, `bx_persons_notes` ou similar, que usaria as tabelas genéricas `sys_cmts_*`. A API para comentários seria então através do sistema genérico de comentários (em `04_interaction_systems/`).

## Tabelas de Tracking Genéricas (Exemplos para `bx_persons`):

As seguintes tabelas (`_favorites_track`, `_reports_track`, `_scores_track`, `_votes_track`) seguem um padrão similar e seriam usadas em conjunto com as tabelas de configuração `sys_objects_favorite`, `sys_objects_report`, `sys_objects_score`, `sys_objects_vote` para implementar essas funcionalidades para perfis de pessoas.

*   **`bx_persons_favorites_track`**
    *   `id` INTEGER PK AUTOINCREMENT
    *   `object_id` INTEGER NOT NULL (FK para `sys_profiles.id` - o perfil favoritado)
    *   `author_id` INTEGER NOT NULL (FK para `sys_profiles.id` - quem favoritou)
    *   `date` INTEGER NOT NULL (Unix Timestamp)
    *   `PRIMARY KEY (object_id, author_id)` ou `UNIQUE (object_id, author_id)` se `id` for PK.

*   **`bx_persons_reports_track`**
    *   `id` INTEGER PK AUTOINCREMENT
    *   `object_id` INTEGER NOT NULL (FK para `sys_profiles.id` - o perfil denunciado)
    *   `author_id` INTEGER NOT NULL (FK para `sys_profiles.id` - quem denunciou)
    *   `author_nip` INTEGER (IP do autor)
    *   `type` TEXT (tipo da denúncia)
    *   `text` TEXT (detalhes da denúncia)
    *   `date` INTEGER NOT NULL (Unix Timestamp)
    *   `checked_by` INTEGER (ID do admin que verificou)
    *   `status` INTEGER (status da denúncia)

*   **`bx_persons_scores_track`** (Para sistema de Up/Down)
    *   `id` INTEGER PK AUTOINCREMENT
    *   `object_id` INTEGER NOT NULL (FK para `sys_profiles.id`)
    *   `author_id` INTEGER NOT NULL (FK para `sys_profiles.id`)
    *   `author_nip` INTEGER
    *   `type` TEXT ('up' ou 'down')
    *   `date` INTEGER NOT NULL

*   **`bx_persons_votes_track`** (Para sistema de Avaliação por Estrelas/Valor)
    *   `id` INTEGER PK AUTOINCREMENT
    *   `object_id` INTEGER NOT NULL (FK para `sys_profiles.id`)
    *   `author_id` INTEGER NOT NULL (FK para `sys_profiles.id`)
    *   `author_nip` INTEGER
    *   `value` INTEGER NOT NULL (ex: 1 a 5)
    *   `date` INTEGER NOT NULL

## Tabelas de Metadados e Habilidades:

*   **`bx_persons_meta_keywords`**
    *   `id` INTEGER PK AUTOINCREMENT
    *   `object_id` INTEGER NOT NULL (FK para `sys_profiles.id`)
    *   `keyword` TEXT NOT NULL
    *   Índices em `object_id` e `keyword`.

*   **`bx_persons_meta_locations`**
    *   `object_id` INTEGER PRIMARY KEY (FK para `sys_profiles.id`)
    *   `lat` REAL, `lng` REAL
    *   `country` TEXT, `state` TEXT, `city` TEXT, `zip` TEXT, `street` TEXT, `street_number` TEXT
    *   Índices apropriados para busca geográfica.

*   **`bx_persons_meta_mentions`**
    *   `id` INTEGER PK AUTOINCREMENT
    *   `object_id` INTEGER NOT NULL (FK para `sys_profiles.id` - o conteúdo onde a menção ocorre, ou o perfil mencionado)
    *   `profile_id` INTEGER NOT NULL (FK para `sys_profiles.id` - o perfil que foi mencionado)
    *   Índices em `object_id` e `profile_id`.

*   **`bx_persons_skills`**
    *   `skill_id` INTEGER PK AUTOINCREMENT
    *   `skill_name` TEXT
    *   `content_id` INTEGER NOT NULL (FK para `sys_profiles.id` - o perfil que possui a habilidade)
    *   Índice em `content_id`.

### Considerações sobre Chaves Estrangeiras:
*   Muitas dessas tabelas referenciam `sys_profiles.id` como `object_id` (o perfil que é o sujeito da ação) e `author_id` (o perfil que realiza a ação).
*   A integridade referencial com `ON DELETE CASCADE` deve ser considerada cuidadosamente para evitar perda de dados indesejada ou para garantir que dados relacionados sejam limpos quando um perfil é removido.