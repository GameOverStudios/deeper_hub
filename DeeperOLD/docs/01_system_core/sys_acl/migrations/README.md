# Documentação Deeper: Migrações para Sistema de Controle de Acesso (ACL)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Controle de Acesso (ACL) do UNA (`sys_acl_*`).

## Migrações Definidas:

1.  [**Criar Tabela `sys_acl_levels` (`create_sys_acl_levels_table.elixir.md`)**](./create_sys_acl_levels_table.elixir.md):
    *   Define os diferentes níveis de membresia no sistema.

2.  [**Criar Tabela `sys_acl_actions` (`create_sys_acl_actions_table.elixir.md`)**](./create_sys_acl_actions_table.elixir.md):
    *   Define as ações específicas que podem ser controladas por permissões.

3.  [**Criar Tabela `sys_acl_levels_members` (`create_sys_acl_levels_members_table.elixir.md`)**](./create_sys_acl_levels_members_table.elixir.md):
    *   Associa membros (perfis) a níveis de ACL, com datas de validade.

4.  [**Criar Tabela `sys_acl_matrix` (`create_sys_acl_matrix_table.elixir.md`)**](./create_sys_acl_matrix_table.elixir.md):
    *   A tabela principal que define quais níveis têm permissão para quais ações, e com quais restrições.

5.  [**Criar Tabela `sys_acl_actions_track` (`create_sys_acl_actions_track_table.elixir.md`)**](./create_sys_acl_actions_track_table.elixir.md):
    *   Rastreia o uso de ações ACL que são contáveis.

## Ordem e Dependências:

*   `sys_acl_levels` e `sys_acl_actions` podem ser criadas independentemente.
*   `sys_acl_levels_members` depende de `sys_acl_levels` (e `sys_profiles`, que já foi definida).
*   `sys_acl_matrix` depende de `sys_acl_levels` e `sys_acl_actions`.
*   `sys_acl_actions_track` depende de `sys_acl_actions` (e `sys_profiles`).

O sistema de execução de migrações deve tentar respeitar essa ordem, especialmente se chaves estrangeiras explícitas forem definidas nas migrações SQLite.