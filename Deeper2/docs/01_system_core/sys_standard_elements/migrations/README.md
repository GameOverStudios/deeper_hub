# Documentação Deeper: Migrações para Elementos Padrão do Sistema (`sys_std_*`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas de \"Elementos Padrão\" (`sys_std_*`) do sistema UNA. Essas tabelas definem componentes como páginas padrão do Studio, widgets e papéis básicos.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_std_pages` (`create_sys_std_pages_table.elixir.md`)**](./create_sys_std_pages_table.elixir.md)
2.  [**Criar Tabela `sys_std_widgets` (`create_sys_std_widgets_table.elixir.md`)**](./create_sys_std_widgets_table.elixir.md)
3.  [**Criar Tabela `sys_std_pages_widgets` (`create_sys_std_pages_widgets_table.elixir.md`)**](./create_sys_std_pages_widgets_table.elixir.md)
4.  [**Criar Tabela `sys_std_roles` (`create_sys_std_roles_table.elixir.md`)**](./create_sys_std_roles_table.elixir.md)
5.  [**Criar Tabela `sys_std_roles_actions` (`create_sys_std_roles_actions_table.elixir.md`)**](./create_sys_std_roles_actions_table.elixir.md)
6.  [**Criar Tabela `sys_std_roles_actions2roles` (`create_sys_std_roles_actions2roles_table.elixir.md`)**](./create_sys_std_roles_actions2roles_table.elixir.md)
7.  [**Criar Tabela `sys_std_roles_members` (`create_sys_std_roles_members_table.elixir.md`)**](./create_sys_std_roles_members_table.elixir.md)
8.  [**Criar Tabela `sys_std_widgets_bookmarks` (`create_sys_std_widgets_bookmarks_table.elixir.md`)**](./create_sys_std_widgets_bookmarks_table.elixir.md)

## Ordem de Criação e Dependências:

*   `sys_std_pages`, `sys_std_widgets`, `sys_std_roles`, `sys_std_roles_actions` podem ser criadas primeiro.
*   `sys_std_pages_widgets` depende de `sys_std_pages` e `sys_std_widgets`.
*   `sys_std_roles_actions2roles` depende de `sys_std_roles` e `sys_std_roles_actions`.
*   `sys_std_roles_members` depende de `sys_std_roles` e `sys_accounts`.
*   `sys_std_widgets_bookmarks` depende de `sys_std_widgets` e `sys_profiles`.

As migrações devem ser executadas respeitando essas dependências.