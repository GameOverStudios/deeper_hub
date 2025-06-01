# Documentação Deeper: Migrações para Módulo de Eventos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Eventos (`deeper_events`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Ordem das Migrações:

É importante considerar a ordem devido às dependências de chave estrangeira:

1.  `deeper_events_categories` (Se usada, deve ser criada antes de `deeper_events_entries`).
2.  `deeper_events_entries` (Pode depender de `deeper_events_categories` e `sys_profiles`).
3.  `deeper_events_participants` (Depende de `deeper_events_entries` e `sys_profiles`).

As tabelas `sys_profiles` (do módulo `sys_accounts_and_profiles`) devem existir antes da criação de `deeper_events_entries` e `deeper_events_participants` para que as FKs possam ser estabelecidas corretamente.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_events_categories` (`create_deeper_events_categories_table.elixir.md`)**](./create_deeper_events_categories_table.elixir.md):
    *   Cria a tabela para armazenar categorias de eventos.

2.  [**Criar Tabela `deeper_events_entries` (`create_deeper_events_entries_table.elixir.md`)**](./create_deeper_events_entries_table.elixir.md):
    *   Cria a tabela principal para armazenar os detalhes dos eventos.

3.  [**Criar Tabela `deeper_events_participants` (`create_deeper_events_participants_table.elixir.md`)**](./create_deeper_events_participants_table.elixir.md):
    *   Cria a tabela para registrar a participação (RSVP) nos eventos.