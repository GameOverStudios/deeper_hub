# Documentação Deeper: Migrações para Módulo de Grupos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Grupos (`deeper_groups`) no sistema \"Deeper\".

## Ordem das Migrações:

1.  `deeper_groups_categories`
2.  `deeper_groups_entries` (depende de `sys_profiles`, `deeper_groups_categories`)
3.  `deeper_groups_members` (depende de `deeper_groups_entries`, `sys_profiles`)
4.  `deeper_groups_invites` (depende de `deeper_groups_entries`, `sys_profiles`)
5.  `deeper_groups_content_feed` (depende de `deeper_groups_entries`, `sys_profiles`)

As tabelas `sys_profiles` devem existir antes da execução destas migrações.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_groups_categories` (`create_deeper_groups_categories_table.elixir.md`)**](./create_deeper_groups_categories_table.elixir.md)
2.  [**Criar Tabela `deeper_groups_entries` (`create_deeper_groups_entries_table.elixir.md`)**](./create_deeper_groups_entries_table.elixir.md)
3.  [**Criar Tabela `deeper_groups_members` (`create_deeper_groups_members_table.elixir.md`)**](./create_deeper_groups_members_table.elixir.md)
4.  [**Criar Tabela `deeper_groups_invites` (`create_deeper_groups_invites_table.elixir.md`)**](./create_deeper_groups_invites_table.elixir.md)
5.  [**Criar Tabela `deeper_groups_content_feed` (`create_deeper_groups_content_feed_table.elixir.md`)**](./create_deeper_groups_content_feed_table.elixir.md)