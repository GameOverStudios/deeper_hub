# Documentação Deeper: Migrações para o Sistema de Scores Genérico

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas à tabela de configuração `sys_objects_score` e exemplos de tabelas de sumário (`table_main`) e rastreamento (`table_track`) usadas pelo sistema de scores (upvote/downvote) genérico do UNA.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de sistemas de interação.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_score` (`create_sys_objects_score_table.elixir.md`)**](./create_sys_objects_score_table.elixir.md):
    *   Cria a tabela de configuração que define cada \"objeto de score\" para diferentes tipos de conteúdo.

2.  [**(Exemplo) Criar Tabela de Sumário de Scores (`create_example_scores_summary_table.elixir.md`)**](./create_example_scores_summary_table.elixir.md):
    *   Demonstra como uma tabela de sumário (referenciada por `sys_objects_score.table_main`, ex: `bx_persons_scores`) seria criada.

3.  [**(Exemplo) Criar Tabela de Rastreamento de Scores (`create_example_scores_track_table.elixir.md`)**](./create_example_scores_track_table.elixir.md):
    *   Demonstra como uma tabela de rastreamento de scores individuais (referenciada por `sys_objects_score.table_track`, ex: `bx_persons_scores_track`) seria criada.

## Nomes de Tabela Dinâmicos:

Os nomes das tabelas de sumário (`table_main`) e rastreamento (`table_track`) são dinâmicos, definidos em `sys_objects_score`. As migrações de exemplo fornecidas usam nomes genéricos. Na implementação real do \"Deeper\", pode ser necessário:
*   Criar migrações específicas para cada conjunto conhecido de tabelas `table_main`/`table_track` (ex: uma migração para `bx_persons_scores` e `bx_persons_scores_track`).
*   Ou, ter um mecanismo mais dinâmico se o sistema precisar se adaptar a novas configurações de `sys_objects_score`.

## Ordem de Criação e Dependências:

1.  `sys_objects_score` (tabela de configuração).
2.  As tabelas `table_main` e `table_track` correspondentes. Estas dependem conceitualmente de `sys_profiles` (para `author_id` na `table_track`) e da tabela do conteúdo principal que está sendo pontuado (para `object_id`).