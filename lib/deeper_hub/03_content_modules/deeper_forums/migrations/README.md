# Documentação Deeper: Migrações para Módulo de Fóruns

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Fóruns (`deeper_forums`) no sistema \"Deeper\".

## Migrações Definidas:

1.  [**Criar Tabela `deeper_forum_categories` (`create_deeper_forum_categories_table.elixir.md`)**](./create_deeper_forum_categories_table.elixir.md):
    *   Cria a tabela para categorias de fóruns (opcional, se os fóruns forem agrupados).

2.  [**Criar Tabela `deeper_forums` (`create_deeper_forums_table.elixir.md`)**](./create_deeper_forums_table.elixir.md):
    *   Cria a tabela principal `deeper_forums` para os fóruns de discussão.

3.  [**Criar Tabela `deeper_forum_topics` (`create_deeper_forum_topics_table.elixir.md`)**](./create_deeper_forum_topics_table.elixir.md):
    *   Cria a tabela `deeper_forum_topics` para os tópicos dentro dos fóruns.

4.  [**Criar Tabela `deeper_forum_posts` (`create_deeper_forum_posts_table.elixir.md`)**](./create_deeper_forum_posts_table.elixir.md):
    *   Cria a tabela `deeper_forum_posts` para as mensagens/respostas dentro dos tópicos.

5.  [**Criar Tabela `deeper_forum_read_topics` (`create_deeper_forum_read_topics_table.elixir.md`)**](./create_deeper_forum_read_topics_table.elixir.md):
    *   Cria a tabela para rastrear quais tópicos foram lidos por cada usuário.

6.  [**Criar Tabela `deeper_forum_subscriptions` (`create_deeper_forum_subscriptions_table.elixir.md`)**](./create_deeper_forum_subscriptions_table.elixir.md):
    *   Cria a tabela para permitir que usuários sigam fóruns ou tópicos para notificações.

A ordem de execução destas migrações deve respeitar as dependências de chaves estrangeiras (ex: `deeper_forums` antes de `deeper_forum_topics`, que por sua vez é antes de `deeper_forum_posts`).