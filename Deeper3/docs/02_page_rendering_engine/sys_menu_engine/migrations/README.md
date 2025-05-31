# Documentação Deeper: Migrações para o Motor de Menus

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas que compõem o sistema de menus do UNA (`sys_objects_menu`, `sys_menu_sets`, `sys_menu_items`, `sys_menu_templates`).

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_menu_templates` (`create_sys_menu_templates_table.elixir.md`)**](./create_sys_menu_templates_table.elixir.md):
    *   Cria a tabela para definir os templates de visualização dos menus.

2.  [**Criar Tabela `sys_menu_sets` (`create_sys_menu_sets_table.elixir.md`)**](./create_sys_menu_sets_table.elixir.md):
    *   Cria a tabela para definir conjuntos lógicos de itens de menu.

3.  [**Criar Tabela `sys_objects_menu` (`create_sys_objects_menu_table.elixir.md`)**](./create_sys_objects_menu_table.elixir.md):
    *   Cria a tabela para definir instâncias de menu (\"objetos de menu\"), ligando um conjunto de itens a um template. (Depende de `sys_menu_templates` e `sys_menu_sets`).

4.  [**Criar Tabela `sys_menu_items` (`create_sys_menu_items_table.elixir.md`)**](./create_sys_menu_items_table.elixir.md):
    *   Cria a tabela para armazenar os itens individuais de cada menu. (Depende de `sys_menu_sets` e conceitualmente de `sys_objects_menu` para `submenu_object`).

## Ordem de Criação e Dependências:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeiras:
1.  `sys_menu_templates`
2.  `sys_menu_sets`
3.  `sys_objects_menu` (depois de `sys_menu_templates` e `sys_menu_sets`)
4.  `sys_menu_items` (depois de `sys_menu_sets`; a FK para `submenu_object` em `sys_objects_menu` é mais uma referência lógica do que uma constraint estrita de criação, mas a tabela `sys_objects_menu` deve existir).