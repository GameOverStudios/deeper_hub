# Documentação Deeper: API para Objetos de Página (`sys_objects_page`)

Este documento descreve a API \"Deeper\" para obter as definições de \"Objetos de Página\" do UNA e os blocos associados a eles. Esta é a API central que o cliente usará para entender como construir a estrutura e o conteúdo de uma página.

## Tabela Principal do UNA: `sys_objects_page`

*   Define cada página única no sistema.
*   Campos chave: `id`, `object` (nome único do objeto de página), `uri` (usado na URL `page.php?i=uri`), `title_system`, `title`, `module`, `layout_id`, `submenu`, `visible_for_levels`, `url` (se for um link externo), `content_info`, etc.

## Tabela de Blocos: `sys_pages_blocks`

*   Define os blocos que compõem cada objeto de página.
*   Campos chave: `id`, `object` (FK para `sys_objects_page.object`), `cell_id`, `module`, `title`, `designbox_id`, `type` (`html`, `service`, `menu`, etc.), `content` (HTML bruto ou definição do serviço/menu), `cache_lifetime`.

## Módulo de Acesso a Dados (`Deeper.PageEngine.PagesRepo`):

**Funções Principais e SQLs Esperados:**

*   **`get_page_structure(page_uri :: String.t(), page_params :: map()) :: {:ok, page_data :: map()} | {:error, :not_found | any()}`**
    *   Esta é a função principal para buscar a definição de uma página e seus blocos.
    *   `page_uri`: O valor de `sys_objects_page.uri`.
    *   `page_params`: Um mapa de parâmetros adicionais que podem ter vindo da URL resolvida (ex: `%{id: 123, module: \"bx_persons\"}`). Estes parâmetros podem ser necessários para a lógica dos \"serviços\" de blocos.
    *   **Passo 1: Buscar o objeto de página.**
        *   SQL: `SELECT id, object, title, module, layout_id, submenu, visible_for_levels, cache_lifetime, content_info FROM sys_objects_page WHERE uri = ? LIMIT 1;`
        *   Se não encontrado, retorna `{:error, :not_found}`.
        *   Verificar `visible_for_levels` contra o nível de ACL do usuário. Se não permitido, retorna `{:error, :forbidden}`.
    *   **Passo 2: Buscar os blocos da página.**
        *   SQL: `SELECT id AS block_id, cell_id, module AS block_module, title AS block_title, designbox_id, type AS block_type, content AS block_content, cache_lifetime AS block_cache_lifetime, active_api FROM sys_pages_blocks WHERE object = ? AND active = 1 ORDER BY cell_id, \"order\";` (usando `sys_objects_page.object` da query anterior).
    *   **Passo 3: Processar os blocos (especialmente os de tipo `service`).**
        *   Para cada bloco retornado:
            *   Se `block_type` for `service`:
                *   O `block_content` do UNA geralmente é uma string PHP serializada (ex: `a:4:{s:6:\"module\";s:10:\"bx_persons\";s:6:\"method\";s:18:\"service_entity_all\";...}`). A API \"Deeper\" **não executará PHP**.
                *   **Abordagem \"Deeper\":**
                    1.  **Parsear `block_content`:** Extrair `module`, `method`, e `params` da string serializada (se possível, ou definir um formato JSON mais limpo para isso no futuro se o BD puder ser alterado minimamente).
                    2.  **Pré-buscar Dados (Recomendado):** Com base no `module`, `method`, `params` extraídos, e os `page_params` originais, o `PagesRepo` (ou um serviço/contexto que ele chama) invocaria a função apropriada de outro Repo (ex: `Deeper.Content.PersonsRepo.list_latest_profiles(count: 5)`) para obter os *dados* que o serviço PHP original geraria.
                    3.  O bloco na resposta da API conteria: `block_type: \"service\"`, `service_definition: %{module: \"bx_persons\", method: \"service_entity_all\", original_params: ...}`, e **`service_data: [...]`** (os dados pré-buscados).
                    4.  Se `active_api` for `0` para um bloco de serviço, este bloco pode ser omitido da resposta da API ou marcado como tal.
            *   Se `block_type` for `menu`: `block_content` é o nome do objeto de menu. A API pode incluir os itens do menu diretamente (chamando `MenusRepo`) ou apenas o nome para o cliente buscar separadamente.
            *   Se `block_type` for `html`: `block_content` é o HTML.
    *   **Passo 4: Montar a Resposta.**
        *   Retorna um mapa contendo os metadados da página e a lista de blocos processados.

