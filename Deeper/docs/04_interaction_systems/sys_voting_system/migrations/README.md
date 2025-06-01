# Documentação Deeper: Migrações para o Sistema de Votos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Votos/Avaliações (`deeper_votes_track`) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/interaction_systems/voting/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_votes_track` (`create_deeper_votes_track_table.elixir.md`)**](./create_deeper_votes_track_table.elixir.md):
    *   Cria a tabela para armazenar cada voto individual.

## Considerações Adicionais de Migração:

*   As tabelas de entidade principal (ex: `deeper_articles_entries`, `bx_persons_data`) precisarão ser alteradas (ou criadas com) colunas para armazenar os agregados de votos (`votes_count`, `votes_sum`, `rate`). Essas alterações de tabela seriam parte das migrações dos respectivos módulos de conteúdo ou perfis, não necessariamente aqui. Este sistema de votação apenas define sua tabela de *track*.