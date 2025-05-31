# Documentação Deeper: Migrações para o Motor de Menus

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de menus (`sys_menu_*`, `sys_objects_menu`) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/menu_engine/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_menu_sets` (`create_sys_menu_sets_table.elixir.md`)**](./create_sys_menu_sets_table.elixir.md)
2.  [**Criar Tabela `sys_menu_templates` (`create_sys_menu_templates_table.elixir.md`)**](./create_sys_menu_templates_table.elixir.md)
3.  [**Criar Tabela `sys_objects_menu` (`create_sys_objects_menu_table.elixir.md`)**](./create_sys_objects_menu_table.elixir.md)
4.  [**Criar Tabela `sys_menu_items` (`create_sys_menu_items_table.elixir.md`)**](./create_sys_menu_items_table.elixir.md)

## Ordem de Execução:

As migrações devem ser executadas na seguinte ordem:
1.  `sys_menu_sets`
2.  `sys_menu_templates`
3.  `sys_objects_menu` (depende de `sys_menu_templates` e, logicamente, de `sys_menu_sets`)
4.  `sys_menu_items` (logicamente depende de `sys_menu_sets` e `sys_objects_menu` para `submenu_object`)