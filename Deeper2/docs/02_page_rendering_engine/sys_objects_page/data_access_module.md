# Documentação Deeper: Módulo de Acesso a Dados para Páginas e Blocos (`PagesRepo`)

Este documento descreve o módulo Elixir `Deeper.PageEngine.PagesRepo` (ou um nome similar), responsável por encapsular a lógica de consulta às tabelas que definem a estrutura e o conteúdo das páginas dinâmicas do UNA (`sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`, `sys_pages_design_boxes`, `sys_pages_types`).

O objetivo principal deste Repo é fornecer os dados necessários para que a API \"Deeper\" possa expor a estrutura de uma página e seus blocos de forma que um cliente possa reconstruí-la.

**Localização do Código:** `lib/deeper/page_engine/pages_repo.ex`

## Funções Principais (Exemplos):

### 1. Obter Definição Completa de uma Página (por URI ou Nome de Objeto)

*   **`get_page_definition(identifier :: String.t(), by :: :uri | :object_name) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca a definição completa de uma página, incluindo seus metadados e a lista de seus blocos.
    *   **Argumentos:**
        *   `identifier`: O URI da página (ex: `/m/persons/home`) ou o nome do objeto de página (ex: `persons_home`).
        *   `by`: Átomo `:uri` ou `:object_name` para indicar como `identifier` deve ser usado.
    *   **Retorno:**
        *   `{:ok, page_data_map}`: Um mapa contendo os dados da página e uma lista de seus blocos. Exemplo da estrutura:

```sql
                SELECT
                    sop.*,
                    spl.name AS layout_name,
                    spl.template AS layout_template,
                    spl.cells_number AS layout_cells_number
                FROM sys_objects_page sop
                JOIN sys_pages_layouts spl ON sop.layout_id = spl.id
                WHERE sop.object = ?; -- ou sop.uri = ?
```

```sql
                SELECT
                    spb.*,
                    spd.template AS designbox_template -- de sys_pages_design_boxes
                FROM sys_pages_blocks spb
                LEFT JOIN sys_pages_design_boxes spd ON spb.designbox_id = spd.id
                WHERE spb.object = ? -- object_name da página obtida no passo 1
                  -- AND spb.active = 1 -- Adicionar se necessário filtrar blocos inativos
                ORDER BY spb.cell_id, spb.\"order\";
