# Documentação Deeper: Esquema do BD para Sistema de Favoritos Genérico (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite da tabela de configuração `sys_objects_favorite` e um exemplo de tabela de rastreamento (`table_track`) usada pelo sistema de favoritos genérico do UNA.

## Tabela: `sys_objects_favorite` (Configuração)

```sql
CREATE TABLE IF NOT EXISTS sys_objects_favorite (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- No UNA é INT(11)
  name TEXT NOT NULL UNIQUE, -- Nome único do objeto de favorito, ex: 'bx_persons_favorites'
  table_track TEXT NOT NULL, -- Tabela de rastreamento, ex: 'bx_persons_favorites_track'
  table_lists TEXT, -- Tabela para listas de favoritos (uso menos comum para API inicial)
  pruning INTEGER NOT NULL DEFAULT 31536000, -- Em segundos (1 ano)
  is_on INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se este sistema está ativo)
  is_undo INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se pode desfavoritar)
  is_public INTEGER NOT NULL DEFAULT 1, -- 0 ou 1 (se a lista de quem favoritou é pública)
  base_url TEXT, -- URL base para links de favoritos
  trigger_table TEXT, -- Tabela de conteúdo principal a ser atualizada
  trigger_field_id TEXT, -- Nome da coluna ID na TriggerTable
  trigger_field_author TEXT,
  trigger_field_count TEXT, -- Nome da coluna de contagem de favoritos na TriggerTable
  class_name TEXT,
  class_file TEXT
  -- Não há coluna 'Module' explícita como em outros sys_objects_*, o módulo é inferido pelo contexto.
);
CREATE INDEX IF NOT EXISTS idx_sys_objects_favorite_name ON sys_objects_favorite(name);
```

```sql
-- EXEMPLO: Se sys_objects_favorite.table_track = 'bx_example_content_favorites_track'
CREATE TABLE IF NOT EXISTS bx_example_content_favorites_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- PK da tabela de track
  object_id INTEGER NOT NULL, -- ID do item de conteúdo que foi favoritado
  author_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem favoritou)
  date INTEGER NOT NULL, -- Unix Timestamp
  -- A FK para object_id dependeria do tipo de conteúdo específico.
  FOREIGN KEY (author_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
);
-- Garante que um autor não favorite o mesmo objeto múltiplas vezes
CREATE UNIQUE INDEX IF NOT EXISTS uidx_bx_example_fav_track_object_author ON bx_example_content_favorites_track(object_id, author_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_fav_track_object_id ON bx_example_content_favorites_track(object_id);
CREATE INDEX IF NOT EXISTS idx_bx_example_fav_track_author_id ON bx_example_content_favorites_track(author_id);
```

*   Define cada sistema de \"favoritos\" para diferentes partes do site.

## Exemplo de Tabela de Rastreamento de Favoritos (`table_track`)

O nome desta tabela é dinâmico, vindo de `sys_objects_favorite.table_track`. Ex: `bx_persons_favorites_track`.

*   Registra cada ato de favoritar.
*   O UNA original usa `PRIMARY KEY (id)` e `KEY id (object_id, author_id)`. Para garantir a unicidade de (object_id, author_id), um `UNIQUE INDEX` é mais apropriado.

### Nota sobre `table_lists`:
A tabela `table_lists` no UNA é usada para permitir que os usuários criem múltiplas listas de favoritos. Para uma API RESTful inicial, focar no sistema simples de favoritar/desfavoritar (usando `table_track`) é geralmente suficiente. O suporte a múltiplas listas de favoritos pode ser uma funcionalidade avançada.