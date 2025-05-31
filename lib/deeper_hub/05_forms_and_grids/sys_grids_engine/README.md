# Documentação Deeper: Motor de Grids de Dados (`sys_grids_engine`)

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de grids de dados dinâmicos do UNA. O objetivo é permitir que um cliente remoto obtenha a definição de um grid (suas colunas, ações disponíveis, filtros, opções de ordenação) e os dados para preencher esse grid, incluindo suporte a paginação.

O cliente será responsável por renderizar a UI do grid com base nessas definições e dados.

## Tabelas Relevantes do UNA:

*   **`sys_objects_grid`**: Define cada \"objeto de grid\" (uma instância de um grid), especificando sua fonte de dados (SQL ou Array no UNA PHP), tabela principal, campo ID, campo de ordenação padrão, filtros, etc.
*   **`sys_grid_fields`**: Define cada coluna (campo) a ser exibida no grid, incluindo título, largura, se é traduzível, etc.
*   **`sys_grid_actions`**: Define as ações disponíveis para o grid, tanto ações em massa (para múltiplos itens selecionados) quanto ações individuais por linha, ou ações independentes.

## Responsabilidades da API \"Deeper\":

1.  **Fornecer Definição do Grid:**
    *   Dado o nome de um objeto de grid, retornar sua estrutura completa:
        *   Atributos do grid (da `sys_objects_grid`).
        *   Lista de campos/colunas (de `sys_grid_fields`).
        *   Lista de ações disponíveis (de `sys_grid_actions`).
        *   Opções de filtro e ordenação configuradas.
2.  **Fornecer Dados para o Grid:**
    *   Um endpoint para buscar os dados que preenchem o grid, aplicando filtros, ordenação e paginação conforme solicitado pelo cliente e permitido pela configuração do grid.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_objects_grid`, `sys_grid_fields`, e `sys_grid_actions`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.Grids.GridsRepo` e suas funções para buscar definições de grids e para executar as queries (SQL direto) para obter os dados do grid, aplicando filtros, ordenação e paginação.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `GET /grids/{grid_object_name}/definition` e `GET /grids/{grid_object_name}/data`).

## Considerações Importantes:

*   **Fonte de Dados (`sys_objects_grid.source_type`, `sys_objects_grid.source`):**
    *   No UNA PHP, a fonte de dados pode ser `Sql` (uma query SQL completa) ou `Array` (um array PHP).
    *   Para a API \"Deeper\", se `source_type` for `Sql`, o `GridsRepo` precisará executar essa query SQL (com modificações para filtros, paginação, ordenação). Isso requer cuidado extremo com a segurança se a query original do UNA for usada diretamente. Idealmente, a query seria reconstruída de forma segura em Elixir com base nos parâmetros do grid.
    *   Se `source_type` for `Array`, essa fonte de dados precisaria ser portada para uma lógica Elixir ou um endpoint que forneça esses dados.
    *   **Abordagem Inicial \"Deeper\":** Focar em grids onde a `source` pode ser interpretada como uma tabela principal (`sys_objects_grid.table`) com campos definidos, e o `GridsRepo` constrói a query SQL de forma segura.
*   **Filtros e Ordenação:** A API permitirá que o cliente passe parâmetros para filtrar e ordenar os dados do grid, mas apenas para os campos configurados como filtráveis/ordenáveis em `sys_objects_grid.filter_fields` e `sys_objects_grid.sorting_fields`.
*   **Tradução de Títulos:** Títulos de colunas e ações podem ser chaves de linguagem e precisarão ser traduzidos.
*   **Ações do Grid:** A API retornará a definição das ações. A execução dessas ações (ex: \"deletar item selecionado\") será feita através de outros endpoints da API \"Deeper\" (ex: `DELETE /api/v1/resource/{id}`), e o cliente construirá a chamada apropriada.