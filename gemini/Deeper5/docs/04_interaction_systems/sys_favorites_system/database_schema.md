# Documentação Deeper: Esquema do Banco de Dados para Sistema de Favoritos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema genérico de favoritos no \"Deeper\".

## Tabela: `deeper_favorites_track` (Rastreamento de Favoritos Individuais)

```sql
CREATE TABLE IF NOT EXISTS deeper_favorites_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL, -- Identificador do sistema de favoritos (ex: 'deeper_articles_fav')
  object_id INTEGER NOT NULL, -- ID da entidade sendo favoritada
  fan_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id de quem favoritou
  favorited_at INTEGER NOT NULL, -- Unix Timestamp
  UNIQUE (system_name, object_id, fan_profile_id), -- Garante que um usuário favorite um objeto apenas uma vez por sistema
  FOREIGN KEY (fan_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_dfavt_system_object ON deeper_favorites_track(system_name, object_id);
CREATE INDEX IF NOT EXISTS idx_dfavt_fan_profile ON deeper_favorites_track(fan_profile_id, system_name); -- Para listar favoritos de um usuário
```

```sql
  -- ... outras colunas ...
  favorites_count INTEGER NOT NULL DEFAULT 0,
  -- ...
```

*   **`system_name`, `object_id`, `fan_profile_id`**: Juntos, formam uma chave única.
*   **`fan_profile_id`**: O perfil do usuário que marcou o item como favorito.

## Atualização de Contadores nas Tabelas de Entidade:

Quando um item é favoritado ou desfavoritado em `deeper_favorites_track`, um campo de contador na tabela da entidade principal (ex: `deeper_articles_entries.favorites_count` ou `bx_persons_data.favorites`) deve ser atualizado (incrementado/decrementado).

**Exemplo para `deeper_articles_entries`:**
A tabela `deeper_articles_entries` precisaria ter uma coluna como:

A atualização pode ser feita:
1.  **Na lógica da aplicação Elixir (dentro do `FavoritesRepo`):** Após cada operação, recalcular ou incrementar/decrementar o contador na tabela da entidade.
2.  **Com Triggers no SQLite.**