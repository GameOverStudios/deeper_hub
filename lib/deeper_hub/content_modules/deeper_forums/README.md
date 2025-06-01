# Documentação Deeper: Módulo de Fóruns (`deeper_forums`)

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de fóruns de discussão, permitindo a criação de categorias de fóruns, tópicos dentro desses fóruns, e posts (respostas) dentro dos tópicos. Visa replicar funcionalidades de módulos como `bx_forum` do sistema UNA.

## Responsabilidades Principais:

*   Criação e gerenciamento de categorias de fóruns (ou \"fóruns\" em si, que podem ser agrupados).
*   Criação, leitura, atualização e exclusão (CRUD) de tópicos de discussão dentro dos fóruns.
*   Criação, leitura, atualização e exclusão (CRUD) de posts/respostas dentro dos tópicos.
*   Suporte para funcionalidades como:
    *   Fixar (sticky) tópicos.
    *   Trancar (lock) tópicos.
    *   Contagem de visualizações de tópicos.
    *   Contagem de respostas em tópicos.
    *   Informações do último post em um tópico/fórum.
*   Moderação de tópicos e posts.
*   Integração com perfis de usuário (autores de tópicos/posts).
*   Integração com sistemas de votos/reações (para posts/tópicos), e potencialmente favoritos (para tópicos).

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite para as tabelas `deeper_forum_categories` (se os fóruns forem categorizados), `deeper_forums` (os fóruns em si), `deeper_forum_topics`, e `deeper_forum_posts`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas do módulo de fóruns.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Content.ForumsRepo`) que encapsulam as queries SQL.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a fóruns, tópicos e posts.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como funcionalidades que seriam \"serviços\" no UNA (ex: \"últimos tópicos ativos\", \"lista de fóruns\") são implementadas na API.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como este módulo se integra com perfis de usuário, e potencialmente com sistemas de comentários (se os posts tiverem um sistema de comentários separado em vez de serem aninhados), votos, favoritos, e gerenciamento de arquivos (para anexos em posts).

## Estrutura de Dados Chave (a ser detalhada em `database_schema.md`):

*   **`deeper_forums`**:
    *   `id`, `category_id` (opcional, se houver categorias de fóruns), `title`, `slug`, `description`, `order_index`, `topics_count`, `posts_count`, `last_post_id` (FK para `deeper_forum_posts`), `last_post_profile_id`, `last_post_at`.
*   **`deeper_forum_topics`**:
    *   `id`, `forum_id` (FK), `profile_id` (autor), `title`, `slug`, `first_post_id` (FK para `deeper_forum_posts`), `views_count`, `replies_count`, `is_sticky` (fixo), `is_locked` (trancado), `last_reply_id` (FK para `deeper_forum_posts`), `last_reply_profile_id`, `last_reply_at`, `created_at`, `updated_at`.
*   **`deeper_forum_posts`**:
    *   `id`, `topic_id` (FK), `profile_id` (autor), `parent_post_id` (para posts aninhados/citações, opcional), `body` (conteúdo do post), `created_at`, `updated_at`, `edited_at`, `edited_by_profile_id`.

Este módulo fornecerá a espinha dorsal para discussões comunitárias na plataforma \"Deeper\".