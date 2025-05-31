# Documentação Deeper: Motor de Grids da API (`sys_grids_*`)

Este documento descreve como a API \"Deeper\" fornecerá os dados e a configuração para renderizar grids (tabelas de dados) do sistema UNA. Grids são usadas extensivamente no UNA para exibir listas de usuários, conteúdo, configurações administrativas, etc., com suporte a paginação, filtragem, ordenação e ações.

## Tabelas Principais do UNA para Grids:

1.  **`sys_objects_grid`**:
    *   Define cada grid no sistema.
    *   Campos chave: `object` (nome único da grid), `source_type` (`Sql` ou `Array` - a API focará em `Sql`), `source` (a query SQL ou nome da classe/método PHP que fornece os dados), `table` (tabela principal da query), `field_id` (coluna PK), `field_order` (coluna de ordenação padrão), `paginate_per_page`, `filter_fields` (colunas pesquisáveis), `sorting_fields` (colunas ordenáveis), `visible_for_levels`.

2.  **`sys_grid_fields`**:
    *   Define as colunas a serem exibidas em uma grid específica.
    *   Campos chave: `object` (FK para `sys_objects_grid.object`), `name` (nome da coluna/campo), `title` (chave de tradução para o cabeçalho da coluna), `width`, `translatable` (se o conteúdo da célula é uma chave de tradução), `chars_limit`, `params` (para formatação customizada no UNA PHP, ex: callback para renderizar a célula).

3.  **`sys_grid_actions`**:
    *   Define as ações disponíveis para os itens da grid (ou para a grid como um todo).
    *   Campos chave: `object` (FK para `sys_objects_grid.object`), `type` (`single`, `bulk`, `independent`), `name` (nome da ação), `title` (chave de tradução), `icon`, `confirm` (se requer confirmação).

## Estratégia da API \"Deeper\" para Grids:

A API \"Deeper\" fornecerá um endpoint para buscar a configuração de uma grid e seus dados paginados, filtrados e ordenados. A API executará a query SQL definida no `sys_objects_grid.source` (com modificações para paginação, filtros, ordenação) e retornará os resultados.

### Módulo de Acesso a Dados (`Deeper.Grids.GridsRepo`):

*   **`get_grid_data(grid_object_name :: String.t(), user_acl_level_id :: integer(), query_params :: map()) :: {:ok, grid_response :: map()} | {:error, :not_found | any()}`**
    1.  **Busca Definição da Grid:**
        *   SQL: `SELECT * FROM sys_objects_grid WHERE object = ? LIMIT 1;`
        *   Verifica `visible_for_levels`.
        *   `grid_config = resultado`.
    2.  **Busca Definição dos Campos da Grid:**
        *   SQL: `SELECT name, title, width, translatable, chars_limit, params FROM sys_grid_fields WHERE object = ? ORDER BY \"order\";` (usando `grid_object_name`).
        *   `fields_config = lista_de_campos`. Traduz `title`.
    3.  **Busca Definição das Ações da Grid:**
        *   SQL: `SELECT type, name, title, icon, confirm FROM sys_grid_actions WHERE object = ? AND active = 1 ORDER BY \"order\";`
        *   `actions_config = lista_de_ações`. Traduz `title`.
    4.  **Constrói e Executa a Query de Dados:**
        *   Obtém a query base de `grid_config[\"source\"]`.
        *   **Modifica a Query Base:**
            *   **Filtragem:** Adiciona cláusulas `WHERE` com base nos `query_params` (ex: `filter_nome_campo=valor`) e nas colunas definidas em `grid_config[\"filter_fields\"]`. Cuidado com SQL Injection; use placeholders.
            *   **Ordenação:** Adiciona cláusula `ORDER BY` com base nos `query_params` (ex: `sort_by=nome_campo&sort_order=asc`) e nas colunas em `grid_config[\"sorting_fields\"]`. Se não fornecido, usa `grid_config[\"field_order\"]`.
            *   **Paginação:** Adiciona `LIMIT` e `OFFSET` com base nos `query_params` (ex: `page=1&per_page=20`) e `grid_config[\"paginate_per_page\"]`.
        *   Executa a query de dados modificada: `Repo.query(modified_sql_data, bind_params)`.
        *   Executa uma query de contagem total (query base com os mesmos `WHERE` mas sem `ORDER BY`, `LIMIT`, `OFFSET`): `SELECT COUNT(*) FROM (...) AS subquery_for_count;`.
    5.  **Processa os Resultados da Query de Dados:**
        *   Para cada linha:
            *   Para cada campo/coluna definido em `fields_config`:
                *   Se `translatable`, traduz o valor.
                *   Aplica `chars_limit`.
                *   Interpreta `params` (originalmente para callbacks PHP). A API \"Deeper\" pode precisar de uma lógica para mapear certos `params` para formatação especial (ex: renderizar um booleano como \"Sim/Não\", formatar data, criar um link). Inicialmente, pode apenas retornar o valor bruto.
    6.  Retorna uma estrutura JSON combinada.