```

```elixir
            %{
              id: 10,
              object: \"persons_home\",
              uri: \"m/persons/home\",
              title: \"Pessoas\",
              module: \"bx_persons\",
              layout_id: 2,
              layout_name: \"layout_2_columns\", # Obtido por JOIN ou query separada
              layout_template: \"layout_2_columns.html\",
              layout_cells_number: 2,
              submenu_object: \"bx_persons_submenu_member\",
              visible_for_levels: 2147483647,
              cache_lifetime: 0,
              # ... outros campos de sys_objects_page ...
              blocks: [
                %{
                  id: 101,
                  cell_id: 1,
                  module: \"bx_persons\",
                  title: \"Novos Perfis\",
                  designbox_id: 11,
                  designbox_template: \"designbox_11.html\", # Obtido por JOIN ou query separada
                  type: \"service\",
                  content: %{module: \"bx_persons\", method: \"service_latest_profiles\", params: %{count: 5}}, # Conteúdo parseado para 'service'
                  # ... outros campos de sys_pages_blocks ...
                  order: 1
                },
                # ... outros blocos ...
              ]
            }
```

        *   `{:error, :not_found}`: Página não encontrada.
        *   `{:error, reason}`: Outro erro de banco de dados.
    *   **Lógica Interna Detalhada:**
        1.  **Buscar `sys_objects_page`:**
            *   SQL (se `by == :uri`): `SELECT * FROM sys_objects_page WHERE uri = ? LIMIT 1;`
            *   SQL (se `by == :object_name`): `SELECT * FROM sys_objects_page WHERE object = ? LIMIT 1;`
            *   Parâmetro: `identifier`.
            *   Se não encontrar, retorna `{:error, :not_found}`.
        2.  **Opcional: Buscar detalhes do Layout (`sys_pages_layouts`):**
            *   Se o `layout_id` foi obtido, buscar `name`, `template`, `cells_number` de `sys_pages_layouts`. Pode ser feito com um `JOIN` na query do passo 1 ou uma query separada.
            *   SQL (com JOIN):

        3.  **Buscar Blocos da Página (`sys_pages_blocks`):**
            *   SQL:

            *   Parâmetro: `page.object`.
        4.  **Processar Blocos:**
            *   Para cada bloco:
                *   Se `type == \"service\"`, o campo `content` (que é uma string serializada no UNA, ex: `a:3:{s:6:\"module\";s:10:\"bx_persons\";...}`) precisa ser **parseado** para uma estrutura de mapa Elixir. Uma função utilitária para desserializar strings PHP serializadas pode ser necessária, ou assumir um formato JSON se a API de Admin permitir salvar nesse formato.
                *   Se `type == \"menu\"`, o `content` é o nome do objeto de menu.
                *   Se `type == \"lang\"`, o `content` é a chave de linguagem.
                *   Se `type == \"image\"`, o `content` é o ID da imagem.
                *   (Opcional) Se `sys_pages_blocks_data` for usado, verificar overrides para os blocos no contexto atual (pode ser complexo e adiado).
        5.  Combinar todos os dados no mapa de retorno.

### 2. Listar Layouts de Página Disponíveis

*   **`list_page_layouts() :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todos os layouts de página definidos em `sys_pages_layouts`.
    *   **SQL:** `SELECT id, name, icon, title, template, cells_number FROM sys_pages_layouts ORDER BY title;`
    *   Retorna: `{:ok, [%{id: 1, name: \"layout_1_column\", ...}, ...]}`

### 3. Listar Design Boxes Disponíveis

*   **`list_design_boxes() :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todos os design boxes definidos em `sys_pages_design_boxes`.
    *   **SQL:** `SELECT id, title, template, \"order\" FROM sys_pages_design_boxes ORDER BY \"order\", title;`

### 4. Listar Tipos de Página Disponíveis

*   **`list_page_types() :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todos os tipos de página definidos em `sys_pages_types`.
    *   **SQL:** `SELECT id, title, template, \"order\" FROM sys_pages_types ORDER BY \"order\", title;`

### Funções Auxiliares (Internas):

*   **`parse_php_serialized_string(serialized_string :: String.t()) :: map() | list() | any()`**
    *   Uma função para desserializar strings PHP (formato `a:N:{...}`). Isso pode ser um desafio em Elixir.
        *   **Alternativa 1:** Se possível, ao popular o banco de dados para \"Deeper\" ou através da API de Admin, converter esses campos para JSON.
        *   **Alternativa 2:** Encontrar ou criar uma biblioteca Elixir que possa parsear esse formato (pode ser limitada ou complexa).
        *   **Alternativa 3 (Simplificada):** Para `type: \"service\"`, se o formato for consistente, usar regex ou parsing de string para extrair `module`, `method` e `params`. Os `params` em si podem ser outra string serializada ou JSON.
    *   Para o `content` de blocos de serviço, a estrutura esperada é algo como `%{module: \"...\", method: \"...\", params: %{...}}`.

### Considerações:

*   **Desserialização de Conteúdo de Bloco:** A desserialização do campo `content` de `sys_pages_blocks` (especialmente para blocos do tipo `service`) é o maior desafio técnico aqui.
*   **Visibilidade de Blocos:** A função `get_page_definition/2` precisará, eventualmente, de acesso ao `IDLevel` do usuário autenticado para filtrar os blocos com base em `visible_for_levels`. Isso pode ser passado como um argumento adicional.
*   **Performance:** A query para buscar blocos pode ser otimizada. O JOIN com `sys_pages_design_boxes` é útil.
*   **Caching:** A definição de uma página (`sys_objects_page` e seus blocos estáticos) pode ser cacheada. O conteúdo dinâmico de blocos de serviço não seria parte deste cache.
*   **Módulos de Conteúdo:** A lógica para realmente buscar os dados para blocos de \"serviço\" residirá nos Repos dos respectivos módulos de conteúdo (ex: `PersonsRepo.service_latest_profiles(params)`). O `PagesRepo` apenas identifica que tal serviço precisa ser chamado.