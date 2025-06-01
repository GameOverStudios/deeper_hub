# Documentação Deeper: Esquema do Banco de Dados para Organizações (`bx_organizations` - SQLite)

Este documento define os `CREATE TABLE` statements para SQLite da tabela principal do módulo Organizações, `bx_organizations_data`.

## Tabela: `bx_organizations_data` (Dados para Perfis do Tipo \"Organização\")

```sql
CREATE TABLE IF NOT EXISTS bx_organizations_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- Este ID será o content_id em sys_profiles com type='bx_organizations'
  author_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do criador/principal administrador
  org_name TEXT NOT NULL, -- Nome da organização
  org_uri TEXT NOT NULL UNIQUE, -- URI/slug único para a organização
  org_cat INTEGER, -- ID da categoria da organização (FK para uma futura tabela bx_organizations_categories)
  org_desc TEXT, -- Descrição da organização
  org_logo INTEGER, -- ID de um arquivo/imagem (FK para deeper_files.id) para o logo
  org_cover INTEGER, -- ID de um arquivo/imagem para a capa
  org_website TEXT,
  org_email TEXT, -- Email de contato da organização
  org_phone TEXT, -- Telefone de contato da organização
  org_address_street TEXT,
  org_address_city TEXT,
  org_address_state TEXT,
  org_address_zip TEXT,
  org_address_country TEXT, -- Código do país (ex: US, BR)
  org_location_lat REAL,
  org_location_lng REAL,
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'pending', 'hidden')), -- Status do perfil da organização
  status_admin TEXT NOT NULL DEFAULT 'active' CHECK(status_admin IN ('active', 'hidden', 'pending')), -- Status de moderação
  allow_view_to TEXT NOT NULL DEFAULT '3', -- ID do grupo de privacidade (do UNA)
  allow_post_to TEXT NOT NULL DEFAULT 'c', -- Permissão para postar no mural/feed da organização (UNA: 'c' = admins)
  allow_contact_to TEXT NOT NULL DEFAULT 'c', -- Permissão para contatar
  views INTEGER NOT NULL DEFAULT 0,
  fans_count INTEGER NOT NULL DEFAULT 0, -- Número de seguidores/membros
  comments_count INTEGER NOT NULL DEFAULT 0,
  reports_count INTEGER NOT NULL DEFAULT 0,
  featured_until INTEGER, -- Timestamp Unix até quando está em destaque
  added INTEGER NOT NULL, -- Unix Timestamp
  changed INTEGER NOT NULL, -- Unix Timestamp
  settings TEXT, -- Configurações específicas, pode ser JSON

  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
  -- FOREIGN KEY (org_cat) REFERENCES bx_organizations_categories(id) ON DELETE SET NULL -- Se existir tabela de categorias
  -- FOREIGN KEY (org_logo) REFERENCES deeper_files(id) ON DELETE SET NULL
  -- FOREIGN KEY (org_cover) REFERENCES deeper_files(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_author_id ON bx_organizations_data(author_id);
CREATE UNIQUE INDEX IF NOT EXISTS idx_bx_organizations_data_org_uri ON bx_organizations_data(org_uri);
CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_org_name ON bx_organizations_data(org_name);
CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_org_cat ON bx_organizations_data(org_cat);
CREATE INDEX IF NOT EXISTS idx_bx_organizations_data_status ON bx_organizations_data(status);
-- Um índice Full-Text em org_name e org_desc seria útil (usando FTS5 do SQLite)
```

```sql
CREATE TABLE IF NOT EXISTS bx_organizations_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER NOT NULL DEFAULT 0,
  name TEXT NOT NULL UNIQUE,
  title TEXT NOT NULL, -- Chave de tradução ou título direto
  uri TEXT NOT NULL UNIQUE,
  order_index INTEGER NOT NULL DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_bx_org_cat_parent_id ON bx_organizations_categories(parent_id);
CREATE INDEX IF NOT EXISTS idx_bx_org_cat_uri ON bx_organizations_categories(uri);
```

