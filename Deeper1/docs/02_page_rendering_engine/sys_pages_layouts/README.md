# Documentação Deeper: API para Layouts de Página (`sys_pages_layouts`)

Este documento descreve como a API \"Deeper\" fornecerá informações sobre os layouts de página definidos no sistema UNA. O cliente remoto usará essa informação para estruturar visualmente o conteúdo da página em colunas e seções.

## Tabela Principal do UNA: `sys_pages_layouts`

*   Define as diferentes estruturas de layout disponíveis para as páginas.
*   Campos chave: `id`, `name` (nome único do layout), `icon` (para exibição no admin), `title` (chave de tradução), `template` (nome do arquivo de template no UNA PHP), `cells_number` (quantas colunas/células o layout possui).

## Estratégia da API \"Deeper\" para Layouts:

A API \"Deeper\" não servirá o \"template\" PHP. Em vez disso, quando a API de Páginas (`GET /api/v1/pages`) retorna os dados de uma página, ela incluirá o `layout_id`. O cliente pode, opcionalmente, fazer uma chamada separada para obter detalhes de todos os layouts disponíveis, ou a API de Páginas pode embutir informações chave do layout.

A abordagem mais simples e eficiente para o cliente é que a resposta da API de Páginas (`GET /api/v1/pages`) inclua os detalhes relevantes do layout da página solicitada.

### Informações do Layout na Resposta da API de Páginas:

Quando o cliente requisita uma página via `GET /api/v1/pages?uri={page_uri}`, a resposta JSON na seção de metadados da página incluiria:

```json
// Dentro da resposta de GET /api/v1/pages
{
  \"data\": {
    \"page_uri\": \"bx_persons_view\",
    \"title\": \"View Profile\",
    // ... outros metadados da página ...
    \"layout\": { // Informações do layout associado
      \"id\": 2, // sys_pages_layouts.id
      \"name\": \"layout_2_columns_thin_left\", // sys_pages_layouts.name
      \"title_key\": \"_sys_layout_2_columns_thin_left_title\", // sys_pages_layouts.title (chave de tradução)
      \"cells_number\": 2, // sys_pages_layouts.cells_number
      // Opcional: uma descrição mais estruturada do layout para o cliente
      \"structure_hint\": \"thin-left-main\" // Ex: \"main-sidebar\", \"three-equal-columns\", etc.
                                         // Isso ajuda o cliente a aplicar o CSS/componente correto.
    },
    \"blocks\": [
      // ... lista de blocos, cada um com seu \"cell_id\" (1, 2, ..., N)
      // que corresponde a uma célula no layout.
    ]
  }
}
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"layout_1_column_std\",
          \"title_key\": \"_sys_layout_1_column_std_title\",
          \"cells_number\": 1,
          \"icon\": \"far columns\", // sys_pages_layouts.icon
          \"structure_hint\": \"single-column\"
        },
        {
          \"id\": 2,
          \"name\": \"layout_2_columns_thin_left\",
          \"title_key\": \"_sys_layout_2_columns_thin_left_title\",
          \"cells_number\": 2,
          \"icon\": \"far columns-gap\",
          \"structure_hint\": \"thin-left-main\"
        }
        // ... outros layouts ...
      ]
    }
```

```sql
        SELECT id, name, title, cells_number
        FROM sys_pages_layouts
        WHERE id = ?; -- ? é o layout_id da página
```

```sql
CREATE TABLE IF NOT EXISTS sys_pages_layouts (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE, -- Nome programático do layout
  icon TEXT NOT NULL, -- Classe de ícone FontAwesome ou caminho
  title TEXT NOT NULL, -- Chave de tradução para o título do layout
  template TEXT NOT NULL, -- Nome do arquivo de template PHP original (para referência)
  cells_number INTEGER NOT NULL -- Quantas células/colunas o layout tem
);
-- Adicionar \"order\" se existir no schema original
-- CREATE INDEX IF NOT EXISTS idx_sys_pages_layouts_order ON sys_pages_layouts(\"order\");
```

**Lógica do Backend (`Deeper.PageEngine.PagesRepo`):**

*   Ao buscar os dados da página (`sys_objects_page`), a função `get_page_structure` também fará um `JOIN` (ou uma query separada) com `sys_pages_layouts` usando `sys_objects_page.layout_id` para obter os detalhes do layout.
    *   SQL (como parte da busca da página ou query adicional):

### Endpoint Opcional para Listar Todos os Layouts (para ferramentas de desenvolvimento/admin do cliente):

*   **Endpoint:** `GET /api/v1/system/layouts`
*   **Descrição:** Retorna uma lista de todos os layouts de página disponíveis no sistema.
*   **Autenticação:** Pode requerer autenticação (ex: para um construtor de páginas no cliente).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend (`Deeper.PageEngine.LayoutsRepo` ou similar):**
    *   SQL: `SELECT id, name, title, cells_number, icon FROM sys_pages_layouts ORDER BY \"order\";` (se houver uma coluna de ordem).

## Tabela de Layouts (Esquema SQLite):

O `CREATE TABLE` statement para `sys_pages_layouts` (e `sys_pages_design_boxes`, `sys_pages_types` se forem expostos diretamente) precisará ser definido no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações Elixir.

**Exemplo `sys_pages_layouts` (SQLite):**

## Responsabilidade do Cliente:

*   Com base no `layout.id` ou `layout.structure_hint` e `layout.cells_number` recebidos da API de páginas, o cliente é responsável por aplicar o CSS ou a estrutura de componentes correta para renderizar as colunas.
*   O cliente então itera sobre a lista de `blocks` e renderiza cada bloco dentro da `cell_id` apropriada.
*   Por exemplo, se `cells_number` for 2 e um bloco tiver `cell_id: 1`, ele vai para a primeira coluna; se `cell_id: 2`, para a segunda.

Esta abordagem simplifica a API, embutindo as informações de layout necessárias diretamente na resposta da página, mas oferece um endpoint opcional para introspecção de todos os layouts.