# Documentação Deeper: Esquema do Banco de Dados para Páginas, Blocos e Layouts (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas usadas pelo motor de renderização de páginas do UNA: `sys_objects_page`, `sys_pages_layouts`, `sys_pages_blocks`, `sys_pages_design_boxes`, e `sys_pages_types`.

## Tabela: `sys_pages_types`

```sql
CREATE TABLE IF NOT EXISTS sys_pages_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL, -- Chave de tradução para o título do tipo de página
  template TEXT NOT NULL, -- Nome do arquivo de template base para este tipo de página
  \"order\" INTEGER NOT NULL DEFAULT 0
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_layouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE, -- Nome programático do layout (ex: 'col_1_2', 'col_2_1')
  icon TEXT NOT NULL, -- Caminho ou classe do ícone representativo
  title TEXT NOT NULL, -- Chave de tradução para o título do layout
  template TEXT NOT NULL, -- Nome do arquivo de template para a estrutura do layout (ex: 'layout_2_columns.html')
  cells_number INTEGER NOT NULL -- Número de células de conteúdo que este layout possui
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_page (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author INTEGER NOT NULL DEFAULT 0, -- ID do perfil do autor da página
  added INTEGER NOT NULL DEFAULT 0, -- Unix Timestamp
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto da página (ex: 'bx_persons_home', 'system_login')
  uri TEXT NOT NULL UNIQUE, -- URI única associada à página (usada para permalinks)
  title_system TEXT, -- Chave de tradução para o título interno/sistema
  title TEXT NOT NULL, -- Chave de tradução para o título exibido da página
  module TEXT NOT NULL, -- Módulo ao qual esta página pertence
  cover INTEGER NOT NULL DEFAULT 1, -- 0 ou 1, se a página deve tentar exibir uma capa
  cover_image INTEGER DEFAULT 0, -- ID de uma imagem para a capa (FK para tabela de arquivos)
  cover_title TEXT, -- Chave de tradução para o título da capa
  type_id INTEGER NOT NULL DEFAULT 1, -- FK para sys_pages_types.id
  layout_id INTEGER NOT NULL, -- FK para sys_pages_layouts.id
  sticky_columns INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se colunas laterais devem ser \"sticky\"
  submenu TEXT, -- Nome do objeto de menu (sys_objects_menu.object) a ser usado como submenu
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  visible_for_levels_editable INTEGER NOT NULL DEFAULT 1,
  url TEXT, -- URL externa para redirecionamento (se aplicável)
  content_info TEXT, -- Nome de um objeto sys_objects_content_info associado
  meta_title TEXT, -- Chave de tradução para o meta title (SEO)
  meta_description TEXT, -- Chave de tradução para meta description (SEO)
  meta_keywords TEXT, -- Chave de tradução para meta keywords (SEO)
  meta_robots TEXT, -- Conteúdo para a tag meta robots (ex: 'index, follow')
  cache_lifetime INTEGER NOT NULL DEFAULT 0, -- Tempo de vida do cache em segundos (0 para sem cache)
  cache_editable INTEGER NOT NULL DEFAULT 1,
  inj_head TEXT, -- Código HTML/JS para injetar no <head>
  inj_footer TEXT, -- Código HTML/JS para injetar antes de </body>
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1, se a página pode ser deletada pelo admin
  override_class_name TEXT, -- Para customização avançada no UNA PHP
  override_class_file TEXT, -- Para customização avançada no UNA PHP
  FOREIGN KEY (type_id) REFERENCES sys_pages_types(id) ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (layout_id) REFERENCES sys_pages_layouts(id) ON DELETE RESTRICT ON UPDATE CASCADE
  -- FK para author, cover_image, submenu, content_info podem ser adicionadas se as tabelas correspondentes forem definidas
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_page_module ON sys_objects_page(module);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_design_boxes (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  title TEXT NOT NULL, -- Chave de tradução para o título do design (ex: 'Caixa Padrão', 'Sem Título')
  template TEXT NOT NULL, -- Nome do arquivo de template para o wrapper do bloco
  \"order\" INTEGER NOT NULL DEFAULT 0
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK (lógica) para sys_objects_page.object (a qual página este bloco pertence)
  cell_id INTEGER NOT NULL DEFAULT 1, -- A qual célula do layout da página este bloco pertence
  module TEXT NOT NULL, -- Módulo que \"possui\" ou fornece este bloco
  title_system TEXT, -- Chave de tradução para o título interno/sistema do bloco
  title TEXT NOT NULL, -- Chave de tradução para o título exibido do bloco
  designbox_id INTEGER NOT NULL DEFAULT 11, -- FK para sys_pages_design_boxes.id
  class TEXT, -- Classes CSS adicionais para o wrapper do bloco
  submenu TEXT, -- Nome de um objeto de menu a ser usado dentro/associado a este bloco
  tabs INTEGER NOT NULL DEFAULT 0, -- Se o bloco deve renderizar conteúdo em abas
  async INTEGER NOT NULL DEFAULT 0, -- 0 ou 1, se o conteúdo do bloco deve ser carregado via AJAX no UNA PHP
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  hidden_on TEXT, -- Condições de tela para ocultar (ex: 'phone,tablet')
  type TEXT NOT NULL DEFAULT 'raw' CHECK(type IN (
    'raw', 'html', 'creative', 'bento_grid', 'lang', 'image', 'rss', 'menu', 'custom', 'service', 'wiki'
  )),
  content TEXT NOT NULL, -- Conteúdo do bloco. Depende do 'type':
                         -- 'html'/'text'/'raw': Conteúdo HTML/texto.
                         -- 'service': String serializada da chamada de serviço (ex: a:4:{s:6:\"module\";s:10:\"bx_persons\";...}).
                         -- 'menu': Nome do objeto de menu (sys_objects_menu.object).
                         -- 'rss': URL do feed RSS.
                         -- 'image': ID/Path da imagem.
                         -- 'lang': Chave de linguagem.
                         -- 'wiki': Conteúdo wiki (ou referência a sys_pages_wiki_blocks.id).
  content_empty TEXT, -- Chave de tradução para mensagem quando o bloco está vazio
  text TEXT, -- Usado especificamente para blocos 'wiki' se o conteúdo não estiver em 'content'
  text_updated INTEGER, -- Unix Timestamp da última atualização do 'text' (para wiki)
  help TEXT, -- Chave de tradução para texto de ajuda do bloco
  cache_lifetime INTEGER NOT NULL DEFAULT 0, -- Tempo de vida do cache para este bloco em segundos
  deletable INTEGER NOT NULL DEFAULT 1,
  copyable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1, -- 0 ou 1, se o bloco está ativo
  active_api INTEGER NOT NULL DEFAULT 0, -- Se o bloco deve ser exposto via API no UNA
  \"order\" INTEGER NOT NULL DEFAULT 0, -- Ordem do bloco dentro da célula
  FOREIGN KEY (designbox_id) REFERENCES sys_pages_design_boxes(id) ON DELETE SET DEFAULT ON UPDATE CASCADE
  -- FK para object (sys_objects_page.object) e module (sys_modules.name) são lógicas,
  -- não impostas por constraint SQL direta aqui para simplificar, mas devem ser válidas.
);
CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_object_cell ON sys_pages_blocks(object, cell_id);
```

