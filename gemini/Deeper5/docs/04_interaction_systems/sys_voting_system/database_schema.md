# Documentação Deeper: Esquema do Banco de Dados para Sistema de Votos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema genérico de votos/avaliações no \"Deeper\".

## Tabela: `deeper_votes_track` (Rastreamento de Votos Individuais)

```sql
CREATE TABLE IF NOT EXISTS deeper_votes_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL, -- Identificador do sistema de votação (ex: 'deeper_articles_rating')
  object_id INTEGER NOT NULL, -- ID da entidade sendo votada
  voter_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id do votante
  value INTEGER NOT NULL, -- O valor do voto (ex: 1, 2, 3, 4, 5)
  voted_at INTEGER NOT NULL, -- Unix Timestamp
  ip_address TEXT, -- Opcional, para rastreamento/prevenção de abuso
  UNIQUE (system_name, object_id, voter_profile_id), -- Garante um voto por usuário por objeto por sistema
  FOREIGN KEY (voter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dvt_system_object ON deeper_votes_track(system_name, object_id);
CREATE INDEX IF NOT EXISTS idx_dvt_voter ON deeper_votes_track(voter_profile_id);
```

```sql
  -- ... outras colunas ...
  article_votes_count INTEGER NOT NULL DEFAULT 0,
  article_votes_sum INTEGER NOT NULL DEFAULT 0,
  article_rate REAL NOT NULL DEFAULT 0.0, -- Média calculada
  -- ...
```

*   **`system_name`, `object_id`, `voter_profile_id`**: Juntos, formam uma chave única para garantir que um usuário possa votar apenas uma vez em um objeto específico dentro de um sistema de votação.
*   **`value`**: O voto numérico dado pelo usuário. A validação (ex: 1-5) ocorrerá na camada de aplicação.

## Atualização de Agregados nas Tabelas de Entidade:

Quando um voto é registrado, alterado ou removido em `deeper_votes_track`, os campos agregados na tabela da entidade principal (ex: `deeper_articles_entries`) devem ser atualizados. Esses campos são tipicamente:

*   `votes_count` (ou `votes` no UNA): O número total de votos recebidos.
*   `votes_sum` (ou `sum` em `sys_votes` do UNA): A soma de todos os valores de votos.
*   `rate` (ou `rate` no UNA): A avaliação média (`votes_sum / votes_count`).

**Exemplo para `deeper_articles_entries`:**
A tabela `deeper_articles_entries` precisaria ter colunas como:

A atualização desses contadores pode ser feita:
1.  **Na lógica da aplicação Elixir (dentro do `VotingRepo`):** Após cada operação de voto, recalcular e atualizar os campos na tabela da entidade principal. Isso geralmente é feito dentro de uma transação.
2.  **Com Triggers no SQLite:** Definir triggers no banco de dados para automatizar essas atualizações.

A abordagem da lógica da aplicação é mais flexível para começar.