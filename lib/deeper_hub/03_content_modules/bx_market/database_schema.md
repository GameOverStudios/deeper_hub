# Documentação Deeper: Esquema do Banco de Dados para Marketplace (`bx_market` - SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas principais do módulo Marketplace (`bx_market`).

## Tabela: `bx_market_categories`

```sql
CREATE TABLE IF NOT EXISTS bx_market_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER NOT NULL DEFAULT 0, -- Para subcategorias
  name TEXT NOT NULL UNIQUE, -- Nome da categoria (deve ser único ou único por parent_id)
  title TEXT NOT NULL, -- Título amigável (para internacionalização, pode ser uma chave de tradução)
  uri TEXT NOT NULL UNIQUE, -- URI amigável para a categoria
  icon TEXT, -- Caminho para um ícone ou classe de ícone
  order INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1 CHECK(active IN (0,1)),
  meta_description TEXT,
  meta_keywords TEXT
);

CREATE INDEX IF NOT EXISTS idx_bx_market_categories_parent_id ON bx_market_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_bx_market_categories_uri ON bx_market_categories(uri);
```

```sql
CREATE TABLE IF NOT EXISTS bx_market_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do vendedor/autor
  status TEXT NOT NULL DEFAULT 'pending' CHECK(status IN ('active', 'pending', 'hidden', 'sold', 'expired')), -- Status da listagem
  status_admin TEXT NOT NULL DEFAULT 'active' CHECK(status_admin IN ('active', 'hidden', 'pending')), -- Status de moderação
  category_id INTEGER NOT NULL, -- FK para bx_market_categories.id
  title TEXT NOT NULL,
  name TEXT NOT NULL UNIQUE, -- Slug/identificador único para a URL do produto
  description TEXT,
  tags TEXT, -- Tags separadas por vírgula ou JSON array
  price REAL, -- Preço principal (pode ser 0 para \"a combinar\" ou \"grátis\")
  currency_code TEXT DEFAULT 'USD', -- Código da moeda (ex: USD, BRL, EUR)
  price_negotiable INTEGER NOT NULL DEFAULT 0 CHECK(price_negotiable IN (0,1)),
  location_text TEXT, -- Descrição textual da localização
  location_lat REAL, -- Latitude
  location_lng REAL, -- Longitude
  quantity INTEGER DEFAULT 1, -- Quantidade disponível (se aplicável)
  condition TEXT CHECK(condition IN ('new', 'used_like_new', 'used_good', 'used_fair')), -- Condição do produto
  allow_comments INTEGER NOT NULL DEFAULT 1 CHECK(allow_comments IN (0,1)),
  allow_votes INTEGER NOT NULL DEFAULT 1 CHECK(allow_votes IN (0,1)),
  allow_reports INTEGER NOT NULL DEFAULT 1 CHECK(allow_reports IN (0,1)),
  views INTEGER NOT NULL DEFAULT 0,
  favorites INTEGER NOT NULL DEFAULT 0,
  comments_count INTEGER NOT NULL DEFAULT 0,
  votes_count INTEGER NOT NULL DEFAULT 0,
  score REAL NOT NULL DEFAULT 0,
  reports_count INTEGER NOT NULL DEFAULT 0,
  featured_until INTEGER, -- Timestamp Unix até quando está em destaque, ou NULL
  added INTEGER NOT NULL, -- Unix Timestamp
  changed INTEGER NOT NULL, -- Unix Timestamp
  last_bump INTEGER, -- Unix Timestamp do último \"bump\" ou \"up\" na listagem
  expiration_date INTEGER, -- Unix Timestamp de quando a listagem expira, ou NULL

  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES bx_market_categories(id) ON DELETE RESTRICT -- Não deletar categoria se tiver produtos
);

CREATE INDEX IF NOT EXISTS idx_bx_market_entries_author_id ON bx_market_entries(author_id);
CREATE INDEX IF NOT EXISTS idx_bx_market_entries_category_id ON bx_market_entries(category_id);
CREATE INDEX IF NOT EXISTS idx_bx_market_entries_status ON bx_market_entries(status);
CREATE INDEX IF NOT EXISTS idx_bx_market_entries_name ON bx_market_entries(name);
CREATE INDEX IF NOT EXISTS idx_bx_market_entries_price ON bx_market_entries(price);
CREATE INDEX IF NOT EXISTS idx_bx_market_entries_added ON bx_market_entries(added);
-- Um índice Full-Text em title e description seria útil aqui (usando FTS5 do SQLite)
-- Ex: CREATE VIRTUAL TABLE bx_market_entries_fts USING fts5(title, description, content=bx_market_entries, content_rowid=id);
-- Esta é uma otimização posterior.
```

