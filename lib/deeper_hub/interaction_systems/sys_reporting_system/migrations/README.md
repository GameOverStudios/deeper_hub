# Documentação Deeper: Migrações para o Sistema de Denúncias Genérico

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas à tabela de configuração `sys_objects_report` e exemplos de tabelas de sumário (`table_main`) e rastreamento (`table_track`) usadas pelo sistema de denúncias genérico do UNA.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de sistemas de interação.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_report` (`create_sys_objects_report_table.elixir.md`)**](./create_sys_objects_report_table.elixir.md):
    *   Cria a tabela de configuração que define cada \"objeto de denúncia\" para diferentes tipos de conteúdo.

2.  [**(Exemplo) Criar Tabela de Sumário de Denúncias (`create_example_reports_summary_table.elixir.md`)**](./create_example_reports_summary_table.elixir.md):
    *   Demonstra como uma tabela de sumário (referenciada por `sys_objects_report.table_main`, ex: `bx_persons_reports`) seria criada.

3.  [**(Exemplo) Criar Tabela de Rastreamento de Denúncias (`create_example_reports_track_table.elixir.md`)**](./create_example_reports_track_table.elixir.md):
    *   Demonstra como uma tabela de rastreamento de denúncias individuais (referenciada por `sys_objects_report.table_track`, ex: `bx_persons_reports_track`) seria criada.

## Nomes de Tabela Dinâmicos:

Os nomes das tabelas de sumário (`table_main`) e rastreamento (`table_track`) são dinâmicos, definidos em `sys_objects_report`. As migrações de exemplo fornecidas usam nomes genéricos. Na implementação real do \"Deeper\", pode ser necessário:
*   Criar migrações específicas para cada conjunto conhecido de tabelas `table_main`/`table_track` (ex: uma migração para `bx_persons_reports` e `bx_persons_reports_track`).
*   Ou, ter um mecanismo mais dinâmico se o sistema precisar se adaptar a novas configurações de `sys_objects_report`.

## Ordem de Criação e Dependências:

1.  `sys_objects_report` (tabela de configuração).
2.  As tabelas `table_main` e `table_track` correspondentes. Estas dependem conceitualmente de `sys_profiles` (para `author_id` e `checked_by` na `table_track`) e da tabela do conteúdo principal que está sendo denunciado (para `object_id`).