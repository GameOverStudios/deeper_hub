# Documentação Deeper: Sistema de Favoritos Genérico

Esta seção detalha a API RESTful \"Deeper\" para interagir com o sistema de favoritos genérico do UNA. Este sistema permite que usuários marquem diferentes tipos de conteúdo (perfis, posts, etc.) como seus favoritos.

## Tabelas Relevantes do UNA:

*   **`sys_objects_favorite`**: Tabela de configuração principal. Cada entrada define um \"objeto de favorito\" para um tipo de conteúdo. Especifica:
    *   `name`: Nome único do objeto de favorito (ex: `bx_persons_favorite`, `bx_posts_favorite`). Usado na API.
    *   `table_track`: Nome da tabela SQL que armazena cada ato de favoritar. Ex: `bx_persons_favorites_track`.
    *   `table_lists`: (Menos comum para APIs REST, mais para UI do UNA) Nome da tabela que poderia armazenar listas de favoritos criadas por usuários. A API \"Deeper\" focará inicialmente no `table_track`.
    *   `is_undo`: Se o usuário pode desfavoritar.
    *   `is_public`: Se a lista de quem favoritou um item é pública.
    *   `trigger_table`, `trigger_field_id`, `trigger_field_count`: Configurações para atualizar o contador de favoritos na tabela de conteúdo principal.
*   **Tabela de Rastreamento de Favoritos (especificada em `sys_objects_favorite.table_track`)**:
    *   Geralmente contém colunas como `object_id` (ID do item favoritado), `author_id` (quem favoritou), `date`.

## Responsabilidades da API \"Deeper\":

*   Permitir que usuários favoritem e desfavoritem itens de conteúdo.
*   Verificar se um usuário já favoritou um item específico.
*   Listar itens favoritados por um usuário.
*   Listar usuários que favoritaram um item específico (se `is_public`).

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite da tabela `sys_objects_favorite` e um exemplo de tabela `table_track`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.FavoritesRepo` e suas funções para ler e registrar favoritos, usando dinamicamente o nome da tabela de rastreamento configurada.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful (ex: `POST /favorites/{object_fav_name}/item/{item_id}/toggle`).

## Fluxo Típico:

1.  O cliente exibe um item de conteúdo (ex: perfil com `id=456`).
2.  O cliente sabe que o objeto de favorito para perfis é, por exemplo, `bx_persons_favorites`.
3.  Para exibir o estado do botão \"favoritar\" para o usuário logado, o cliente chama `GET /api/v1/favorites/object/bx_persons_favorites/item/456/status`.
4.  A API \"Deeper\" usa o `FavoritesRepo` para verificar na tabela de track se o usuário logado favoritou o item.
5.  Para favoritar/desfavoritar, o cliente envia `POST /api/v1/favorites/object/bx_persons_favorites/item/456/toggle`. O `FavoritesRepo` adiciona/remove a entrada na tabela de track e atualiza o contador na `TriggerTable` (ex: `bx_persons_data.favorites`).