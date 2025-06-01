# Documentação Deeper: Migrações para Conexões de Perfil (`sys_connections`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Conexões de Perfil (`sys_connections`) no backend \"Deeper\".

Estas migrações criarão as tabelas necessárias para gerenciar amizades, assinaturas (seguir/fãs) e bloqueios entre perfis.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que residirá em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_conn_friends` (`create_deeper_conn_friends_table.elixir.md`)**](./create_deeper_conn_friends_table.elixir.md):
    *   Responsável por criar a tabela `deeper_conn_friends` para armazenar relacionamentos de amizade (e potencialmente solicitações de amizade).

2.  [**Criar Tabela `deeper_conn_subscriptions` (`create_deeper_conn_subscriptions_table.elixir.md`)**](./create_deeper_conn_subscriptions_table.elixir.md):
    *   Responsável por criar a tabela `deeper_conn_subscriptions` para armazenar conexões unidirecionais de seguir/fã.

3.  [**Criar Tabela `deeper_conn_bans` (`create_deeper_conn_bans_table.elixir.md`)**](./create_deeper_conn_bans_table.elixir.md):
    *   Responsável por criar a tabela `deeper_conn_bans` para armazenar bloqueios entre perfis.

## Ordem de Execução e Dependências:

*   Todas estas migrações dependem da existência da tabela `sys_profiles` (definida em `01_system_core/sys_accounts_and_profiles/migrations/`). O runner de migrações deve garantir que `create_sys_profiles_table.ex` seja executada antes destas.
*   Dentro deste conjunto, a ordem entre `create_deeper_conn_friends_table.ex`, `create_deeper_conn_subscriptions_table.ex`, e `create_deeper_conn_bans_table.ex` geralmente não é crítica, pois elas não dependem diretamente umas das outras, apenas de `sys_profiles`.

A gestão da ordem de execução das migrações globais do projeto será tratada por um runner de migrações.