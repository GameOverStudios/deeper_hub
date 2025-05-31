# Documentação Deeper: Esquema do Banco de Dados para Módulo Pessoas (`bx_persons`) (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas primárias e de suporte do módulo \"Pessoas\" (`bx_persons`) do UNA.

**Tabelas Principais:**

1.  **`bx_persons_data`**: Armazena os dados detalhados dos perfis de pessoa.
    *   *Definição já fornecida em `docs/01_system_core/sys_accounts_and_profiles/database_schema.md` e será referenciada/confirmada aqui.*

2.  **`bx_persons_pictures`**: Armazena informações sobre as imagens originais dos avatares/fotos dos perfis.
3.  **`bx_persons_pictures_resized`**: Armazena informações sobre as versões redimensionadas das imagens de perfil.
4.  **`bx_persons_views_track`**: Rastreia visualizações de perfis de pessoas.
5.  **`bx_persons_cmts`**: Comentários específicos para perfis de pessoas (se o sistema de comentários genérico `sys_cmts_*` não for usado ou se houver campos adicionais).
    *   *Nota: O UNA tem um sistema de comentários genérico (`sys_cmts_`, `sys_objects_cmts`). Se `bx_persons_cmts` for apenas uma instância desse sistema sem campos extras, podemos não precisar de uma tabela separada, mas sim configurar o objeto `sys_objects_cmts` para `bx_persons`.* Vamos assumir por enquanto que ela pode ter campos específicos ou uma estrutura que o UNA mantém separada.
6.  Outras tabelas de rastreamento de interações como `bx_persons_favorites_track`, `bx_persons_scores_track`, `bx_persons_votes_track`, `bx_persons_reports_track` (se não forem cobertas por sistemas genéricos e a API precisar interagir diretamente com elas).

---
## Tabela: `bx_persons_data`

*Referência: A definição completa e atualizada desta tabela está em `docs/01_system_core/sys_accounts_and_profiles/database_schema.md`.*

```sql
-- CREATE TABLE IF NOT EXISTS bx_persons_data ( ... ); -- Definição completa lá
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_pictures (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- FK para bx_persons_data.id (o perfil da pessoa a quem a foto pertence)
  remote_id TEXT NOT NULL UNIQUE, -- ID do arquivo no sistema de armazenamento (ex: S3 key, ou ID de sys_files)
  path TEXT NOT NULL, -- Caminho relativo ou URL para o arquivo original
  file_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  ext TEXT NOT NULL,
  size INTEGER NOT NULL, -- Tamanho em bytes
  dimensions TEXT, -- Ex: \"800x600\"
  added INTEGER NOT NULL, -- Unix Timestamp
  modified INTEGER NOT NULL, -- Unix Timestamp
  private INTEGER NOT NULL DEFAULT 0, -- 0 para público, 1 para privado
  FOREIGN KEY (profile_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_profile_id ON bx_persons_pictures(profile_id);
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_pictures_resized (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- FK para bx_persons_data.id
  remote_id TEXT NOT NULL UNIQUE, -- ID do arquivo redimensionado no sistema de armazenamento
  -- original_id INTEGER, -- Opcional: FK para bx_persons_pictures.id se precisar linkar com o original
  path TEXT NOT NULL,
  file_name TEXT NOT NULL,
  mime_type TEXT NOT NULL,
  ext TEXT NOT NULL,
  size INTEGER NOT NULL,
  -- dimensions TEXT, -- Dimensões da imagem redimensionada, se necessário
  added INTEGER NOT NULL,
  modified INTEGER NOT NULL,
  private INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (profile_id) REFERENCES bx_persons_data(id) ON DELETE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_bx_persons_pictures_resized_profile_id ON bx_persons_pictures_resized(profile_id);
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_views_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object_id INTEGER NOT NULL, -- ID do bx_persons_data.id que foi visualizado
  viewer_id INTEGER NOT NULL DEFAULT 0, -- ID do perfil (sys_profiles.id) do visualizador (0 se anônimo)
  viewer_nip INTEGER, -- IP do visualizador como inteiro (NETWORK_IP)
  date INTEGER NOT NULL -- Unix Timestamp da visualização
);

CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_object_id_date ON bx_persons_views_track(object_id, date);
CREATE INDEX IF NOT EXISTS idx_bx_persons_views_track_viewer_id ON bx_persons_views_track(viewer_id);
-- Considerar um índice UNIQUE(object_id, viewer_nip, date_trunc_day) se quiser contar uma visualização por IP/dia
```

