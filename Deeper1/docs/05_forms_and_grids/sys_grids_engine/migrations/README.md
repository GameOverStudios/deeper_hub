# Documentação Deeper: Migrações para Motor de Grids

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Grids (`sys_objects_grid`, `sys_grid_fields`, `sys_grid_actions`) do UNA.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_grid` (`create_sys_objects_grid_table.elixir.md`)**](./create_sys_objects_grid_table.elixir.md):
    *   Cria a tabela que define cada grid no sistema, incluindo sua fonte de dados SQL e configurações de paginação, filtro e ordenação.

2.  [**Criar Tabela `sys_grid_fields` (`create_sys_grid_fields_table.elixir.md`)**](./create_sys_grid_fields_table.elixir.md):
    *   Cria a tabela que define as colunas a serem exibidas em cada grid.

3.  [**Criar Tabela `sys_grid_actions` (`create_sys_grid_actions_table.elixir.md`)**](./create_sys_grid_actions_table.elixir.md):
    *   Cria a tabela que define as ações (single, bulk, independent) disponíveis para cada grid.

## Ordem e Dependências:

*   `sys_objects_grid` é a tabela central.
*   `sys_grid_fields` depende de `sys_objects_grid` (via coluna `object`).
*   `sys_grid_actions` depende de `sys_objects_grid` (via coluna `object`).

O sistema de execução de migrações deve idealmente criar `sys_objects_grid` primeiro, embora as FKs explícitas não estejam sendo definidas nas migrações SQLite iniciais para manter a fidelidade com o dump original do UNA, que também as omite. A integridade relacional é mantida pela lógica da aplicação.