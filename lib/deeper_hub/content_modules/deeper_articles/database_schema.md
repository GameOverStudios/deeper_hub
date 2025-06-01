# Documentação Deeper: Esquema do Banco de Dados para Artigos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas usadas pelo módulo de Artigos (`deeper_articles`).

## Tabela: `deeper_articles_entries` (Tabela Principal dos Artigos)

```sql
CREATE TABLE IF NOT EXISTS deeper_articles_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id do autor
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE, -- Para URL amigável (ex: 'meu-primeiro-artigo')
  summary TEXT, -- Resumo/excerpt
  body TEXT NOT NULL, -- Corpo completo do artigo (Markdown, HTML, ou texto simples)
  body_type TEXT NOT NULL DEFAULT 'markdown' CHECK(body_type IN ('markdown', 'html', 'text')),
  featured_image_id INTEGER, -- FK para uma futura tabela de arquivos/sys_files
  category_id INTEGER, -- FK para deeper_articles_categories.id (opcional, se usar categorias)
  status TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'pending', 'archived')),
  published_at INTEGER, -- Unix Timestamp de quando foi publicado (pode ser futuro para agendamento)
  views INTEGER NOT NULL DEFAULT 0,
  allow_view_to TEXT NOT NULL DEFAULT '3', -- ID do grupo de privacidade UNA
  meta_title TEXT,
  meta_description TEXT,
  created_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL, -- Unix Timestamp
  FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (category_id) REFERENCES deeper_articles_categories(id) ON DELETE SET NULL ON UPDATE CASCADE
  -- FOREIGN KEY (featured_image_id) REFERENCES deeper_files(id) ON DELETE SET NULL ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_deeper_articles_author_id ON deeper_articles_entries(author_profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_articles_category_id ON deeper_articles_entries(category_id);
CREATE INDEX IF NOT EXISTS idx_deeper_articles_status_published_at ON deeper_articles_entries(status, published_at);
-- O índice em slug é criado pela constraint UNIQUE.
```

```sql
CREATE TABLE IF NOT EXISTS deeper_articles_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER DEFAULT 0, -- Para hierarquia de categorias
  name TEXT NOT NULL, -- Nome da categoria
  slug TEXT NOT NULL UNIQUE, -- Slug para URL
  description TEXT,
  item_count INTEGER NOT NULL DEFAULT 0, -- Cache da contagem de artigos nesta categoria
  \"order\" INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
  -- FOREIGN KEY (parent_id) REFERENCES deeper_articles_categories(id) ON DELETE SET DEFAULT ON UPDATE CASCADE
  -- No SQLite, auto-referência de FK precisa ser bem pensada ou gerenciada pela app.
  -- ON DELETE SET DEFAULT para parent_id requer que o default seja um ID válido ou NULL se permitido.
  -- Se parent_id pode ser NULL, então `DEFAULT NULL`. Se sempre 0 para raiz, `DEFAULT 0`.
);

CREATE INDEX IF NOT EXISTS idx_deeper_articles_categories_parent_id ON deeper_articles_categories(parent_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_articles_tags (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE, -- Nome da tag
  slug TEXT NOT NULL UNIQUE, -- Slug da tag
  item_count INTEGER NOT NULL DEFAULT 0, -- Cache da contagem de artigos com esta tag
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_articles_tags_to_entries (
  tag_id INTEGER NOT NULL,
  entry_id INTEGER NOT NULL,
  PRIMARY KEY (tag_id, entry_id),
  FOREIGN KEY (tag_id) REFERENCES deeper_articles_tags(id) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (entry_id) REFERENCES deeper_articles_entries(id) ON DELETE CASCADE ON UPDATE CASCADE
);
```

*   **`author_profile_id`**: Quem escreveu o artigo. `ON DELETE SET NULL` para que o artigo não seja deletado se o perfil do autor for, mas fique sem autor.
*   **`slug`**: Parte da URL amigável, deve ser único.
*   **`body_type`**: Indica o formato do corpo do artigo.
*   **`featured_image_id`**: Para uma imagem de destaque.
*   **`category_id`**: Para uma categoria principal (se houver).
*   **`status`**: Controla a visibilidade e ciclo de vida do artigo.
*   **`published_at`**: Permite agendar publicações.
*   **`allow_view_to`**: Controle de privacidade.
*   **`created_at`, `updated_at`**: Timestamps de criação/atualização.

## Tabela: `deeper_articles_categories` (Categorias para Artigos)

## Tabela: `deeper_articles_tags` (Tags para Artigos)

## Tabela: `deeper_articles_tags_to_entries` (Tabela de Junção Muitos-para-Muitos: Tags <-> Artigos)

*   Permite que um artigo tenha múltiplas tags e uma tag seja associada a múltiplos artigos.