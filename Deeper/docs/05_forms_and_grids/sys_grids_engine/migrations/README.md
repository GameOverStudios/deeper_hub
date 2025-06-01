# Documentação Deeper: Migrações para Motor de Grades

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Motor de Grades de Dados no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Ordem das Migrações:

É importante executar estas migrações na ordem correta devido às dependências de chave estrangeira:

1.  `sys_objects_grid`
2.  `sys_grid_fields` (depende de `sys_objects_grid`)
3.  `sys_grid_actions` (depende de `sys_objects_grid`)

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_grid` (`create_sys_objects_grid_table.elixir.md`)**](./create_sys_objects_grid_table.elixir.md):
    *   Cria a tabela para armazenar as definições dos objetos de grade.

2.  [**Criar Tabela `sys_grid_fields` (`create_sys_grid_fields_table.elixir.md`)**](./create_sys_grid_fields_table.elixir.md):
    *   Cria a tabela para armazenar as definições das colunas de cada grade.

3.  [**Criar Tabela `sys_grid_actions` (`create_sys_grid_actions_table.elixir.md`)**](./create_sys_grid_actions_table.elixir.md):
    *   Cria a tabela para armazenar as definições das ações disponíveis nas grades.