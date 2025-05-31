# Documentação Deeper: Migrações para Módulo de Eventos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Eventos (`deeper_events`) no sistema \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_events` (`create_deeper_events_table.elixir.md`)**](./create_deeper_events_table.elixir.md):
    *   Cria a tabela principal `deeper_events` para armazenar os detalhes dos eventos.

2.  [**Criar Tabela `deeper_event_rsvps` (`create_deeper_event_rsvps_table.elixir.md`)**](./create_deeper_event_rsvps_table.elixir.md):
    *   Cria a tabela `deeper_event_rsvps` para registrar a participação dos usuários nos eventos.

3.  [**Criar Tabela `deeper_event_categories` (`create_deeper_event_categories_table.elixir.md`)**](./create_deeper_event_categories_table.elixir.md):
    *   Cria a tabela `deeper_event_categories` para definir as categorias dos eventos.

4.  [**Criar Tabela de Junção `deeper_events_to_categories` (`create_deeper_events_to_categories_table.elixir.md`)**](./create_deeper_events_to_categories_table.elixir.md):
    *   Cria a tabela de junção para associar eventos a múltiplas categorias.

A ordem de execução destas migrações deve garantir que as tabelas referenciadas por chaves estrangeiras existam antes das tabelas que as referenciam.