### Endpoints da API (`/api/v1/pages`):

*   **Obter Estrutura de uma Página:**
    *   **Endpoint:** `GET /api/v1/pages`
    *   **Query Parameters:**
        *   `uri` (obrigatório): O `uri` do objeto de página do UNA (ex: `bx_persons_view`, `home`).
        *   `param_[key]` (opcional): Parâmetros adicionais que seriam parte da URL original do UNA ou resolvidos de um permalink. Ex: `param_id=123`, `param_username=john`. A API deve coletar todos os `param_*` em um mapa.
    *   **Descrição:** Retorna a definição completa de uma página, incluindo seus metadados e a lista de blocos que a compõem (com conteúdo ou dados de serviço pré-buscados).
    *   **Autenticação:** Requer JWT (para verificar `visible_for_levels` da página e potencialmente para a lógica dos serviços de blocos).
    *   **Resposta de Sucesso (200 OK):**

```json
        {
          \"data\": {
            \"page_uri\": \"bx_persons_view\",
            \"title\": \"View Profile\",
            \"layout_id\": 2, // ID do sys_pages_layouts
            \"submenu_object_name\": \"bx_persons_profile_submenu\", // Nome do sys_objects_menu
            \"cache_lifetime\": 3600,
            \"content_info_object\": \"bx_persons\", // Nome do sys_objects_content_info
            \"blocks\": [
              {
                \"block_id\": 101,
                \"cell_id\": 1, // Em qual célula do layout
                \"title\": \"Profile Header\",
                \"designbox_id\": 11,
                \"type\": \"service\",
                \"service_definition\": {
                  \"module\": \"bx_persons\",
                  \"method\": \"service_entity_breadcrumb\", // Exemplo
                  \"original_params\": {\"id\": 123} // Parâmetros do bloco e da página
                },
                \"service_data\": { // Dados que o serviço PHP geraria
                  \"name\": \"John Doe\",
                  \"profile_url\": \"/profile/john-doe\"
                },
                \"cache_lifetime\": 0
              },
              {
                \"block_id\": 102,
                \"cell_id\": 2,
                \"title\": \"About Me\",
                \"designbox_id\": 1,
                \"type\": \"html\",
                \"html_content\": \"<p>Este é o meu conteúdo HTML sobre mim...</p>\",
                \"cache_lifetime\": 3600
              },
              {
                \"block_id\": 103,
                \"cell_id\": 1, // Outro bloco na célula 1, renderizado após o bloco 101
                \"title\": \"Friends\",
                \"designbox_id\": 3,
                \"type\": \"service\",
                \"service_definition\": {
                  \"module\": \"bx_persons\",
                  \"method\": \"service_entity_friends\",
                  \"original_params\": {\"id\": 123, \"count\": 6}
                },
                \"service_data\": [ // Lista de amigos
                  {\"id\": 201, \"fullname\": \"Jane Smith\", \"avatar_url\": \"...\"},
                  {\"id\": 202, \"fullname\": \"Peter Jones\", \"avatar_url\": \"...\"}
                ],
                \"cache_lifetime\": 600
              },
              {
                \"block_id\": 104,
                \"cell_id\": 3,
                \"title\": \"Profile Actions\",
                \"designbox_id\": 0, // Sem design box
                \"type\": \"menu\",
                \"menu_object_name\": \"bx_persons_profile_actions\",
                // Opcional: incluir itens do menu diretamente aqui
                // \"menu_items\": [ { \"title\": \"Add Friend\", \"link\": \"/api/v1/...\", \"icon\": \"...\"} ]
                \"cache_lifetime\": 0
              }
            ]
          }
        }
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_page (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de página
  uri TEXT NOT NULL UNIQUE, -- Usado em page.php?i=uri
  title_system TEXT NOT NULL, -- Chave de tradução para o título (admin)
  title TEXT NOT NULL, -- Chave de tradução para o título (público)
  module TEXT NOT NULL,
  -- cover INTEGER DEFAULT 1, -- Se a página tem imagem de capa
  -- cover_image INTEGER DEFAULT 0,
  -- cover_title TEXT,
  -- type_id INTEGER DEFAULT 1, -- FK para sys_pages_types
  layout_id INTEGER NOT NULL, -- FK para sys_pages_layouts.id
  -- sticky_columns INTEGER DEFAULT 0,
  submenu TEXT, -- Nome do objeto de menu para o submenu da página
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Máscara de bits ACL
  -- visible_for_levels_editable INTEGER DEFAULT 1,
  url TEXT, -- Se for um redirecionamento ou link externo
  content_info TEXT, -- Nome do sys_objects_content_info associado
  -- meta_title TEXT, meta_description TEXT, meta_keywords TEXT, meta_robots TEXT
  cache_lifetime INTEGER NOT NULL DEFAULT 0,
  -- cache_editable INTEGER DEFAULT 1,
  -- inj_head TEXT, inj_footer TEXT,
  deletable INTEGER NOT NULL DEFAULT 1, -- 0 ou 1
  override_class_name TEXT,
  override_class_file TEXT
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_page_uri ON sys_objects_page(uri);
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_blocks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK para sys_objects_page.object
  cell_id INTEGER NOT NULL DEFAULT 1, -- Em qual célula do layout
  module TEXT NOT NULL,
  title_system TEXT NOT NULL, -- Chave de tradução (admin)
  title TEXT NOT NULL, -- Chave de tradução (público)
  designbox_id INTEGER NOT NULL DEFAULT 11, -- FK para sys_pages_design_boxes.id
  class TEXT, -- Classes CSS adicionais
  submenu TEXT, -- Nome do objeto de menu para o submenu do bloco
  tabs INTEGER NOT NULL DEFAULT 0, -- Se o bloco usa abas
  async INTEGER NOT NULL DEFAULT 0, -- Se carrega via AJAX no UNA PHP
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
  hidden_on TEXT, -- Condições para ocultar (ex: 'mobile', 'desktop')
  type TEXT NOT NULL DEFAULT 'raw' CHECK(type IN ('raw','html','creative','bento_grid','lang','image','rss','menu','custom','service','wiki')),
  content TEXT NOT NULL, -- HTML, ou definição de serviço/menu, ou chave de tradução
  -- content_empty TEXT,
  -- text MEDIUMTEXT, text_updated INTEGER, -- Para blocos wiki
  -- help TEXT,
  cache_lifetime INTEGER NOT NULL DEFAULT 0,
  deletable INTEGER NOT NULL DEFAULT 1,
  copyable INTEGER NOT NULL DEFAULT 1,
  active INTEGER NOT NULL DEFAULT 1, -- Se o bloco está ativo
  active_api INTEGER NOT NULL DEFAULT 0, -- Se o bloco deve ser exposto/processado pela API \"Deeper\"
  \"order\" INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (object) REFERENCES sys_objects_page(object) ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX IF NOT EXISTS idx_sys_pages_blocks_object_active ON sys_pages_blocks(object, active);
```

    *   **Respostas de Erro:** `400 Bad Request` (se `uri` faltar), `401 Unauthorized`, `403 Forbidden` (se o nível do usuário não permitir ver a página), `404 Not Found` (se a página `uri` não existir).

