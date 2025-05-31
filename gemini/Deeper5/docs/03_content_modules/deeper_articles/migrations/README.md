# Documentação Deeper: Migrações para o Módulo de Artigos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Artigos (`deeper_articles_*`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/content/articles/` (sugestão de subpasta para organização).

## Migrações Definidas:

1.  [**Criar Tabela `deeper_articles_categories` (`create_deeper_articles_categories_table.elixir.md`)**](./create_deeper_articles_categories_table.elixir.md):
    *   Cria a tabela para armazenar categorias de artigos. (Deve ser criada antes de `deeper_articles_entries` se houver FK direta).

2.  [**Criar Tabela `deeper_articles_entries` (`create_deeper_articles_entries_table.elixir.md`)**](./create_deeper_articles_entries_table.elixir.md):
    *   Cria a tabela principal para armazenar os artigos.

3.  [**Criar Tabela `deeper_articles_tags` (`create_deeper_articles_tags_table.elixir.md`)**](./create_deeper_articles_tags_table.elixir.md):
    *   Cria a tabela para armazenar as tags.

4.  [**Criar Tabela `deeper_articles_tags_to_entries` (`create_deeper_articles_tags_to_entries_table.elixir.md`)**](./create_deeper_articles_tags_to_entries_table.elixir.md):
    *   Cria a tabela de junção para o relacionamento muitos-para-muitos entre artigos e tags.

## Ordem de Execução:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeiras:
1.  `deeper_articles_categories` (Se `deeper_articles_entries` tiver uma FK para ela na criação).
2.  `deeper_articles_tags`
3.  `deeper_articles_entries` (Depende de `sys_profiles` e opcionalmente de `deeper_articles_categories`).
4.  `deeper_articles_tags_to_entries` (Depende de `deeper_articles_tags` e `deeper_articles_entries`).

É crucial que a tabela `sys_profiles` (de `01_system_core`) exista antes de criar `deeper_articles_entries`.