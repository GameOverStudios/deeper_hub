# Documentação Deeper: Esquema do Banco de Dados para Módulo de Fóruns (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao módulo de Fóruns (`deeper_forums`).

## Tabela: `deeper_forum_categories` (Opcional, para agrupar fóruns)

Se os fóruns em si puderem ser agrupados em categorias maiores.

```sql
CREATE TABLE IF NOT EXISTS deeper_forum_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0 -- Para ordenação manual
);

CREATE INDEX IF NOT EXISTS idx_dfc_slug ON deeper_forum_categories(slug);
CREATE INDEX IF NOT EXISTS idx_dfc_order_index ON deeper_forum_categories(order_index);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_forums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER, -- FK para deeper_forum_categories.id (opcional)
  title TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  order_index INTEGER NOT NULL DEFAULT 0, -- Para ordenação manual dos fóruns
  topics_count INTEGER NOT NULL DEFAULT 0, -- Contagem denormalizada de tópicos
  posts_count INTEGER NOT NULL DEFAULT 0, -- Contagem denormalizada de posts (respostas)
  last_topic_id INTEGER, -- FK para deeper_forum_topics.id (opcional)
  -- As colunas abaixo são para o último post *em qualquer tópico* dentro deste fórum.
  -- Pode ser mais complexo de manter atualizado do que o último post de um tópico específico.
  -- Uma alternativa é buscar dinamicamente ou ter um last_activity_ts.
  last_post_id INTEGER, -- FK para deeper_forum_posts.id
  last_post_profile_id INTEGER, -- FK para sys_profiles.id
  last_post_at INTEGER, -- Unix Timestamp
  -- Permissões de visualização/postagem podem ser definidas aqui ou via ACL mais granular
  -- Ex: visibility_level (public, members_only, etc.)
  -- Ex: posting_level (members, moderators, etc.)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (category_id) REFERENCES deeper_forum_categories(id) ON DELETE SET NULL,
  FOREIGN KEY (last_topic_id) REFERENCES deeper_forum_topics(id) ON DELETE SET NULL,
  FOREIGN KEY (last_post_id) REFERENCES deeper_forum_posts(id) ON DELETE SET NULL,
  FOREIGN KEY (last_post_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_df_slug ON deeper_forums(slug);
CREATE INDEX IF NOT EXISTS idx_df_category_id ON deeper_forums(category_id);
CREATE INDEX IF NOT EXISTS idx_df_order_index_title ON deeper_forums(order_index, title);
CREATE INDEX IF NOT EXISTS idx_df_last_post_at ON deeper_forums(last_post_at DESC);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_forum_topics (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  forum_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL, -- Autor do tópico (quem criou o primeiro post)
  title TEXT NOT NULL,
  slug TEXT NOT NULL, -- Slug gerado a partir do título, único dentro do fórum
  first_post_id INTEGER, -- FK para deeper_forum_posts.id (o post original do tópico)
  views_count INTEGER NOT NULL DEFAULT 0,
  replies_count INTEGER NOT NULL DEFAULT 0, -- Número de posts exceto o primeiro
  is_sticky INTEGER NOT NULL DEFAULT 0, -- 0 = não, 1 = sim (fixo no topo)
  is_locked INTEGER NOT NULL DEFAULT 0, -- 0 = aberto, 1 = trancado (sem novas respostas)
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'hidden_by_moderator', 'deleted_by_user')),
  -- Informações sobre a última resposta neste tópico
  last_post_id INTEGER, -- FK para deeper_forum_posts.id
  last_post_profile_id INTEGER, -- FK para sys_profiles.id
  last_post_at INTEGER, -- Unix Timestamp
  created_at INTEGER NOT NULL, -- Timestamp do primeiro post
  updated_at INTEGER NOT NULL, -- Timestamp da última edição do tópico ou do último post (depende da lógica)
  FOREIGN KEY (forum_id) REFERENCES deeper_forums(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL, -- Se o autor for deletado, o tópico permanece
  FOREIGN KEY (first_post_id) REFERENCES deeper_forum_posts(id) ON DELETE SET NULL, -- Ou CASCADE se o primeiro post deletado deleta o tópico
  FOREIGN KEY (last_post_id) REFERENCES deeper_forum_posts(id) ON DELETE SET NULL,
  FOREIGN KEY (last_post_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
  UNIQUE (forum_id, slug) -- Slug deve ser único por fórum
);

CREATE INDEX IF NOT EXISTS idx_dft_forum_id_is_sticky_last_post_at ON deeper_forum_topics(forum_id, is_sticky DESC, last_post_at DESC);
CREATE INDEX IF NOT EXISTS idx_dft_profile_id ON deeper_forum_topics(profile_id);
CREATE INDEX IF NOT EXISTS idx_dft_slug ON deeper_forum_topics(slug); -- Se slugs globais forem necessários, senão o UNIQUE(forum_id, slug) é suficiente
CREATE INDEX IF NOT EXISTS idx_dft_last_post_at ON deeper_forum_topics(last_post_at DESC);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_forum_posts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  topic_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL, -- Autor do post
  parent_post_id INTEGER, -- Para respostas aninhadas ou citações, FK para deeper_forum_posts.id
  body TEXT NOT NULL, -- Conteúdo do post (HTML, Markdown, BBCode)
  ip_address TEXT, -- Opcional, para moderação
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'hidden_by_moderator', 'deleted_by_user')),
  -- Contadores de votos/reações podem ser armazenados aqui se não usar o sistema genérico
  -- Ou referenciar o sistema genérico com object_name=\"deeper_forum_posts\", object_id=id
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL, -- Timestamp da última edição
  edited_at INTEGER, -- Timestamp da última edição (se diferente de updated_at para outros fins)
  edited_by_profile_id INTEGER, -- Quem editou por último
  FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL,
  FOREIGN KEY (parent_post_id) REFERENCES deeper_forum_posts(id) ON DELETE SET NULL, -- Ou CASCADE se respostas devem ser deletadas com o pai
  FOREIGN KEY (edited_by_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_dfp_topic_id_created_at ON deeper_forum_posts(topic_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_dfp_profile_id ON deeper_forum_posts(profile_id);
CREATE INDEX IF NOT EXISTS idx_dfp_parent_post_id ON deeper_forum_posts(parent_post_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_forum_read_topics (
  profile_id INTEGER NOT NULL,
  topic_id INTEGER NOT NULL,
  last_read_post_id INTEGER NOT NULL, -- ID do último post lido no tópico
  last_read_at INTEGER NOT NULL, -- Unix Timestamp
  PRIMARY KEY (profile_id, topic_id),
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
  FOREIGN KEY (last_read_post_id) REFERENCES deeper_forum_posts(id) ON DELETE CASCADE -- Ou SET NULL se posts podem ser deletados
);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_forum_subscriptions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL,
  forum_id INTEGER, -- Se está seguindo um fórum inteiro
  topic_id INTEGER, -- Se está seguindo um tópico específico
  subscription_type TEXT NOT NULL DEFAULT 'instant' CHECK(subscription_type IN ('instant', 'daily_digest', 'weekly_digest', 'none')), -- Tipo de notificação
  created_at INTEGER NOT NULL,
  UNIQUE (profile_id, forum_id) WHERE topic_id IS NULL,
  UNIQUE (profile_id, topic_id) WHERE forum_id IS NULL,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (forum_id) REFERENCES deeper_forums(id) ON DELETE CASCADE,
  FOREIGN KEY (topic_id) REFERENCES deeper_forum_topics(id) ON DELETE CASCADE,
  CHECK ((forum_id IS NOT NULL AND topic_id IS NULL) OR (forum_id IS NULL AND topic_id IS NOT NULL)) -- Deve seguir um fórum OU um tópico, não ambos na mesma linha
);

CREATE INDEX IF NOT EXISTS idx_dfs_profile_id_forum_id ON deeper_forum_subscriptions(profile_id, forum_id);
CREATE INDEX IF NOT EXISTS idx_dfs_profile_id_topic_id ON deeper_forum_subscriptions(profile_id, topic_id);
```

