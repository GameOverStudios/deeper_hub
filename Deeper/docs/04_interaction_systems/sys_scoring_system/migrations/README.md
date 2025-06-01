# Documentação Deeper: Migrações para o Sistema de Pontuações

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Pontuações (`deeper_scores_track`) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/interaction_systems/scoring/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_scores_track` (`create_deeper_scores_track_table.elixir.md`)**](./create_deeper_scores_track_table.elixir.md):
    *   Cria a tabela para armazenar cada voto individual de pontuação (up/down).

## Considerações Adicionais de Migração:

*   As tabelas de entidade principal (ex: `deeper_articles_entries`, `deeper_comments`) precisarão ser alteradas para incluir colunas como `score_up_count`, `score_down_count`, e `score_net` se ainda não existirem. Essas alterações seriam parte das migrações dos respectivos módulos de conteúdo ou do sistema de comentários.