```sql
CREATE TABLE IF NOT EXISTS bx_persons_cmts (
  cmt_id INTEGER PRIMARY KEY AUTOINCREMENT,
  cmt_parent_id INTEGER NOT NULL DEFAULT 0, -- Para respostas aninhadas
  cmt_vparent_id INTEGER NOT NULL DEFAULT 0, -- O ID do comentário raiz na thread (virtual parent)
  cmt_object_id INTEGER NOT NULL, -- ID do bx_persons_data.id a que o comentário pertence
  cmt_author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do autor do comentário
  cmt_level INTEGER NOT NULL DEFAULT 0, -- Nível de aninhamento
  cmt_text TEXT NOT NULL,
  cmt_mood INTEGER NOT NULL DEFAULT 0, -- Pequeno ícone/mood associado
  cmt_rate INTEGER NOT NULL DEFAULT 0, -- Soma das avaliações (se houver sistema de rate em comentários)
  cmt_rate_count INTEGER NOT NULL DEFAULT 0, -- Contagem de avaliações
  cmt_time INTEGER NOT NULL, -- Unix Timestamp
  cmt_replies INTEGER NOT NULL DEFAULT 0, -- Número de respostas diretas
  cmt_pinned INTEGER NOT NULL DEFAULT 0, -- 0 ou 1
  cmt_cf INTEGER NOT NULL DEFAULT 1 -- Content Filter (do UNA, pode ser ignorado/simplificado)
);

CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_object_parent ON bx_persons_cmts(cmt_object_id, cmt_parent_id);
CREATE INDEX IF NOT EXISTS idx_bx_persons_cmts_vparent ON bx_persons_cmts(cmt_vparent_id);
-- FULLTEXT KEY `search_fields` (`cmt_text`) -- Omitido para SQLite inicial, usar FTS5 depois se necessário.
```

**Campos Chave já definidos:** `id`, `author`, `added`, `changed`, `picture`, `cover`, `fullname`, `description`, `gender`, `birthday`, `location`, `views`, `rate`, `votes`, `score`, `sc_up`, `sc_down`, `favorites`, `comments`, `reports`, `featured`, `allow_view_to`, `allow_post_to`, `allow_contact_to`, `settings`.

---
## Tabela: `bx_persons_pictures` (Avatares/Fotos Originais)

*   **`profile_id`**: O ID do perfil (`bx_persons_data.id`) ao qual esta imagem pertence.
*   **`remote_id`**: Identificador único do arquivo no sistema de armazenamento.
*   **`path`, `file_name`**: Informações para localizar o arquivo.
*   **`dimensions`**: Pode ser útil para o cliente saber as dimensões originais.

---
## Tabela: `bx_persons_pictures_resized` (Versões Redimensionadas)

*   **Nota:** Esta tabela armazena ponteiros para diferentes tamanhos de uma imagem (thumbnail, médio, etc.). A lógica de qual `remote_id` usar para um contexto específico (ex: avatar na lista vs. avatar na página de perfil) pode ser gerenciada pela aplicação ou o cliente pode solicitar um \"tipo\" de imagem. O UNA usa um sistema de \"transcoders\" para isso. Para a API \"Deeper\", podemos simplificar inicialmente, talvez o cliente receba URLs para diferentes tamanhos com base em convenções.

---
## Tabela: `bx_persons_views_track` (Rastreamento de Visualizações)

*   **`object_id`**: O `id` do perfil (`bx_persons_data`) que foi visualizado.
*   **`viewer_id`**: O `id` do perfil (`sys_profiles`) de quem visualizou. `0` para anônimo.
*   **`viewer_nip`**: IP do visualizador (anonimizado ou convertido para inteiro).
*   **`date`**: Timestamp da visualização.
*   O contador `views` em `bx_persons_data` seria atualizado com base nos registros desta tabela (ex: por um job ou trigger).

---
## Tabela: `bx_persons_cmts` (Comentários em Perfis de Pessoas)

*Como mencionado, o UNA possui um sistema de comentários genérico. Se `bx_persons_cmts` for apenas uma instância dele, a definição seria idêntica à tabela de comentários genérica. Assumindo que pode haver pequenas diferenças ou que o UNA a mantém assim:*

*   **`cmt_object_id`**: O `id` do perfil (`bx_persons_data`) que está sendo comentado.

---
**Outras Tabelas de Interação (`bx_persons_favorites_track`, etc.):**

Estas tabelas (`bx_persons_favorites_track`, `bx_persons_meta_keywords`, `bx_persons_meta_locations`, `bx_persons_meta_mentions`, `bx_persons_reports_track`, `bx_persons_scores_track`, `bx_persons_skills`, `bx_persons_votes_track`) seguem padrões similares:

*   Um `object_id` ou `content_id` que referencia `bx_persons_data.id`.
*   Um `author_id` ou `profile_id` que referencia `sys_profiles.id` do usuário que realizou a ação.
*   Campos específicos da interação (ex: `keyword`, `lat`/`lng`, `type` de denúncia, `value` do voto).
*   Timestamps.

Elas serão detalhadas nas seções de migrações e módulos de acesso a dados conforme avançamos, e também em `04_interaction_systems` se a API fornecer endpoints genéricos para essas interações. Por agora, reconhecemos sua existência e o link principal com `bx_persons_data.id`.

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas do módulo `bx_persons`.