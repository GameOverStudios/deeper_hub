# Documentação Deeper: Migrações para o Sistema de Reações Genérico

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas a um sistema de reações genérico. Isso inclui uma tabela de configuração hipotética `sys_objects_reaction` e exemplos de tabelas de sumário e rastreamento.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de sistemas de interação.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_reaction` (Hipotética) (`create_sys_objects_reaction_table.elixir.md`)**](./create_sys_objects_reaction_table.elixir.md):
    *   Cria a tabela de configuração que define cada \"objeto de reação\" para diferentes tipos de conteúdo, incluindo as reações disponíveis.

2.  [**(Exemplo) Criar Tabela de Sumário de Reações (`create_example_reactions_summary_table.elixir.md`)**](./create_example_reactions_summary_table.elixir.md):
    *   Demonstra como uma tabela de sumário (referenciada por `sys_objects_reaction.table_summary`) seria criada para contar cada tipo de reação por item.

3.  [**(Exemplo) Criar Tabela de Rastreamento de Reações (`create_example_reactions_track_table.elixir.md`)**](./create_example_reactions_track_table.elixir.md):
    *   Demonstra como uma tabela de rastreamento de reações individuais (referenciada por `sys_objects_reaction.table_track`) seria criada.

## Nomes de Tabela Dinâmicos e Adaptação:

*   Os nomes das tabelas de sumário (`table_summary`) e rastreamento (`table_track`) são dinâmicos, definidos em `sys_objects_reaction`.
*   Se o sistema UNA original utilizar `sys_cmts_reactions` e `sys_cmts_reactions_track` para reações em conteúdo principal (onde `object_id` nessas tabelas se refere ao ID do conteúdo principal), as migrações e o Repo precisariam ser adaptados para usar essas tabelas existentes em vez dos exemplos genéricos. A tabela `sys_objects_cmts` já teria uma coluna `ObjectReaction` que apontaria para um nome de objeto, mas o mecanismo de armazenamento pode ser diferente.

## Ordem de Criação e Dependências:

1.  `sys_objects_reaction` (tabela de configuração).
2.  As tabelas `table_summary` e `table_track` correspondentes. Estas dependem conceitualmente de `sys_profiles` (para `author_id` na `table_track`) e da tabela do conteúdo principal que está recebendo as reações (para `object_id`).