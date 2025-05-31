# Documentação Deeper: Migrações para Sistema de Favoritos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Favoritos Genérico.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_favorite` (`create_sys_objects_favorite_table.elixir.md`)**](./create_sys_objects_favorite_table.elixir.md):
    *   Responsável por criar a tabela `sys_objects_favorite`. Esta tabela é essencial, pois define as configurações para cada \"instância\" de sistema de favoritos usada por diferentes módulos ou tipos de conteúdo (ex: favoritar perfis, favoritar posts). A API \"Deeper\" usará esta tabela para saber qual tabela de rastreamento (`table_track`) consultar e como atualizar contadores.

2.  **Migrações para Tabelas de Rastreamento de Favoritos Específicas (Exemplo: `bx_persons_favorites_track`):**
    *   Estas migrações criam as tabelas que efetivamente armazenam os registros de quem favoritou qual item, para um tipo de conteúdo específico, conforme configurado em `sys_objects_favorite`.
    *   [**Criar Tabela `bx_persons_favorites_track` (`create_bx_persons_favorites_track_table.elixir.md`)**](./create_bx_persons_favorites_track_table.elixir.md)
    *   Outros módulos (ex: `bx_posts`) teriam suas próprias tabelas de rastreamento (ex: `bx_posts_favorites_track`) com migrações correspondentes.

## Ordem e Dependências:

*   `sys_objects_favorite` deve existir para que o `FavoritesRepo` possa funcionar dinamicamente.
*   As tabelas de rastreamento específicas (ex: `bx_persons_favorites_track`) devem existir.
*   Tabelas referenciadas em `TriggerTable` (ex: `bx_persons_data`) devem existir antes que a lógica de atualização de gatilho seja implementada.