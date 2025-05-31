# Documentação Deeper: Migrações para o Sistema de Favoritos Genérico

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas à tabela de configuração `sys_objects_favorite` e um exemplo de tabela de rastreamento (`table_track`) usada pelo sistema de favoritos genérico do UNA.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de sistemas de interação.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_favorite` (`create_sys_objects_favorite_table.elixir.md`)**](./create_sys_objects_favorite_table.elixir.md):
    *   Cria a tabela de configuração que define cada \"objeto de favorito\" para diferentes tipos de conteúdo.

2.  [**(Exemplo) Criar Tabela de Rastreamento de Favoritos (`create_example_favorites_track_table.elixir.md`)**](./create_example_favorites_track_table.elixir.md):
    *   Demonstra como uma tabela de rastreamento de favoritos (referenciada por `sys_objects_favorite.table_track`, ex: `bx_persons_favorites_track`) seria criada.

## Nomes de Tabela Dinâmicos:

O nome da tabela de rastreamento (`table_track`) é dinâmico, definido em `sys_objects_favorite`. A migração de exemplo fornecida usa um nome genérico. Na implementação real do \"Deeper\", pode ser necessário:
*   Criar migrações específicas para cada tabela `table_track` conhecida (ex: uma migração para `bx_persons_favorites_track`).
*   Ou, ter um mecanismo mais dinâmico se o sistema precisar se adaptar a novas configurações de `sys_objects_favorite`.

## Ordem de Criação e Dependências:

1.  `sys_objects_favorite` (tabela de configuração).
2.  A tabela `table_track` correspondente. Esta depende conceitualmente de `sys_profiles` (para `author_id`) e da tabela do conteúdo principal que está sendo favoritado (para `object_id`).