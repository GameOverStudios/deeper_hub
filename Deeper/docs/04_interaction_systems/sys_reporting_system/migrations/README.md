# Documentação Deeper: Migrações para o Sistema de Denúncias

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Denúncias (`deeper_reports_track` e opcionalmente `deeper_report_types`) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/interaction_systems/reporting/`.

## Migrações Definidas:

1.  **(Opcional)** [**Criar Tabela `deeper_report_types` (`create_deeper_report_types_table.elixir.md`)**](./create_deeper_report_types_table.elixir.md):
    *   Cria a tabela para armazenar os tipos de denúncia predefinidos.

2.  [**Criar Tabela `deeper_reports_track` (`create_deeper_reports_track_table.elixir.md`)**](./create_deeper_reports_track_table.elixir.md):
    *   Cria a tabela para armazenar cada denúncia individual.

## Ordem de Execução:

1.  (Opcional) `deeper_report_types`
2.  `deeper_reports_track` (depende de `sys_profiles` e opcionalmente de `deeper_report_types`)

É crucial que a tabela `sys_profiles` (de `01_system_core`) exista antes de criar `deeper_reports_track`.