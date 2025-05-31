# Documentação Deeper Studio API: Gerenciamento de Conteúdo - Posts (`bx_posts`)

Este documento descreve os endpoints da API de Administração (\"Studio API\") especificamente para o gerenciamento e moderação de \"Posts\" (artigos, notícias, entradas de blog) do módulo `bx_posts` (ou similar) na plataforma \"Deeper\".

**Objetivo Principal:** Fornecer aos administradores e moderadores as ferramentas para visualizar, criar (em nome de outros), editar, deletar, aprovar, destacar e gerenciar o status de qualquer post no sistema.

## Entidades Relevantes (Exemplos para um módulo `bx_posts`):

*   **`bx_posts_data` (ou `bx_posts_entries`):** Tabela principal com o conteúdo dos posts.
    *   Campos típicos: `id`, `author_id` (profile_id do criador), `title`, `text` (corpo do post), `status` (`active`, `pending`, `draft`, `hidden`), `category_id`, `tags` (pode ser um campo de texto ou uma tabela de junção), `allow_view_to`, `allow_comments`, `views`, `comments_count`, `featured_until_ts`, `added_ts`, `changed_ts`.
*   **`bx_posts_pictures` / `bx_posts_files`:** Tabelas para imagens ou anexos associados aos posts.
*   Tabelas de categorias e tags específicas para posts (ex: `bx_posts_categories`, `bx_posts_tags_to_entries`).
*   Tabelas de interação: `bx_posts_cmts`, `bx_posts_votes`, `bx_posts_favorites_track`, etc.

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Content.PostsRepo` (Hipotético): Responsável por todas as operações CRUD e de listagem para posts, incluindo JOINs com categorias, tags, autores.
*   `Deeper.SystemCore.ProfilesRepo` e `AccountsRepo`: Para obter informações sobre os autores.
*   `Deeper.Interactions.*Repo`: Para buscar/moderar comentários, votos, etc., associados aos posts.

## Funcionalidades da API de Admin para Posts:

*   Listar todos os posts com filtros administrativos (por status, autor, categoria, tags, etc.).
*   Visualizar todos os detalhes de um post específico.
*   Criar um novo post (útil para administradores publicarem conteúdo).
*   Editar qualquer aspecto de um post existente.
*   Mudar o status de um post (publicar, despublicar, marcar como rascunho, arquivar).
*   Deletar um post.
*   Gerenciar categorias e tags de posts.
*   Definir um post como \"destacado\" (`featured`).

## Relação com APIs Públicas:

Enquanto a API pública (`/api/v1/posts`) permite que usuários criem (seus próprios posts) e visualizem posts (respeitando permissões e status), a API de Admin (`/api/v1/admin/content/posts`) permite operações privilegiadas em *qualquer* post.