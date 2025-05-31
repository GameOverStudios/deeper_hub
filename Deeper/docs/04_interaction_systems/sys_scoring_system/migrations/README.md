# Documentação Deeper: Migrações para Sistema de Pontuações (Scores)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Pontuações (Scores) Genérico.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_score` (`create_sys_objects_score_table.elixir.md`)**](./create_sys_objects_score_table.elixir.md):
    *   Responsável por criar a tabela `sys_objects_score`. Esta tabela define as configurações para cada \"instância\" de sistema de pontuação usada por diferentes tipos de conteúdo (ex: pontuação de perfis, pontuação de comentários).

2.  **Migrações para Tabelas de Pontuações Específicas (Exemplo: `bx_persons_scores` e `bx_persons_scores_track`):**
    *   Estas migrações criam as tabelas que armazenam os dados de pontuação para um tipo de conteúdo específico, conforme configurado em `sys_objects_score`.
    *   [**Criar Tabela `bx_persons_scores` (Agregação) (`create_bx_persons_scores_table.elixir.md`)**](./create_bx_persons_scores_table.elixir.md)
    *   [**Criar Tabela `bx_persons_scores_track` (Rastreamento) (`create_bx_persons_scores_track_table.elixir.md`)**](./create_bx_persons_scores_track_table.elixir.md)
    *   Outros módulos teriam suas próprias tabelas de scores com migrações correspondentes.

## Ordem e Dependências:

*   `sys_objects_score` deve existir para que o `ScoringRepo` funcione dinamicamente.
*   As tabelas de scores específicas devem existir.
*   Tabelas referenciadas em `TriggerTable` (ex: `bx_persons_data`) devem existir.