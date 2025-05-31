# Documentação Deeper: Migrações para Marketplace (`bx_market`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo Marketplace (`bx_market`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que residirá em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `bx_market_categories` (`create_bx_market_categories_table.elixir.md`)**](./create_bx_market_categories_table.elixir.md):
    *   Responsável por criar a tabela `bx_market_categories` para armazenar as categorias dos produtos/listagens.

2.  [**Criar Tabela `bx_market_entries` (`create_bx_market_entries_table.elixir.md`)**](./create_bx_market_entries_table.elixir.md):
    *   Responsável por criar a tabela principal `bx_market_entries` para armazenar as listagens de produtos ou serviços.

3.  [**Criar Tabela `bx_market_photos` (`create_bx_market_photos_table.elixir.md`)**](./create_bx_market_photos_table.elixir.md):
    *   Responsável por criar a tabela `bx_market_photos` para associar imagens às listagens do marketplace.

## Ordem de Execução:

As migrações devem ser executadas na seguinte ordem para respeitar as dependências de chaves estrangeiras (se definidas na criação da tabela, ou para lógica de aplicação):

1.  `create_bx_market_categories_table.ex`
2.  `create_sys_profiles_table.ex` (Já deve existir de `01_system_core` - `bx_market_entries` depende dela para `author_id`)
3.  `create_deeper_files_table.ex` (Do módulo `06_file_management` - `bx_market_photos` depende dela para `file_id`. Se não existir ainda, a FK em `bx_market_photos` pode ser adicionada depois ou a tabela criada sem a FK inicialmente).
4.  `create_bx_market_entries_table.ex`
5.  `create_bx_market_photos_table.ex`

A gestão da ordem de execução das migrações globais do projeto será tratada por um runner de migrações.