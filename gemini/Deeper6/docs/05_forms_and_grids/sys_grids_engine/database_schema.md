# Documentação Deeper: Esquema do Banco de Dados para Motor de Grades (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas que compõem o motor de grades de dados do UNA, adaptadas para o projeto \"Deeper\": `sys_objects_grid`, `sys_grid_fields`, e `sys_grid_actions`.

## Tabela: `sys_objects_grid`

Define os objetos de grade, que são instâncias configuráveis de tabelas de dados exibidas no sistema.

```sql
CREATE TABLE IF NOT EXISTS sys_objects_grid (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de grade (ex: bx_persons_administration)
  source_type TEXT NOT NULL CHECK(source_type IN ('Sql', 'Array')), -- Tipo da fonte de dados
  source TEXT NOT NULL, -- Se Sql: a query SQL base. Se Array: nome da variável PHP ou método (precisará de adaptação)
  table_name TEXT NOT NULL, -- Tabela principal para operações CRUD (originalmente `table`)
  field_id TEXT NOT NULL, -- Nome da coluna de ID na `table_name`
  field_order TEXT NOT NULL, -- Coluna padrão para ordenação (ex: `added DESC`)
  field_active TEXT, -- Coluna para status de ativo/inativo (opcional)
  -- order_get_field TEXT NOT NULL DEFAULT 'order_field', -- Nome do param GET para campo de ordenação
  -- order_get_dir TEXT NOT NULL DEFAULT 'order_dir', -- Nome do param GET para direção de ordenação
  paginate_url TEXT, -- URL base para paginação (menos relevante para API, cliente controla)
  paginate_per_page INTEGER NOT NULL DEFAULT 10,
  -- paginate_simple TEXT,
  paginate_get_start TEXT, -- Nome do param GET para offset/start (ex: 'start' ou 'offset')
  paginate_get_per_page TEXT, -- Nome do param GET para limite (ex: 'per_page' ou 'limit')
  filter_fields TEXT, -- Lista de campos pesquisáveis (separados por vírgula)
  -- filter_fields_translatable TEXT,
  filter_mode TEXT NOT NULL DEFAULT 'auto' CHECK(filter_mode IN ('like', 'fulltext', 'auto')),
  filter_get TEXT DEFAULT 'filter', -- Nome do param GET para o termo de filtro geral
  sorting_fields TEXT, -- Lista de campos pelos quais se pode ordenar (separados por vírgula)
  -- sorting_fields_translatable TEXT,
  visible_for_levels INTEGER NOT NULL DEFAULT 2147483647, -- Bitmask ACL
  responsive INTEGER NOT NULL DEFAULT 1, -- Se a grade deve ser responsiva (dica para o cliente)
  show_total_count INTEGER NOT NULL DEFAULT 1 -- Se deve mostrar a contagem total de itens
  -- override_class_name TEXT,
  -- override_class_file TEXT
);
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_fields (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK para sys_objects_grid.object
  name TEXT NOT NULL, -- Nome da coluna/campo (geralmente corresponde a um alias na query `source` do grid)
  title TEXT NOT NULL, -- Título da coluna a ser exibido (pode ser chave de tradução)
  width TEXT NOT NULL DEFAULT 'auto', -- Largura da coluna (ex: '10%', '100px', 'auto')
  translatable INTEGER NOT NULL DEFAULT 0, -- Se o conteúdo do campo é traduzível
  chars_limit INTEGER NOT NULL DEFAULT 0, -- Limite de caracteres para exibição (0 = sem limite)
  params TEXT, -- Parâmetros adicionais para formatação ou renderização (JSON ou string serializada)
  hidden_on TEXT, -- Condições de ocultação baseadas em dispositivo/resolução (ex: \"xs,sm\")
  \"order\" INTEGER NOT NULL, -- Ordem de exibição da coluna
  FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_grid_fields_object_order ON sys_grid_fields(object, \"order\");
CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_grid_fields_object_name ON sys_grid_fields(object, name);
```

```sql
CREATE TABLE IF NOT EXISTS sys_grid_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL, -- FK para sys_objects_grid.object
  type TEXT NOT NULL CHECK(type IN ('bulk', 'single', 'independent')), -- Tipo de ação
  name TEXT NOT NULL, -- Nome programático da ação
  title TEXT NOT NULL, -- Texto do botão/link da ação (pode ser chave de tradução)
  icon TEXT, -- Ícone para a ação
  icon_only INTEGER NOT NULL DEFAULT 0, -- Se deve mostrar apenas o ícone
  confirm INTEGER NOT NULL DEFAULT 1, -- Se a ação requer confirmação do usuário
  active INTEGER NOT NULL DEFAULT 1, -- Se a ação está ativa
  \"order\" INTEGER NOT NULL, -- Ordem de exibição da ação
  -- No UNA PHP, actions geralmente têm um `onClick` ou uma URL.
  -- Para a API \"Deeper\", precisaremos definir como a ação será tratada:
  -- 1. Um endpoint API específico (ex: DELETE /api/v1/resource/{id})
  -- 2. Um evento que o cliente dispara, e o cliente sabe qual endpoint chamar.
  -- Adicionaremos um campo para isso:
  api_endpoint TEXT, -- Ex: \"DELETE /api/v1/module/resource/{id_placeholder}\" ou \"EVENT:delete_item\"
  api_method TEXT, -- GET, POST, PUT, DELETE (se api_endpoint for uma URL)
  id_placeholder_field TEXT DEFAULT 'id' -- Nome do campo da linha cujo valor substitui {id_placeholder}
  FOREIGN KEY (object) REFERENCES sys_objects_grid(object) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_grid_actions_object_order ON sys_grid_actions(object, \"order\");
CREATE UNIQUE INDEX IF NOT EXISTS idx_sys_grid_actions_object_name_type ON sys_grid_actions(object, name, type);
```

