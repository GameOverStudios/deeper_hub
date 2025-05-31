# Documentação Deeper: Migrações para Controle de Acesso (ACL)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Controle de Acesso (ACL) no \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/acl/` (sugestão de subpasta para organização).

## Migrações Definidas:

1.  [**Criar Tabela `sys_acl_levels` (`create_sys_acl_levels_table.elixir.md`)**](./create_sys_acl_levels_table.elixir.md):
    *   Cria a tabela para definir os diferentes níveis de membresia.

2.  [**Criar Tabela `sys_acl_actions` (`create_sys_acl_actions_table.elixir.md`)**](./create_sys_acl_actions_table.elixir.md):
    *   Cria a tabela para definir as ações controláveis no sistema.

3.  [**Criar Tabela `sys_acl_levels_members` (`create_sys_acl_levels_members_table.elixir.md`)**](./create_sys_acl_levels_members_table.elixir.md):
    *   Cria a tabela para associar usuários a níveis de ACL.

4.  [**Criar Tabela `sys_acl_matrix` (`create_sys_acl_matrix_table.elixir.md`)**](./create_sys_acl_matrix_table.elixir.md):
    *   Cria a tabela principal que define as permissões (nível x ação).

5.  [**Criar Tabela `sys_acl_actions_track` (`create_sys_acl_actions_track_table.elixir.md`)**](./create_sys_acl_actions_track_table.elixir.md):
    *   Cria a tabela para rastrear o uso de ações contáveis.

## Ordem de Execução:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeiras, se definidas na criação:
1.  `sys_acl_levels`
2.  `sys_acl_actions`
3.  `sys_acl_levels_members` (depende de `sys_accounts` e `sys_acl_levels`)
4.  `sys_acl_matrix` (depende de `sys_acl_levels` e `sys_acl_actions`)
5.  `sys_acl_actions_track` (depende de `sys_acl_actions` e `sys_accounts`)

A tabela `sys_accounts` (de `01_system_core/sys_accounts_and_profiles/`) deve existir antes de `sys_acl_levels_members` e `sys_acl_actions_track`.