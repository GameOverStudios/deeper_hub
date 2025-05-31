# Documentação Deeper: Migrações para Sistema de Votos/Avaliações

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Votos/Avaliações Genérico.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_vote` (`create_sys_objects_vote_table.elixir.md`)**](./create_sys_objects_vote_table.elixir.md):
    *   Responsável por criar a tabela `sys_objects_vote`. Esta tabela é essencial, pois define as configurações para cada \"instância\" de sistema de votação usada por diferentes módulos ou tipos de conteúdo (ex: avaliações de perfis, estrelas em posts). A API \"Deeper\" usará esta tabela para saber quais tabelas de agregação (`TableMain`) e rastreamento (`TableTrack`) consultar e como atualizar contadores e médias.

2.  **Migrações para Tabelas de Votos Específicas (Exemplo: `bx_persons_votes` e `bx_persons_votes_track`):**
    *   Estas migrações criam as tabelas que efetivamente armazenam os dados de votação para um tipo de conteúdo específico, conforme configurado em `sys_objects_vote`.
    *   [**Criar Tabela `bx_persons_votes` (Agregação) (`create_bx_persons_votes_table.elixir.md`)**](./create_bx_persons_votes_table.elixir.md)
    *   [**Criar Tabela `bx_persons_votes_track` (Rastreamento) (`create_bx_persons_votes_track_table.elixir.md`)**](./create_bx_persons_votes_track_table.elixir.md)
    *   Outros módulos (ex: `bx_posts`) teriam suas próprias tabelas de votos (ex: `bx_posts_votes`, `bx_posts_votes_track`) com migrações correspondentes, seguindo o mesmo padrão.

## Ordem e Dependências:

*   `sys_objects_vote` deve existir para que o `VotingRepo` possa funcionar dinamicamente.
*   As tabelas de votos específicas (ex: `bx_persons_votes`, `bx_persons_votes_track`) devem existir para armazenar os dados de votação. Elas podem ser criadas independentemente de `sys_objects_vote`, mas só serão \"utilizáveis\" pelo sistema genérico após a configuração correspondente em `sys_objects_vote`.
*   Tabelas referenciadas em `TriggerTable` (ex: `bx_persons_data`) devem existir antes que a lógica de atualização de gatilho seja implementada ou executada.