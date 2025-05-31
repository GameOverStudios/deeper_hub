# Documentação Deeper: Esquema do Banco de Dados para Módulo de Artigos/Posts (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao módulo de Artigos/Posts (`deeper_articles`).

## Tabela Principal: `deeper_articles`

```sql
CREATE TABLE IF NOT EXISTS deeper_articles (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- Autor do artigo
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE, -- Para URLs amigáveis, ex: \"meu-primeiro-artigo\"
  body TEXT NOT NULL, -- Conteúdo principal do artigo
  excerpt TEXT, -- Resumo curto ou introdução
  featured_image_file_id INTEGER, -- FK para deeper_files.id
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'archived', 'pending_review')),
  visibility TEXT NOT NULL DEFAULT 'public', -- Simplificado: 'public', 'private' (para o autor), 'unlisted' (acesso por link). Pode ser integrado com ACL para mais granularidade.
  allow_comments INTEGER NOT NULL DEFAULT 1, -- 0 para não permitir, 1 para permitir
  published_at INTEGER, -- Unix Timestamp de quando foi publicado (NULL se não publicado)
  views INTEGER NOT NULL DEFAULT 0,
  -- Contadores para votos, comentários, favoritos serão gerenciados pelas tabelas de sistema
  -- como sys_cmts_ids, sys_votes (usando o 'deeper_articles' + article_id como object_id)
  created_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL, -- Unix Timestamp
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL, -- Ou CASCADE se artigos devem ser deletados com o perfil
  FOREIGN KEY (featured_image_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL -- Se a imagem for deletada, o campo fica NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_articles_profile_id ON deeper_articles(profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_articles_slug ON deeper_articles(slug);
CREATE INDEX IF NOT EXISTS idx_deeper_articles_status ON deeper_articles(status);
CREATE INDEX IF NOT EXISTS idx_deeper_articles_published_at ON deeper_articles(published_at);
CREATE INDEX IF NOT EXISTS idx_deeper_articles_created_at ON deeper_articles(created_at);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_article_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE, -- Para URLs de categorias
  description TEXT,
  parent_id INTEGER, -- Para categorias aninhadas/hierárquicas
  FOREIGN KEY (parent_id) REFERENCES deeper_article_categories(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_article_categories_slug ON deeper_article_categories(slug);
CREATE INDEX IF NOT EXISTS idx_deeper_article_categories_parent_id ON deeper_article_categories(parent_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_articles_to_categories (
  article_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  PRIMARY KEY (article_id, category_id),
  FOREIGN KEY (article_id) REFERENCES deeper_articles(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES deeper_article_categories(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_datc_category_id_article_id ON deeper_articles_to_categories(category_id, article_id);
```

*   **`slug`**: Usado para criar URLs amigáveis. Deve ser único e gerado a partir do título.
*   **`body`**: Pode armazenar HTML, Markdown, ou outro formato de rich text. A API e o cliente devem concordar sobre o formato.
*   **`featured_image_file_id`**: Link para uma imagem de destaque na tabela `deeper_files`.
*   **`status`**: Controla o estado de publicação do artigo.
*   **`visibility`**: Um controle de privacidade simplificado. No UNA, isso seria gerenciado por `allow_view_to` e `sys_objects_privacy`. Para \"Deeper\", podemos começar simples e integrar com um sistema de ACL mais granular depois, se necessário, ou usar o `profile_id` para acesso privado.
*   **`published_at`**: Importante para ordenação e para saber quando o artigo se tornou público.
*   Contadores como `views`, `votes`, `comments` foram omitidos da tabela principal. A filosofia do UNA é geralmente ter esses contadores nas tabelas de \"objetos\" (ex: `sys_objects_vote` teria uma entrada para `object_name='deeper_articles'` e a tabela de votos teria `object_id=article_id`). Ou, no sistema UNA mais antigo, a tabela de conteúdo principal teria esses contadores atualizados por triggers ou pela aplicação. Para \"Deeper\", podemos optar por buscar esses contadores dinamicamente das tabelas de interação (ex: `COUNT(*)` de comentários para um artigo) ou ter uma tabela de sumário atualizada, dependendo dos requisitos de performance. Inicialmente, omitir da tabela principal simplifica.

## Tabela: `deeper_article_categories` (Para definir categorias)

*   Define as categorias disponíveis para os artigos.

## Tabela de Junção: `deeper_articles_to_categories` (Muitos-para-Muitos)

*   Liga artigos a uma ou mais categorias.

Este esquema fornece uma base para um módulo de artigos/posts. Funcionalidades como tags poderiam ser adicionadas com uma estrutura similar à de categorias (uma tabela `deeper_article_tags` e uma tabela de junção `deeper_articles_to_tags`).