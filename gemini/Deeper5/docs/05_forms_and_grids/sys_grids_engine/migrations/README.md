# Documentação Deeper: Migrações para o Motor de Grades

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Grades Dinâmicas (`sys_objects_grid`, etc.) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/grids_engine/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_grid` (`create_sys_objects_grid_table.elixir.md`)**](./create_sys_objects_grid_table.elixir.md)
2.  [**Criar Tabela `sys_grid_fields` (`create_sys_grid_fields_table.elixir.md`)**](./create_sys_grid_fields_table.elixir.md)
3.  [**Criar Tabela `sys_grid_actions` (`create_sys_grid_actions_table.elixir.md`)**](./create_sys_grid_actions_table.elixir.md)

## Ordem de Execução:

1.  `sys_objects_grid`
2.  `sys_grid_fields` (logicamente depende de `sys_objects_grid`)
3.  `sys_grid_actions` (logicamente depende de `sys_objects_grid`)