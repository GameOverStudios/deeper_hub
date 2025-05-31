# Documentação Deeper: Módulo de Conteúdo - Artigos (`deeper_articles`)

Este documento detalha a API \"Deeper\" para o gerenciamento de \"Artigos\" (ou posts de blog, notícias, etc.). Ele cobre a criação, leitura, atualização e exclusão (CRUD) de artigos, bem como funcionalidades associadas como listagem, busca e interações.

Este módulo pode ser análogo a módulos como `bx_posts`, `bx_news`, ou um sistema de blog genérico no UNA.

## Responsabilidades Principais da API de Artigos:

*   Permitir a criação de novos artigos por usuários autorizados.
*   Listar artigos com paginação, filtros (por autor, categoria, tags, status) e ordenação.
*   Permitir a leitura de um artigo específico.
*   Permitir a atualização de artigos existentes por seus autores ou administradores.
*   Permitir a exclusão de artigos por seus autores ou administradores.
*   Integrar-se com sistemas de comentários, votos, favoritos, etc. (usando `04_interaction_systems`).

## Estrutura da Documentação para Artigos:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define as `CREATE TABLE` statements para SQLite das tabelas necessárias para os artigos (ex: `deeper_articles_entries`, `deeper_articles_categories`, `deeper_articles_tags`, `deeper_articles_tags2entries`).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas de artigos.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.Content.ArticlesRepo` que encapsula as queries SQL para interagir com as tabelas de artigos.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a artigos.

## Considerações de Design:

*   **Autoria:** Cada artigo terá um autor (`author_profile_id`, referenciando `sys_profiles.id`).
*   **Status:** Artigos podem ter status como \"publicado\", \"rascunho\", \"pendente de aprovação\". A API respeitará esses status ao listar e exibir artigos.
*   **Categorias e Tags:** Suporte para categorização e tagging de artigos.
*   **Campos Comuns:** Título, corpo do texto (possivelmente Markdown ou HTML rico), resumo, imagem de destaque, data de publicação.
*   **Contadores:** Visualizações, comentários, votos (estes seriam atualizados via os sistemas de interação).
*   **Privacidade:** Um campo `allow_view_to` (similar ao de `bx_persons_data`) pode controlar quem pode ver o artigo.
*   **SEO:** Campos para slug (URL amigável), meta título, meta descrição.

Este módulo servirá como um exemplo representativo para outros módulos de conteúdo.