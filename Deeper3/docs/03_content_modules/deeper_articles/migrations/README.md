# Documentação Deeper: Migrações para Módulo de Artigos/Posts

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Artigos/Posts (`deeper_articles`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_articles` (`create_deeper_articles_table.elixir.md`)**](./create_deeper_articles_table.elixir.md):
    *   Cria a tabela principal `deeper_articles` para armazenar o conteúdo dos posts.

2.  [**Criar Tabela `deeper_article_categories` (`create_deeper_article_categories_table.elixir.md`)**](./create_deeper_article_categories_table.elixir.md):
    *   Cria a tabela `deeper_article_categories` para definir as categorias dos artigos.

3.  [**Criar Tabela de Junção `deeper_articles_to_categories` (`create_deeper_articles_to_categories_table.elixir.md`)**](./create_deeper_articles_to_categories_table.elixir.md):
    *   Cria a tabela de junção para associar artigos a múltiplas categorias.

A ordem de execução destas migrações deve ser tal que tabelas referenciadas por chaves estrangeiras (`deeper_articles`, `deeper_article_categories`) existam antes da tabela de junção.