## Tabela: `deeper_forums` (Os fóruns de discussão)

*   **`category_id`**: Se os fóruns são agrupados.
*   **`topics_count`, `posts_count`**: Contagens denormalizadas para performance.
*   **`last_post_*`**: Informações sobre o último post feito em qualquer tópico deste fórum. Mantê-los atualizados requer lógica na aplicação ou triggers.

## Tabela: `deeper_forum_topics` (Tópicos de discussão)

*   **`forum_id`**: Liga o tópico ao fórum pai.
*   **`profile_id`**: O autor original do tópico.
*   **`first_post_id`**: Link para o conteúdo inicial do tópico na tabela `deeper_forum_posts`. É uma relação 1-para-1 um pouco incomum, mas comum em sistemas de fórum para separar metadados do tópico do seu conteúdo inicial.
*   **`replies_count`**: Número de posts de resposta.
*   **`last_post_*`**: Informações sobre o último post de resposta neste tópico.

## Tabela: `deeper_forum_posts` (Posts/Respostas nos tópicos)

*   **`topic_id`**: Liga o post ao tópico pai.
*   **`parent_post_id`**: Para estrutura de árvore/respostas aninhadas.
*   `status`: Permite moderação de posts individuais.

## Tabela: `deeper_forum_read_topics` (Para rastrear tópicos lidos por usuário)

*   Ajuda a UI a indicar quais tópicos/posts são novos para um usuário.

## Tabela: `deeper_forum_subscriptions` (Para usuários seguirem tópicos ou fóruns)

*   Permite que usuários recebam notificações sobre novos posts em fóruns ou tópicos que seguem.

Este conjunto de tabelas fornece uma base sólida para um módulo de fórum. A lógica para manter as contagens denormalizadas e as informações de \"último post\" atualizadas precisará ser implementada na camada de aplicação (Repos).