```sql
CREATE TABLE IF NOT EXISTS bx_market_photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  entry_id INTEGER NOT NULL, -- FK para bx_market_entries.id
  file_id INTEGER NOT NULL, -- FK para a tabela de arquivos global (ex: deeper_files.id do módulo 06_file_management)
  title TEXT, -- Legenda da foto
  is_main INTEGER NOT NULL DEFAULT 0 CHECK(is_main IN (0,1)), -- Se é a foto principal/capa do produto
  order_index INTEGER NOT NULL DEFAULT 0,

  FOREIGN KEY (entry_id) REFERENCES bx_market_entries(id) ON DELETE CASCADE
  -- FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE -- Depende da tabela de arquivos global
);

CREATE INDEX IF NOT EXISTS idx_bx_market_photos_entry_id ON bx_market_photos(entry_id);
CREATE INDEX IF NOT EXISTS idx_bx_market_photos_file_id ON bx_market_photos(file_id);
```

```sql
-- Esta tabela é mais complexa e pode ser adiada para v2.
-- CREATE TABLE IF NOT EXISTS bx_market_custom_fields_values (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   entry_id INTEGER NOT NULL,
--   field_id INTEGER NOT NULL, -- FK para uma tabela bx_market_custom_fields
--   value TEXT,
--   FOREIGN KEY (entry_id) REFERENCES bx_market_entries(id) ON DELETE CASCADE
--   -- FOREIGN KEY (field_id) REFERENCES bx_market_custom_fields(id) ON DELETE CASCADE
-- );
```

*   **`id`**: Chave primária.
*   **`parent_id`**: Para estrutura de categorias aninhadas. `0` indica categoria raiz.
*   **`name`**: Identificador único da categoria (slug).
*   **`title`**: Título exibível (potencialmente uma chave de tradução `_L descanso`).
*   **`uri`**: URI amigável para a categoria.
*   **`icon`**: Ícone associado à categoria.
*   **`order`**: Ordem de exibição.
*   **`active`**: Se a categoria está ativa (1) ou inativa (0).
*   **`meta_description`, `meta_keywords`**: Para SEO da página de categoria.

## Tabela: `bx_market_entries` (Listagens de Produtos/Serviços)

*   **`author_id`**: ID do perfil do vendedor.
*   **`status`**: Status público da listagem.
*   **`status_admin`**: Status de moderação pelo administrador.
*   **`category_id`**: Categoria do produto.
*   **`title`, `name`, `description`, `tags`**: Informações descritivas do produto.
*   **`price`, `currency_code`, `price_negotiable`**: Informações de preço.
*   **`location_text`, `location_lat`, `location_lng`**: Informações de localização.
*   **`quantity`, `condition`**: Detalhes do produto.
*   **`allow_comments`, `allow_votes`, `allow_reports`**: Configurações de interação.
*   **Contadores (`views`, `favorites`, etc.)**: Métricas de interação (atualizadas por gatilhos ou lógica da aplicação).
*   **`featured_until`**: Para destacar produtos.
*   **`added`, `changed`, `last_bump`, `expiration_date`**: Timestamps relevantes.

## Tabela: `bx_market_photos` (Imagens dos Produtos)
(No UNA, isso poderia ser `bx_market_files` e usar o sistema `sys_files` mais genérico. Aqui, simplificamos para uma tabela direta, mas a integração com `06_file_management` é ideal).

*   **`entry_id`**: A qual listagem esta foto pertence.
*   **`file_id`**: ID da entrada do arquivo no sistema de gerenciamento de arquivos.
*   **`title`**: Legenda opcional.
*   **`is_main`**: Indica se é a foto principal da listagem.
*   **`order_index`**: Ordem de exibição das fotos.

## Tabela: `bx_market_custom_fields_values` (Opcional, para campos customizados)
Se o sistema permitir campos customizados por categoria.

## Outras Tabelas Relevantes (Interação):

As seguintes tabelas são genéricas do sistema, mas serão usadas em associação com `bx_market_entries`:

*   `sys_comments` (ou uma `bx_market_cmts` específica se o UNA tiver): Para comentários nas listagens.
*   `sys_votes` (ou `bx_market_votes`): Para avaliações/votos nas listagens.
*   `sys_favorites_track` (ou `bx_market_favorites_track`): Para favoritar listagens.
*   `sys_reports_track` (ou `bx_market_reports_track`): Para denunciar listagens.
*   `sys_views_track` (ou `bx_market_views_track`): Para rastrear visualizações.

A decisão de usar tabelas de interação genéricas (`sys_*`) ou específicas do módulo (`bx_market_*`) dependerá de como o UNA original está estruturado e da preferência de design para \"Deeper\". Usar tabelas genéricas com uma coluna `object_id` e `module_name` é comum e flexível.

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas.