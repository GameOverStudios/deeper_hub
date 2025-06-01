# Documentação Deeper: Migrações para o Sistema de Reações

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Reações (`deeper_reactions_track`, etc.) no \"Deeper\".

## Migrações Definidas:

1.  **(Opcional)** [**Criar Tabela `deeper_reaction_types` (`create_deeper_reaction_types_table.elixir.md`)**](./create_deeper_reaction_types_table.elixir.md):
    *   Cria a tabela para definir os tipos de reação disponíveis.

2.  [**Criar Tabela `deeper_reactions_track` (`create_deeper_reactions_track_table.elixir.md`)**](./create_deeper_reactions_track_table.elixir.md):
    *   Cria a tabela para armazenar cada reação individual.

3.  **(Opcional)** [**Criar Tabela `deeper_object_reactions_summary` (`create_deeper_object_reactions_summary_table.elixir.md`)**](./create_deeper_object_reactions_summary_table.elixir.md):
    *   Cria a tabela para armazenar contagens agregadas de reações por objeto e tipo.

## Ordem de Execução:

1.  (Opcional) `deeper_reaction_types`
2.  `deeper_reactions_track` (depende de `sys_profiles` e opcionalmente de `deeper_reaction_types`)
3.  (Opcional) `deeper_object_reactions_summary` (depende de `deeper_reaction_types` se usada)

É crucial que a tabela `sys_profiles` (de `01_system_core`) exista antes de criar `deeper_reactions_track`.