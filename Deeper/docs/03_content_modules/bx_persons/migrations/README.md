# Documentação Deeper: Migrações para Módulo Pessoas (`bx_persons`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo \"Pessoas\" (`bx_persons`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Ordem das Migrações:

A ordem de criação das tabelas pode ser importante devido a chaves estrangeiras, embora para SQLite, se as FKs forem definidas e a tabela referenciada ainda não existir, a criação falhará a menos que as FKs sejam adicionadas depois com `ALTER TABLE` (que tem limitações no SQLite) ou a verificação de FKs esteja desabilitada durante a migração. É mais seguro criar tabelas referenciadas primeiro.

1.  **`bx_persons_data`**: Esta tabela é central. Sua migração já foi coberta em `docs/01_system_core/sys_accounts_and_profiles/migrations/create_bx_persons_data_table.elixir.md` devido à sua ligação com `sys_profiles`. Vamos referenciá-la aqui para completude.
2.  **`bx_persons_pictures`**: Para avatares e fotos originais.
3.  **`bx_persons_pictures_resized`**: Para versões redimensionadas das fotos.
4.  **`bx_persons_views_track`**: Para rastrear visualizações de perfis.
5.  **`bx_persons_cmts`**: Para comentários em perfis.
6.  *(Outras tabelas de interação como `bx_persons_favorites_track`, `bx_persons_meta_keywords`, etc., serão adicionadas conforme necessário).*

## Migrações Definidas:

*   [**Criar Tabela `bx_persons_data` (Referência)**](./create_bx_persons_data_table.elixir.md):
    *   *Esta migração já foi definida em `docs/01_system_core/sys_accounts_and_profiles/migrations/create_bx_persons_data_table.elixir.md`. Este arquivo aqui pode ser um stub ou um link para essa definição.*

*   [**Criar Tabela `bx_persons_pictures` (`create_bx_persons_pictures_table.elixir.md`)**](./create_bx_persons_pictures_table.elixir.md):
    *   Cria a tabela para armazenar informações sobre as imagens originais dos perfis.

*   [**Criar Tabela `bx_persons_pictures_resized` (`create_bx_persons_pictures_resized_table.elixir.md`)**](./create_bx_persons_pictures_resized_table.elixir.md):
    *   Cria a tabela para armazenar informações sobre as versões redimensionadas das imagens.

*   [**Criar Tabela `bx_persons_views_track` (`create_bx_persons_views_track_table.elixir.md`)**](./create_bx_persons_views_track_table.elixir.md):
    *   Cria a tabela para rastrear visualizações de perfis.

*   [**Criar Tabela `bx_persons_cmts` (`create_bx_persons_cmts_table.elixir.md`)**](./create_bx_persons_cmts_table.elixir.md):
    *   Cria a tabela para comentários em perfis de pessoas.

*(As migrações para as demais tabelas de `bx_persons` (meta, scores, votes, reports, skills, favorites) serão adicionadas posteriormente, seguindo o mesmo padrão).*