```sql
CREATE TABLE IF NOT EXISTS bx_organizations_members (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  org_id INTEGER NOT NULL, -- FK para bx_organizations_data.id
  profile_id INTEGER NOT NULL, -- FK para sys_profiles.id (o perfil do membro)
  role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('admin', 'editor', 'member')), -- Papel do membro na organização
  added INTEGER NOT NULL, -- Unix Timestamp de quando se tornou membro/admin

  PRIMARY KEY (org_id, profile_id), -- Garante que um perfil só tenha um papel por organização
  FOREIGN KEY (org_id) REFERENCES bx_organizations_data(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

-- Nota: SQLite não permite PRIMARY KEY (org_id, profile_id) e id INTEGER PRIMARY KEY AUTOINCREMENT na mesma tabela diretamente.
-- Se um ID autoincrementável for desejado para esta tabela de junção,
-- a chave primária composta (org_id, profile_id) deve ser transformada em um UNIQUE INDEX.
-- Exemplo alternativo:
-- CREATE TABLE IF NOT EXISTS bx_organizations_members (
--   id INTEGER PRIMARY KEY AUTOINCREMENT,
--   org_id INTEGER NOT NULL,
--   profile_id INTEGER NOT NULL,
--   role TEXT NOT NULL DEFAULT 'member' CHECK(role IN ('admin', 'editor', 'member')),
--   added INTEGER NOT NULL,
--   UNIQUE (org_id, profile_id),
--   FOREIGN KEY (org_id) REFERENCES bx_organizations_data(id) ON DELETE CASCADE,
--   FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
-- );
```

*   **`id`**: Chave primária. Ligado a `sys_profiles.content_id`.
*   **`author_id`**: O perfil que criou e inicialmente administra a organização.
*   **`org_name`**: Nome oficial da organização.
*   **`org_uri`**: Identificador único para URLs.
*   **`org_cat`**: Categoria da organização (se houver uma taxonomia).
*   **`org_desc`**: Descrição detalhada.
*   **`org_logo`, `org_cover`**: IDs para o logo e imagem de capa, vinculados ao sistema de arquivos.
*   **`org_website`, `org_email`, `org_phone`**: Informações de contato.
*   **Campos de Endereço (`org_address_*`)**: Endereço físico.
*   **`org_location_lat`, `org_location_lng`**: Coordenadas geográficas.
*   **`status`, `status_admin`**: Status público e de moderação.
*   **`allow_view_to`, `allow_post_to`, `allow_contact_to`**: Níveis de privacidade/permissão (mapeados dos valores do UNA).
*   **Contadores (`views`, `fans_count`, etc.)**: Métricas de interação.
*   **`featured_until`**: Para destacar organizações.
*   **`added`, `changed`**: Timestamps.
*   **`settings`**: Para configurações adicionais em JSON.

## Tabela: `bx_organizations_categories` (Opcional, mas comum)

Se as organizações puderem ser categorizadas (ex: \"Tecnologia\", \"Educação\", \"ONG\").

## Tabela: `bx_organizations_admins` (ou `bx_organizations_members`)

Para gerenciar múltiplos administradores ou membros com papéis dentro da organização, se a funcionalidade for além do simples `author_id`.

*   **`org_id`**: A qual organização o membro pertence.
*   **`profile_id`**: O perfil do membro.
*   **`role`**: Papel do membro (admin, editor, membro simples).
*   **`added`**: Quando o membro foi adicionado.

## Considerações:

*   As chaves estrangeiras para `org_logo`, `org_cover` dependerão da implementação final da tabela de arquivos global (`deeper_files` do módulo `06_file_management`).
*   As tabelas de interação (comentários, fãs/seguidores) podem ser as genéricas do sistema (`sys_cmts_entries`, `sys_profiles_conn_subscriptions` com um contexto específico para organizações) ou tabelas específicas como `bx_organizations_cmts`, `bx_organizations_fans` se o UNA as tiver. A abordagem genérica é geralmente mais flexível para \"Deeper\".

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas.