# Documentação Deeper: Migrações para Módulo de Grupos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Grupos (`deeper_groups`) no sistema \"Deeper\".

## Migrações Definidas:

1.  [**Criar Tabela `deeper_groups` (`create_deeper_groups_table.elixir.md`)**](./create_deeper_groups_table.elixir.md):
    *   Cria a tabela principal `deeper_groups` para armazenar os detalhes dos grupos.

2.  [**Criar Tabela `deeper_group_members` (`create_deeper_group_members_table.elixir.md`)**](./create_deeper_group_members_table.elixir.md):
    *   Cria a tabela `deeper_group_members` para gerenciar a associação de perfis aos grupos e seus papéis.

3.  [**Criar Tabela `deeper_group_content_posts` (`create_deeper_group_content_posts_table.elixir.md`)**](./create_deeper_group_content_posts_table.elixir.md):
    *   Cria uma tabela exemplo para posts de conteúdo dentro dos grupos.

## Migrações Opcionais / Implementação Futura:

*   **Criar Tabela `deeper_group_invites` (`create_deeper_group_invites_table.elixir.md`)**: Para um sistema de convites pendentes.
*   **Criar Tabela `deeper_group_join_requests` (`create_deeper_group_join_requests_table.elixir.md`)**: Para solicitações de entrada em grupos privados.

A ordem de execução destas migrações deve garantir que as tabelas referenciadas por chaves estrangeiras existam antes das tabelas que as referenciam (ex: `deeper_groups` antes de `deeper_group_members`).