# Documentação Deeper: Migrações para o Motor de Grids de Dados

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas que compõem o sistema de grids de dados dinâmicos do UNA.

Isso inclui tabelas para definir os grids (`sys_objects_grid`), suas colunas/campos (`sys_grid_fields`), e as ações disponíveis (`sys_grid_actions`).

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de formulários/grids.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_grid` (`create_sys_objects_grid_table.elixir.md`)**](./create_sys_objects_grid_table.elixir.md):
    *   Cria a tabela principal que define cada \"objeto de grid\".

2.  [**Criar Tabela `sys_grid_fields` (`create_sys_grid_fields_table.elixir.md`)**](./create_sys_grid_fields_table.elixir.md):
    *   Cria a tabela que define cada coluna (campo) a ser exibida no grid. (Depende de `sys_objects_grid`).

3.  [**Criar Tabela `sys_grid_actions` (`create_sys_grid_actions_table.elixir.md`)**](./create_sys_grid_actions_table.elixir.md):
    *   Cria a tabela que define as ações disponíveis para o grid. (Depende de `sys_objects_grid`).

## Ordem de Criação e Dependências:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeiras:
1.  `sys_objects_grid`
2.  `sys_grid_fields` (depois de `sys_objects_grid`)
3.  `sys_grid_actions` (depois de `sys_objects_grid`)