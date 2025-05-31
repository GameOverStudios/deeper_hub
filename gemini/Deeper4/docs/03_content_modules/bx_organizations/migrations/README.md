# Documentação Deeper: Migrações para Organizações (`bx_organizations`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo Organizações (`bx_organizations`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que residirá em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `bx_organizations_data` (`create_bx_organizations_data_table.elixir.md`)**](./create_bx_organizations_data_table.elixir.md):
    *   Responsável por criar a tabela principal `bx_organizations_data` para armazenar os dados específicos dos perfis de organização.

2.  [**Criar Tabela `bx_organizations_categories` (Opcional) (`create_bx_organizations_categories_table.elixir.md`)**](./create_bx_organizations_categories_table.elixir.md):
    *   Responsável por criar a tabela `bx_organizations_categories` se a funcionalidade de categorização de organizações for implementada.

3.  [**Criar Tabela `bx_organizations_members` (Opcional) (`create_bx_organizations_members_table.elixir.md`)**](./create_bx_organizations_members_table.elixir.md):
    *   Responsável por criar a tabela `bx_organizations_members` para gerenciar múltiplos administradores ou membros com papéis dentro de uma organização.

## Ordem de Execução (Considerando Dependências):

1.  `create_sys_profiles_table.ex` (Do módulo `01_system_core` - `bx_organizations_data` depende dela para `author_id`).
2.  `create_deeper_files_table.ex` (Do módulo `06_file_management` - `bx_organizations_data` pode depender dela para `org_logo`, `org_cover`. Se não existir, as FKs podem ser omitidas inicialmente ou a tabela criada sem elas).
3.  (Opcional) `create_bx_organizations_categories_table.ex`
4.  `create_bx_organizations_data_table.ex`
5.  (Opcional) `create_bx_organizations_members_table.ex` (depende de `bx_organizations_data` e `sys_profiles`).

A gestão da ordem de execução das migrações globais do projeto será tratada por um runner de migrações.