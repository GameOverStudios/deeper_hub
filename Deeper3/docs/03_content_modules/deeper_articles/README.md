# Documentação Deeper: Módulo de Artigos/Posts (`deeper_articles`)

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de artigos ou posts criados por usuários. Ele permitirá a criação, leitura, atualização e exclusão (CRUD) de artigos, juntamente com funcionalidades associadas como categorias, imagens de destaque e integração com sistemas de interação.

Este módulo é um exemplo de como um módulo de conteúdo típico do UNA seria portado para a API \"Deeper\". Ele pode se basear em funcionalidades de módulos como `bx_posts` ou um sistema de blog/artigos genérico.

## Responsabilidades Principais:

*   Permitir que usuários criem, visualizem, editem e excluam artigos.
*   Armazenar o título, corpo do artigo, autor, data de publicação, status (publicado, rascunho).
*   Suporte para uma imagem de destaque.
*   Suporte para categorização de artigos.
*   Integração com sistemas de comentários, votos, favoritos.
*   Controle de visibilidade/privacidade (ACL).

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite para a tabela principal `deeper_articles` e tabelas de suporte como `deeper_article_categories` e `deeper_articles_to_categories`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do módulo de artigos.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve o módulo Elixir (ex: `Deeper.Content.ArticlesRepo`) que encapsula as queries SQL para interagir com as tabelas de artigos.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a artigos.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como funcionalidades que seriam \"serviços\" no UNA (ex: \"obter últimos artigos para a página inicial\", \"obter artigos por categoria\") serão implementadas como queries ou lógicas na API.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como este módulo se integra com sistemas de comentários (`sys_comments_system`), votos (`sys_voting_system`), favoritos (`sys_favorites_system`), e o sistema de gerenciamento de arquivos (`06_file_management`) para imagens de destaque.

## Estrutura da Tabela Principal (`deeper_articles` - a ser detalhada em `database_schema.md`):

*   `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
*   `profile_id` (INTEGER, FK para `sys_profiles.id` - autor do artigo)
*   `title` (TEXT NOT NULL)
*   `slug` (TEXT NOT NULL UNIQUE - para URLs amigáveis)
*   `body` (TEXT NOT NULL - conteúdo do artigo, pode ser HTML ou Markdown)
*   `excerpt` (TEXT - um resumo curto)
*   `featured_image_file_id` (INTEGER, FK para `deeper_files.id` - opcional)
*   `status` (TEXT NOT NULL DEFAULT 'draft' CHECK(status IN ('draft', 'published', 'archived')))
*   `visibility` (TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'private', 'unlisted'))) -- ou integrado com ACL
*   `allow_comments` (INTEGER NOT NULL DEFAULT 1)
*   `published_at` (INTEGER - Unix Timestamp, se o status for 'published')
*   `created_at` (INTEGER NOT NULL - Unix Timestamp)
*   `updated_at` (INTEGER NOT NULL - Unix Timestamp)
*   Contadores (views, votes, comments - podem ser atualizados por triggers ou pela aplicação via `sys_objects_vote`, `sys_objects_cmts`, etc.)