### Endpoint da API:

*   **Endpoint:** `GET /api/v1/grids/{grid_object_name}`
*   **Path Parameter:** `grid_object_name`.
*   **Query Parameters (Opcionais):**
    *   `page`, `per_page` (ou `offset`, `limit`).
    *   `sort_by`, `sort_order`.
    *   `filter_[field_name]`: Parâmetros de filtro (ex: `filter_email_like=test@`, `filter_status=active`).
    *   `lang`: Para traduções.
*   **Autenticação:** Requer JWT (para `visible_for_levels` e potencialmente para a query SQL subjacente se ela filtrar por permissões).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"grid_object_name\": \"bx_persons_administration\",
        \"config\": { // Configurações da grid para o cliente construir a UI
          \"title\": \"Gerenciamento de Perfis\", // Traduzido de sys_objects_grid.title (se houver)
          \"fields\": [
            {\"name\": \"id\", \"title\": \"ID\", \"width\": \"5%\", \"sortable\": true},
            {\"name\": \"fullname\", \"title\": \"Nome Completo\", \"width\": \"30%\", \"sortable\": true, \"filterable\": true},
            {\"name\": \"email\", \"title\": \"Email\", \"width\": \"30%\", \"sortable\": true, \"filterable\": true},
            {\"name\": \"status\", \"title\": \"Status\", \"width\": \"15%\", \"sortable\": true, \"filterable\": {\"type\": \"select\", \"options\": [{\"value\":\"active\", \"label\":\"Ativo\"}, {\"value\":\"pending\", \"label\":\"Pendente\"}]}},
            {\"name\": \"date_registered\", \"title\": \"Registrado em\", \"width\": \"20%\", \"sortable\": true, \"type\": \"datetime\"}
          ],
          \"actions\": [
            {\"type\": \"single\", \"name\": \"edit_profile\", \"title\": \"Editar\", \"icon\": \"far pen-to-square\", \"confirm\": false},
            {\"type\": \"single\", \"name\": \"delete_profile\", \"title\": \"Deletar\", \"icon\": \"far trash-alt\", \"confirm\": true},
            {\"type\": \"bulk\", \"name\": \"activate_selected\", \"title\": \"Ativar Selecionados\", \"icon\": \"far check-circle\"},
            {\"type\": \"independent\", \"name\": \"add_new_profile\", \"title\": \"Adicionar Novo\", \"icon\": \"far plus-circle\"}
          ],
          \"default_sort_by\": \"fullname\",
          \"default_sort_order\": \"asc\"
        },
        \"items\": [ // Os dados da grid
          {
            \"id\": 123, // Corresponde a sys_grid_fields.name
            \"fullname\": \"John Doe\",
            \"email\": \"john.doe@example.com\",
            \"status\": \"Ativo\", // Pode ser o valor bruto ou formatado/traduzido
            \"date_registered\": \"2023-03-15T10:00:00Z\",
            \"grid_actions_data\": { // Dados para construir URLs/chamadas para as ações
                \"edit_profile_url\": \"/admin/persons/edit/123\", // Exemplo de link do cliente
                \"delete_profile_api_endpoint\": \"/api/v1/persons/123\" // Exemplo de endpoint da API
            }
          }
          // ... outros itens ...
        ],
        \"pagination\": {
          \"total_items\": 127,
          \"total_pages\": 7,
          \"current_page\": 1,
          \"per_page\": 20
        }
      }
    }
```

```sql
CREATE TABLE IF NOT EXISTS sys_objects_grid (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE,
  source_type TEXT NOT NULL DEFAULT 'Sql' CHECK(source_type IN ('Sql', 'Array')),
  source TEXT NOT NULL, -- Query SQL ou identificador de fonte de dados
  \"table\" TEXT NOT NULL, -- Tabela principal da query
  field_id TEXT NOT NULL, -- Coluna PK
  field_order TEXT NOT NULL, -- Coluna de ordenação padrão (pode ser múltiplas: 'col1 ASC, col2 DESC')
  field_active TEXT, -- Coluna para status ativo/inativo (para ações de ativar/desativar)
  -- order_get_field, order_get_dir (parâmetros de URL no UNA PHP)
  paginate_url TEXT, -- URL base para paginação no UNA PHP
  paginate_per_page INTEGER NOT NULL DEFAULT 10,
  paginate_simple TEXT, -- Se usa paginação simples
  -- paginate_get_start, paginate_get_per_page (parâmetros de URL no UNA PHP)
  filter_fields TEXT, -- CSV ou JSON das colunas filtráveis
  filter_fields_translatable TEXT,
  filter_mode TEXT DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
  -- filter_get (parâmetro de URL no UNA PHP)
  sorting_fields TEXT, -- CSV ou JSON das colunas ordenáveis
  -- sorting_fields_translatable TEXT,
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647,
  responsive INTEGER NOT NULL DEFAULT 1,
  show_total_count INTEGER NOT NULL DEFAULT 1,
  override_class_name TEXT,
  override_class_file TEXT
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_fields (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK para sys_objects_grid.object
  name TEXT NOT NULL, -- Nome da coluna na query source ou nome do campo
  title TEXT NOT NULL, -- Chave de tradução
  width TEXT NOT NULL DEFAULT 'auto', -- Ex: '10%', '100px'
  translatable INTEGER NOT NULL DEFAULT 0, -- Se o valor da célula é uma chave de tradução
  chars_limit INTEGER NOT NULL DEFAULT 0, -- Limite de caracteres para exibição
  params TEXT, -- Para formatação/renderização customizada (originalmente PHP callbacks)
  hidden_on TEXT, -- Ex: 'mobile', 'desktop'
  \"order\" INTEGER NOT NULL DEFAULT 0,
  UNIQUE(object, name)
  -- FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE -- Opcional
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK para sys_objects_grid.object
  type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')),
  name TEXT NOT NULL, -- Nome da ação (ex: 'delete', 'edit')
  title TEXT NOT NULL, -- Chave de tradução
  icon TEXT,
  icon_only INTEGER NOT NULL DEFAULT 0,
  confirm INTEGER NOT NULL DEFAULT 1, -- Se requer confirmação JS
  active INTEGER NOT NULL DEFAULT 1,
  \"order\" INTEGER NOT NULL DEFAULT 0,
  UNIQUE(object, type, name)
  -- FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON DELETE CASCADE -- Opcional
);
```

## Tabelas de Grids (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions` precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações.

**Exemplo `sys_objects_grid` (SQLite):**

**Exemplo `sys_grid_fields` (SQLite):**

**Exemplo `sys_grid_actions` (SQLite):**

## Considerações:

*   **Segurança da Query `source`:** A query SQL em `sys_objects_grid.source` vem do banco de dados. Ao modificá-la para adicionar filtros, ordenação e paginação, deve-se ter extremo cuidado para evitar SQL Injection, especialmente se os nomes dos campos de filtro/ordenação vierem diretamente dos `query_params` do cliente. Validar os nomes dos campos contra `filter_fields` e `sorting_fields` da configuração da grid é essencial.
*   **Formatação de Células (`params` em `sys_grid_fields`):** No UNA PHP, `params` pode conter um callback PHP para renderizar o conteúdo da célula. A API \"Deeper\" não executará PHP.
    *   **Abordagem \"Deeper\":** A API pode retornar o valor bruto. O cliente pode ter lógica para formatar certos tipos de dados (datas, booleanos). Para formatação mais complexa, a API pode retornar metadados adicionais no campo (ex: `{\"type\": \"user_avatar\", \"user_id\": 123, \"avatar_url\": \"...\"}`) que o cliente usa para renderizar um componente específico.
*   **Execução de Ações:** As \"ações\" definidas em `sys_grid_actions` são apenas descritivas. O cliente, ao clicar em uma ação, precisará fazer uma chamada API separada para o endpoint que executa essa ação (ex: `DELETE /api/v1/persons/{id}` para uma ação \"delete_profile\"). O campo `grid_actions_data` na resposta dos itens pode ajudar o cliente a construir essas chamadas.

Este sistema de grids permitirá que o cliente \"Deeper\" exiba dados tabulares complexos de forma flexível e interativa.