*   **`object`**: Identificador único da grade.
*   **`source_type`**: `Sql` é o mais comum. `Array` significaria que os dados vêm de uma fonte não-SQL no PHP UNA, o que exigiria uma lógica especial de portabilidade para \"Deeper\". **Foco inicial em `Sql`**.
*   **`source`**: A query SQL base que busca os dados. A API \"Deeper\" irá adicionar `WHERE`, `ORDER BY`, `LIMIT`, `OFFSET` a esta query.
*   **`table_name`**: Tabela principal de onde os dados vêm, útil para saber contra qual tabela as ações (ex: deletar) seriam aplicadas. (Nome original era `table`).
*   **`field_id`**: Nome da coluna que serve como identificador único para cada linha.
*   **`field_order`**: Coluna(s) e direção para ordenação padrão (ex: `title ASC`, `added DESC`).
*   **`field_active`**: Nome da coluna (opcional) que indica se um registro está ativo.
*   **`paginate_per_page`**: Número padrão de itens por página.
*   **`paginate_get_start`, `paginate_get_per_page`**: Nomes dos query parameters que o cliente usará para paginação (ex: `offset`, `limit` ou `start`, `per_page`). A API \"Deeper\" precisará lê-los.
*   **`filter_fields`**: Lista de nomes de colunas (da query `source`) que podem ser usadas para filtragem textual geral.
*   **`filter_mode`**: Como a filtragem deve ser aplicada (`LIKE`, `FULLTEXT` - FTS do SQLite se implementado).
*   **`filter_get`**: Nome do query parameter que o cliente usará para enviar o termo de filtro geral.
*   **`sorting_fields`**: Lista de nomes de colunas pelas quais o cliente pode solicitar ordenação.
*   **`visible_for_levels`**: Bitmask ACL para controlar quem pode ver a grade.
*   **`responsive`, `show_total_count`**: Dicas para a renderização no cliente.

## Tabela: `sys_grid_fields`

Define as colunas que serão exibidas em uma grade específica.

*   **`object`**: Referencia a qual `sys_objects_grid` este campo pertence.
*   **`name`**: O nome do campo, que deve corresponder a uma coluna retornada pela query `source` do `sys_objects_grid`.
*   **`title`**: O cabeçalho da coluna a ser exibido (pode ser uma chave de linguagem).
*   **`width`**: Sugestão de largura para o cliente.
*   **`translatable`**: Indica se o valor deste campo precisa de tradução (ex: um status que é uma chave de linguagem).
*   **`chars_limit`**: Para truncar texto longo.
*   **`params`**: Pode conter informações sobre como formatar o valor (ex: formatar data, transformar em link, usar um componente específico). A API \"Deeper\" pode passar isso para o cliente.
*   **`hidden_on`**: Dica para o cliente sobre quando ocultar a coluna.
*   **`order`**: Ordem das colunas na grade.

## Tabela: `sys_grid_actions`

Define as ações (botões, links) disponíveis para cada linha da grade ou para a grade como um todo.

*   **`object`**: Referencia a qual `sys_objects_grid` esta ação pertence.
*   **`type`**:
    *   `single`: Ação por linha (ex: Editar, Deletar).
    *   `bulk`: Ação em múltiplas linhas selecionadas (ex: Deletar Selecionados).
    *   `independent`: Ação que não depende de seleção de linha (ex: Adicionar Novo).
*   **`name`**: Identificador da ação.
*   **`title`**: Texto da ação.
*   **`icon`, `icon_only`, `confirm`**: Dicas de UI para o cliente.
*   **`active`, `order`**: Status e ordem.
*   **`api_endpoint`**: **Campo crucial para a API \"Deeper\"**. Define o que acontece quando a ação é acionada.
    *   Pode ser um padrão de URL da API, onde `{id_placeholder}` (ou outro placeholder definido em `id_placeholder_field`) é substituído pelo valor do campo `field_id` da linha (para ações `single`).
    *   Pode ser um identificador de evento que o cliente entende e sabe qual requisição fazer (ex: \"EVENT:open_add_form\").
*   **`api_method`**: O método HTTP a ser usado se `api_endpoint` for uma URL.
*   **`id_placeholder_field`**: Se a ação `single` precisa de um ID de um campo que não seja o `field_id` principal da grade.

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas três tabelas.