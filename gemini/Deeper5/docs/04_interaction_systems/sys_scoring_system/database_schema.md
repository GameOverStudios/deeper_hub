# Documentação Deeper: Esquema do Banco de Dados para Sistema de Pontuações (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema genérico de pontuações (upvote/downvote) no \"Deeper\".

## Tabela: `deeper_scores_track` (Rastreamento de Votos Individuais de Score)

```sql
CREATE TABLE IF NOT EXISTS deeper_scores_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL, -- Identificador do sistema de pontuação (ex: 'deeper_articles_score')
  object_id INTEGER NOT NULL, -- ID da entidade sendo pontuada
  voter_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id do votante
  type TEXT NOT NULL CHECK(type IN ('up', 'down')), -- Tipo de voto: 'up' ou 'down'
  voted_at INTEGER NOT NULL, -- Unix Timestamp
  ip_address TEXT, -- Opcional
  UNIQUE (system_name, object_id, voter_profile_id), -- Garante um voto (up OU down) por usuário por objeto
  FOREIGN KEY (voter_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dsct_system_object ON deeper_scores_track(system_name, object_id);
CREATE INDEX IF NOT EXISTS idx_dsct_voter ON deeper_scores_track(voter_profile_id);
```

```sql
  -- ... outras colunas ...
  score_up_count INTEGER NOT NULL DEFAULT 0,
  score_down_count INTEGER NOT NULL DEFAULT 0,
  score_net INTEGER NOT NULL DEFAULT 0, -- Calculado como up - down
  -- ...
```

*   **`system_name`, `object_id`, `voter_profile_id`**: Juntos, formam uma chave única. Um usuário não pode dar um upvote E um downvote no mesmo objeto; seu voto é de um tipo ou de outro, ou nenhum.
*   **`type`**: Armazena se o voto foi 'up' ou 'down'.

## Atualização de Agregados nas Tabelas de Entidade:

Quando um voto é registrado, alterado ou removido em `deeper_scores_track`, os campos agregados na tabela da entidade principal (ex: `deeper_articles_entries` ou `deeper_comments`) devem ser atualizados. Esses campos são tipicamente:

*   `score_up_count` (ou `sc_up` no UNA): O número total de upvotes.
*   `score_down_count` (ou `sc_down` no UNA): O número total de downvotes.
*   `score_net` (ou `score` no UNA): O score líquido (`score_up_count - score_down_count`).

**Exemplo para `deeper_articles_entries`:**
A tabela `deeper_articles_entries` precisaria ter colunas como:

A atualização pode ser feita na lógica da aplicação Elixir (no `ScoringRepo`) ou com triggers.