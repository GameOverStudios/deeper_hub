# Documentação Deeper: Migrações para o Sistema de Votos/Avaliações

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas à tabela de configuração `sys_objects_vote` e exemplos de tabelas de sumário (`TableMain`) e rastreamento (`TableTrack`) usadas pelo sistema de votos/avaliações genérico do UNA.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de sistemas de interação.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_vote` (`create_sys_objects_vote_table.elixir.md`)**](./create_sys_objects_vote_table.elixir.md):
    *   Cria a tabela de configuração que define cada \"objeto de voto\" para diferentes tipos de conteúdo.

2.  [**(Exemplo) Criar Tabela de Sumário de Votos (`create_example_votes_summary_table.elixir.md`)**](./create_example_votes_summary_table.elixir.md):
    *   Demonstra como uma tabela de sumário (referenciada por `sys_objects_vote.TableMain`, ex: `bx_persons_votes`) seria criada.

3.  [**(Exemplo) Criar Tabela de Rastreamento de Votos (`create_example_votes_track_table.elixir.md`)**](./create_example_votes_track_table.elixir.md):
    *   Demonstra como uma tabela de rastreamento de votos individuais (referenciada por `sys_objects_vote.TableTrack`, ex: `bx_persons_votes_track`) seria criada.

## Nomes de Tabela Dinâmicos:

É importante notar que os nomes das tabelas de sumário (`TableMain`) e rastreamento (`TableTrack`) são dinâmicos, definidos em `sys_objects_vote`. As migrações de exemplo fornecidas usam nomes genéricos. Na implementação real do \"Deeper\", pode ser necessário:

*   Criar migrações específicas para cada conjunto conhecido de tabelas `TableMain`/`TableTrack` (ex: uma migração para `bx_persons_votes` e `bx_persons_votes_track`).
*   Ou, ter um mecanismo mais dinâmico se o sistema precisar se adaptar a novas configurações de `sys_objects_vote` sem reimplementação.

## Ordem de Criação e Dependências:

1.  `sys_objects_vote` (tabela de configuração).
2.  As tabelas `TableMain` e `TableTrack` correspondentes. Estas dependem conceitualmente de `sys_profiles` (para `author_id` na `TableTrack`) e da tabela do conteúdo principal que está sendo votado (para `object_id`).