```sql
/*
CREATE TABLE IF NOT EXISTS sys_pages_wiki_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  block_id INTEGER NOT NULL, -- FK para sys_pages_blocks.id
  revision INTEGER NOT NULL,
  language TEXT NOT NULL, -- Código do idioma
  main_lang INTEGER NOT NULL DEFAULT 0,
  profile_id INTEGER NOT NULL, -- ID do perfil do autor da revisão
  content TEXT NOT NULL, -- Conteúdo wiki da revisão
  unsafe INTEGER NOT NULL DEFAULT 0, -- Se o conteúdo pode conter HTML não seguro
  notes TEXT, -- Notas sobre a revisão
  added INTEGER NOT NULL, -- Unix Timestamp
  UNIQUE (block_id, language, revision),
  FOREIGN KEY (block_id) REFERENCES sys_pages_blocks(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- FK para profile_id pode ser adicionada
);
*/
```

*   Define os tipos gerais de página (ex: \"Página Padrão\", \"Página de Perfil\"), que podem influenciar o template HTML raiz usado.

## Tabela: `sys_pages_layouts`

*   Define os diferentes arranjos de colunas/células disponíveis para as páginas.

## Tabela: `sys_objects_page`

*   A tabela central que define cada página do sistema.
*   `object`: O identificador principal usado pela API \"Deeper\" para requisitar uma página.
*   Muitos campos são chaves de tradução (`title`, `meta_title`, etc.).

## Tabela: `sys_pages_design_boxes`

*   Define os diferentes \"contêineres\" ou \"wrappers\" visuais para os blocos de conteúdo.

## Tabela: `sys_pages_blocks`

*   Define cada bloco de conteúdo em uma página.
*   `object` e `cell_id` determinam onde o bloco aparece.
*   `type` e `content` são cruciais para determinar como a API \"Deeper\" deve processar e retornar os dados do bloco.

## (Opcional) Tabela: `sys_pages_wiki_blocks`

Se a funcionalidade de blocos Wiki com versionamento for necessária:

*   Para a API \"Deeper\", se um bloco for do tipo `wiki`, o `sys_pages_blocks.content` pode ser o próprio texto wiki mais recente, ou o `sys_pages_blocks.text` pode ser usado. Se o versionamento for exposto pela API, esta tabela seria consultada.