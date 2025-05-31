# Documentação Deeper: Esquema do BD para Objetos de Página e Blocos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas do UNA que compõem o motor de renderização de páginas.

## Tabela: `sys_pages_layouts`

```sql
CREATE TABLE IF NOT EXISTS sys_pages_layouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  name TEXT NOT NULL UNIQUE, -- Nome do layout, ex: 'layout_2_columns'. No UNA é VARCHAR(64)
  icon TEXT NOT NULL, -- Ícone representando o layout. No UNA é VARCHAR(255)
  title TEXT NOT NULL, -- Título amigável. No UNA é VARCHAR(255)
  template TEXT NOT NULL, -- Nome do arquivo de template HTML. No UNA é VARCHAR(255)
  cells_number INTEGER NOT NULL -- Número de células/colunas no layout. No UNA é INT(11)
);
CREATE INDEX IF NOT EXISTS idx_sys_pages_layouts_name ON sys_pages_layouts(name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_design_boxes (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  title TEXT NOT NULL, -- Título do design box. No UNA é VARCHAR(255)
  template TEXT NOT NULL, -- Nome do arquivo de template para o design box. No UNA é VARCHAR(255)
  \"order\" INTEGER NOT NULL -- No UNA é INT(11)
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_page (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  author INTEGER NOT NULL DEFAULT 0, -- ID do autor (usuário/perfil). No UNA é INT(11)
  added INTEGER NOT NULL DEFAULT 0, -- Unix Timestamp. No UNA é INT(11)
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de página, ex: 'persons_home'. No UNA é VARCHAR(64)
  uri TEXT NOT NULL UNIQUE, -- URI da página, ex: 'persons-home', 'm/persons/home'. No UNA é VARCHAR(255)
  title_system TEXT, -- Título interno/do sistema. No UNA é VARCHAR(255)
  title TEXT NOT NULL, -- Título da página exibido ao usuário. No UNA é VARCHAR(255)
  module TEXT NOT NULL, -- Módulo ao qual a página pertence. No UNA é VARCHAR(32)
  cover INTEGER NOT NULL DEFAULT 1, -- 0 ou 1, se usa imagem de capa. No UNA é TINYINT(4)
  cover_image INTEGER DEFAULT 0, -- ID da imagem de capa (FK para sys_files/sys_images). No UNA é INT(11)
  cover_title TEXT, -- Título sobreposto na capa. No UNA é VARCHAR(255)
  type_id INTEGER NOT NULL DEFAULT 1, -- Tipo de página (ex: padrão, sistema). FK para sys_pages_types. No UNA é INT(11)
  layout_id INTEGER NOT NULL, -- FK para sys_pages_layouts.id. No UNA é INT(11)
  sticky_columns INTEGER NOT NULL DEFAULT 0, -- 0 ou 1. No UNA é TINYINT(4)
  submenu TEXT, -- Nome do objeto de menu para o submenu. No UNA é VARCHAR(64)
  visible_for_levels INTEGER, -- Bitmask de níveis ACL. No UNA é INT(11) NOT NULL DEFAULT 2147483647
  visible_for_levels_editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  url TEXT, -- URL externa, se a página for um redirecionamento. No UNA é VARCHAR(255)
  content_info TEXT, -- Nome do objeto content_info associado. No UNA é VARCHAR(64)
  meta_title TEXT, -- Título para SEO. No UNA é VARCHAR(255)
  meta_description TEXT, -- Descrição para SEO. No UNA é TEXT
  meta_keywords TEXT, -- Palavras-chave para SEO. No UNA é TEXT
  meta_robots TEXT, -- Instruções para robôs (index, nofollow). No UNA é VARCHAR(255)
  cache_lifetime INTEGER NOT NULL DEFAULT 0, -- Em segundos. No UNA é INT(11)
  cache_editable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  inj_head TEXT, -- Código para injetar no <head>. No UNA é TEXT
  inj_footer TEXT, -- Código para injetar antes de </body>. No UNA é TEXT
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(1) (no dump original era só deletable)
  override_class_name TEXT, -- No UNA é VARCHAR(255)
  override_class_file TEXT, -- No UNA é VARCHAR(255)
  FOREIGN KEY (layout_id) REFERENCES sys_pages_layouts(id) ON UPDATE CASCADE ON DELETE RESTRICT -- RESTRICT para não deletar layout em uso
  -- FK para author (sys_profiles.id), cover_image (sys_files.id), module (sys_modules.name),
  -- submenu (sys_objects_menu.object), content_info (sys_objects_content_info.name)
  -- type_id (sys_pages_types.id) serão adicionadas conforme essas tabelas são definidas.
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_page_object ON sys_objects_page(object);
CREATE INDEX IF NOT EXISTS idx_sys_objects_page_uri ON sys_objects_page(uri);
CREATE INDEX IF NOT EXISTS idx_sys_objects_page_module ON sys_objects_page(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  object TEXT NOT NULL, -- Nome do objeto de página (FK para sys_objects_page.object)
  cell_id INTEGER NOT NULL DEFAULT 1, -- Célula do layout onde o bloco aparece
  module TEXT NOT NULL, -- Módulo que fornece o bloco
  title_system TEXT, -- Título interno/do sistema do bloco
  title TEXT NOT NULL, -- Título do bloco exibido ao usuário
  designbox_id INTEGER NOT NULL DEFAULT 11, -- FK para sys_pages_design_boxes.id
  class TEXT, -- Classe CSS adicional para o bloco. No UNA é VARCHAR(128)
  submenu TEXT, -- Nome do objeto de menu para o submenu do bloco. No UNA é VARCHAR(64)
  tabs INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o bloco usa abas internas. No UNA é TINYINT(4)
  async INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o bloco deve ser carregado assincronamente. No UNA é INT(11)
  visible_for_levels INTEGER, -- Bitmask de níveis ACL. No UNA é INT(11) NOT NULL DEFAULT 2147483647
  hidden_on TEXT, -- Condições para ocultar (ex: mobile, desktop). No UNA é VARCHAR(255)
  type TEXT NOT NULL DEFAULT 'raw' CHECK(type IN (
    'raw', 'html', 'creative', 'bento_grid', 'lang', 'image', 'rss', 'menu', 'custom', 'service', 'wiki'
  )), -- ENUM no UNA
  content TEXT, -- Conteúdo do bloco (HTML, definição de serviço, ID de imagem, URL RSS, nome do objeto de menu, etc.)
  content_empty TEXT, -- Chave de linguagem para quando o conteúdo estiver vazio. No UNA é VARCHAR(255)
  \"text\" TEXT, -- Conteúdo para blocos 'wiki' ou 'text'. No UNA é MEDIUMTEXT
  text_updated INTEGER, -- Unix Timestamp. No UNA é INT(11)
  help TEXT, -- Texto de ajuda para o bloco. No UNA é VARCHAR(255)
  cache_lifetime INTEGER NOT NULL DEFAULT 0, -- Em segundos
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  copyable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1. No UNA é TINYINT(4)
  active_api INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se ativo para API. No UNA é TINYINT(4)
  \"order\" INTEGER NOT NULL, -- Ordem do bloco dentro da célula. No UNA é INT(11)
  FOREIGN KEY (object) REFERENCES sys_objects_page(object) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (designbox_id) REFERENCES sys_pages_design_boxes(id) ON UPDATE CASCADE ON DELETE RESTRICT
  -- FK para module (sys_modules.name), submenu (sys_objects_menu.object)
);
CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_object_cell_order ON sys_pages_blocks(object, cell_id, \"order\");
CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_module ON sys_pages_blocks(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  title TEXT NOT NULL, -- Título do tipo de página. No UNA é VARCHAR(255)
  template TEXT NOT NULL, -- Nome do arquivo de template HTML base para este tipo. No UNA é VARCHAR(255)
  \"order\" INTEGER NOT NULL -- No UNA é INT(11)
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_blocks_data (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  block_id INTEGER NOT NULL, -- FK para sys_pages_blocks.id
  content_id INTEGER NOT NULL, -- ID do conteúdo específico ao qual este override se aplica
  content_module TEXT NOT NULL, -- Módulo do conteúdo
  data TEXT NOT NULL, -- Dados de override, geralmente JSON
  FOREIGN KEY (block_id) REFERENCES sys_pages_blocks(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- UNIQUE (block_id, content_id, content_module) no UNA
);
CREATE UNIQUE INDEX IF NOT EXISTS uidx_sys_pages_blocks_data_block_content ON sys_pages_blocks_data(block_id, content_id, content_module);
```

*   Define as diferentes estruturas de layout (ex: 1 coluna, 2 colunas, etc.).

## Tabela: `sys_pages_design_boxes`

*   Define os diferentes estilos visuais (caixas) que podem ser aplicados aos blocos de conteúdo.

## Tabela: `sys_objects_page`

## Tabela: `sys_pages_blocks`

## Tabela: `sys_pages_types` (Referenciada por `sys_objects_page`)

*   Define diferentes \"tipos\" de páginas (ex: padrão, sistema, perfil), que podem ter templates base diferentes.

## Tabela: `sys_pages_blocks_data` (Opcional, para overrides)

*   Permite que instâncias específicas de blocos (quando exibidos no contexto de um `content_id` de um `content_module`) tenham seus dados (geralmente `content` ou `title`) sobrescritos. Uso menos comum e pode ser adiado.

### Chaves Estrangeiras e Integridade:
*   As chaves estrangeiras foram definidas onde óbvias. Algumas dependem de tabelas de outras seções (ex: `sys_modules`, `sys_objects_menu`) e seriam totalmente validadas quando todas as tabelas estiverem no esquema.
*   Lembre-se de `PRAGMA foreign_keys = ON;` para SQLite.