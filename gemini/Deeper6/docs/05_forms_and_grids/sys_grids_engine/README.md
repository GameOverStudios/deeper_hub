# Documentação Deeper: Motor de Grades de Dados Dinâmicas

Este componente da API \"Deeper\" é responsável por fornecer os dados e as definições necessárias para que o cliente possa renderizar grades (tabelas) de dados dinâmicas, com suporte a paginação, filtragem, ordenação e ações.

Ele se baseia nas tabelas `sys_objects_grid`, `sys_grid_fields`, e `sys_grid_actions` do UNA.

## Responsabilidades Principais:

*   Fornecer a definição de uma grade específica, incluindo:
    *   Informações sobre a fonte de dados (tabela principal, campos chave).
    *   Lista de campos/colunas a serem exibidos (`sys_grid_fields`), com seus títulos e propriedades.
    *   Lista de ações disponíveis para os itens da grade ou para a grade como um todo (`sys_grid_actions`).
    *   Configurações de paginação, filtragem e ordenação.
*   Fornecer os dados a serem exibidos na grade, com base nos parâmetros de paginação, filtros e ordenação fornecidos pelo cliente.

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_objects_grid`, `sys_grid_fields`, e `sys_grid_actions`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do motor de grades.
    *   Links para:
        *   [Criar Tabela `sys_objects_grid` (`create_sys_objects_grid_table.elixir.md`)](./migrations/create_sys_objects_grid_table.elixir.md)
        *   [Criar Tabela `sys_grid_fields` (`create_sys_grid_fields_table.elixir.md`)](./migrations/create_sys_grid_fields_table.elixir.md)
        *   [Criar Tabela `sys_grid_actions` (`create_sys_grid_actions_table.elixir.md`)](./migrations/create_sys_grid_actions_table.elixir.md)

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o módulo Elixir (ex: `Deeper.Grids.GridRepo`) que encapsula as queries SQL para:
        *   Buscar a definição de um objeto de grade.
        *   Buscar os dados para uma grade, aplicando dinamicamente as cláusulas `WHERE` (filtros), `ORDER BY` (ordenação), `LIMIT` e `OFFSET` (paginação) na query SQL principal.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para:
        *   Obter a definição de uma grade: `GET /api/v1/grids/{grid_object_name}/definition`
        *   Obter os dados de uma grade: `GET /api/v1/grids/{grid_object_name}/data` (com query params para paginação, filtros, ordenação).

## Fluxo de Obtenção e Exibição de uma Grade:

1.  **Cliente solicita definição da grade:**
    *   Ex: `GET /api/v1/grids/bx_persons_administration/definition`
    *   API (via `GridRepo`) busca metadados de `sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`.
    *   API retorna a definição em JSON.
2.  **Cliente renderiza a estrutura da grade:**
    *   Com base na definição, o cliente monta o cabeçalho da tabela (colunas), os controles de filtro (se houver campos de filtro definidos), e os botões de ação.
3.  **Cliente solicita dados da grade (primeira página):**
    *   Ex: `GET /api/v1/grids/bx_persons_administration/data?page=1&per_page=20`
    *   API (via `GridRepo`):
        *   Busca a definição do objeto de grade em `sys_objects_grid` para saber a `source_type`, `source` (query SQL base), `table`, `field_id`, `field_order`.
        *   Constrói dinamicamente a query SQL:
            *   Começa com a query base do `source`.
            *   Adiciona cláusulas `WHERE` com base nos `filter_fields` e nos query params de filtro enviados pelo cliente.
            *   Adiciona cláusula `ORDER BY` com base no `field_order` padrão ou no query param `sort_by` enviado pelo cliente.
            *   Adiciona `LIMIT` e `OFFSET` com base nos query params `page` e `per_page`.
        *   Executa a query SQL para os dados.
        *   Executa uma query `COUNT(*)` (com os mesmos filtros, mas sem `LIMIT`/`OFFSET`) para obter o `total_items` para a paginação.
    *   API retorna os dados da página atual e os metadados de paginação em JSON.
4.  **Cliente exibe os dados na grade.**
5.  **Interações do Usuário (Paginação, Filtro, Ordenação):**
    *   Quando o usuário clica para ir para outra página, aplicar um filtro ou mudar a ordenação, o cliente faz uma nova requisição ao endpoint `/data` com os novos query parameters. A API reconstrói e executa a query SQL.