## Tabelas de Páginas e Blocos (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_objects_page` e `sys_pages_blocks` (e `sys_pages_layouts`, `sys_pages_design_boxes`) precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações Elixir.

**Exemplo `sys_objects_page` (SQLite):**

**Exemplo `sys_pages_blocks` (SQLite):**

## Desafios e Considerações:

*   **Parsear `block_content` para Serviços:** A string serializada PHP em `sys_pages_blocks.content` para serviços é o maior desafio. Uma função robusta em Elixir para parsear isso (ou um formato alternativo como JSON se pudermos modificar o BD minimamente no futuro) é necessária. Inicialmente, o parse pode ser limitado aos padrões mais comuns.
*   **Lógica dos \"Serviços\":** A API \"Deeper\" não executará o código PHP dos serviços. A estratégia de pré-buscar os *dados* que esses serviços gerariam é crucial. Isso significa que para cada `module`+`method` de serviço do UNA, precisaremos de uma lógica correspondente no backend \"Deeper\" (provavelmente em um Repo do módulo) para buscar e formatar esses dados.
*   **Parâmetros de Página e Bloco:** Garantir que os `page_params` (da URL) e quaisquer parâmetros definidos no `block_content` do serviço sejam corretamente passados para a lógica de busca de dados do serviço no backend \"Deeper\".
*   **Cache:** Respeitar `cache_lifetime` da página e dos blocos. A API pode implementar caching (ex: usando `ConCache` ou ETS) para respostas de páginas/blocos. O cliente também deve ser instruído sobre o cache.
*   **ACL em Blocos:** `visible_for_levels` nos blocos também precisa ser verificado.

Esta API de páginas é o núcleo para permitir que um cliente desacoplado renderize a experiência do UNA.