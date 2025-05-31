# Documentação Deeper: Migrações para Tabelas de Controle de Acesso (ACL)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas de Controle de Acesso (ACL) do sistema UNA, que serão usadas pelo backend \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_acl_levels` (`create_sys_acl_levels_table.elixir.md`)**](./create_sys_acl_levels_table.elixir.md):
    *   Cria a tabela para definir os diferentes níveis de membresia.

2.  [**Criar Tabela `sys_acl_actions` (`create_sys_acl_actions_table.elixir.md`)**](./create_sys_acl_actions_table.elixir.md):
    *   Cria a tabela para definir as ações controláveis no sistema.

3.  [**Criar Tabela `sys_acl_levels_members` (`create_sys_acl_levels_members_table.elixir.md`)**](./create_sys_acl_levels_members_table.elixir.md):
    *   Cria a tabela para associar membros (contas) a níveis de ACL.

4.  [**Criar Tabela `sys_acl_matrix` (`create_sys_acl_matrix_table.elixir.md`)**](./create_sys_acl_matrix_table.elixir.md):
    *   Cria a tabela de permissões que liga níveis a ações, com contadores e validades.

5.  [**Criar Tabela `sys_acl_actions_track` (`create_sys_acl_actions_track_table.elixir.md`)**](./create_sys_acl_actions_track_table.elixir.md):
    *   Cria a tabela para rastrear o uso de ações contáveis por membros.

## Ordem de Criação e Dependências:

*   `sys_acl_levels` e `sys_acl_actions` podem ser criadas independentemente.
*   `sys_acl_levels_members` depende de `sys_acl_levels` (e `sys_accounts` para `IDMember`).
*   `sys_acl_matrix` depende de `sys_acl_levels` e `sys_acl_actions`.
*   `sys_acl_actions_track` depende de `sys_acl_actions` (e `sys_accounts` para `IDMember`).

As chaves estrangeiras serão definidas nas migrações para refletir essas dependências, garantindo a integridade referencial no SQLite (com `PRAGMA foreign_keys = ON;`).