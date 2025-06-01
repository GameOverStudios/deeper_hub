# Documentação Deeper: Sistema de Favoritos (`sys_favorites_system`)

Este documento detalha a API \"Deeper\" para um sistema genérico de \"Favoritos\", permitindo que usuários marquem diferentes tipos de conteúdo (artigos, perfis, fotos, etc.) como seus favoritos. Ele se baseia no conceito de `sys_objects_favorite` e tabelas associadas do UNA.

No UNA, este sistema também pode incluir \"listas de favoritos\", mas para a API \"Deeper\" inicial, focaremos na funcionalidade básica de favoritar/desfavoritar um item.

## Abordagem \"Deeper\" para Favoritos:

O UNA usa `sys_objects_favorite` para definir instâncias de sistemas de favoritos, especificando a tabela de \"track\" (`TableTrack`) e, opcionalmente, uma tabela para listas (`TableLists`).

Para \"Deeper\", podemos ter:

1.  **Tabela de Rastreamento Unificada (Proposta):** `deeper_favorites_track`
    *   Armazenaria cada marcação de favorito.
    *   Colunas: `id`, `system_name` (ex: \"deeper_articles_favorites\", \"bx_persons_profile_favorites\"), `object_id` (ID da entidade favoritada), `fan_profile_id` (quem favoritou), `favorited_at`.
2.  **Atualização de Contadores:**
    *   Um campo de contagem de favoritos (ex: `favorites_count` ou `favorites` no UNA) na tabela da entidade principal (ex: `deeper_articles_entries`, `bx_persons_data`) seria atualizado quando um item é favoritado ou desfavoritado.

## Responsabilidades Principais da API de Favoritos:

*   Permitir que um usuário marque um objeto como favorito.
*   Permitir que um usuário desmarque um objeto como favorito.
*   Verificar se um usuário específico favoritou um objeto.
*   Listar os objetos favoritados por um usuário.
*   Listar os usuários que favoritaram um objeto específico (menos comum para API pública, mais para info).
*   Retornar a contagem de favoritos para um objeto.

## Estrutura da Documentação para Favoritos:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define o `CREATE TABLE` para `deeper_favorites_track` e discute a atualização do contador na entidade principal.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Módulos de migração para criar as tabelas de favoritos.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.InteractionSystems.FavoritesRepo`.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful, geralmente aninhados sob o recurso principal (ex: `/articles/{id}/favorite`).

## Considerações de Design:

*   **`system_name`**: Identifica a qual \"instância\" de sistema de favoritos uma entrada pertence.
*   **`object_id`**: O ID da entidade sendo favoritada.
*   **ACL:** Quem pode favoritar (geralmente qualquer usuário logado).