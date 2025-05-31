# Documentação Deeper: Migrações para o Sistema de Comentários

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Comentários (`deeper_comments*`) no \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/interaction_systems/comments/` (sugestão de subpasta).

## Migrações Definidas:

1.  [**Criar Tabela `deeper_comments` (`create_deeper_comments_table.elixir.md`)**](./create_deeper_comments_table.elixir.md):
    *   Cria a tabela principal para armazenar todos os comentários.

2.  [**Criar Tabela `deeper_comment_votes_track` (`create_deeper_comment_votes_track_table.elixir.md`)**](./create_deeper_comment_votes_track_table.elixir.md):
    *   Cria a tabela para rastrear votos, reações ou denúncias em comentários individuais.

## Ordem de Execução:

1.  `deeper_comments` (depende de `sys_profiles`)
2.  `deeper_comment_votes_track` (depende de `deeper_comments` e `sys_profiles`)

É crucial que a tabela `sys_profiles` (de `01_system_core`) exista antes de criar estas tabelas.