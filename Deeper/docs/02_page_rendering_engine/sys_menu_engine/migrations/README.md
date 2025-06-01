# Documentação Deeper: Migrações para Motor de Menus

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Motor de Menus no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Ordem das Migrações:

É importante executar estas migrações na ordem correta devido às dependências de chave estrangeira:

1.  `sys_menu_sets` e `sys_menu_templates` (podem ser criadas em qualquer ordem entre si).
2.  `sys_objects_menu` (depende de `sys_menu_sets` e `sys_menu_templates`).
3.  `sys_menu_items` (depende de `sys_menu_sets`).

## Migrações Definidas:

1.  [**Criar Tabela `sys_menu_sets` (`create_sys_menu_sets_table.elixir.md`)**](./create_sys_menu_sets_table.elixir.md):
    *   Cria a tabela para armazenar conjuntos de menus.

2.  [**Criar Tabela `sys_menu_templates` (`create_sys_menu_templates_table.elixir.md`)**](./create_sys_menu_templates_table.elixir.md):
    *   Cria a tabela para armazenar templates de renderização de menu.

3.  [**Criar Tabela `sys_objects_menu` (`create_sys_objects_menu_table.elixir.md`)**](./create_sys_objects_menu_table.elixir.md):
    *   Cria a tabela para armazenar objetos de menu concretos que são instanciados no sistema.

4.  [**Criar Tabela `sys_menu_items` (`create_sys_menu_items_table.elixir.md`)**](./create_sys_menu_items_table.elixir.md):
    *   Cria a tabela para armazenar os itens individuais de cada menu.