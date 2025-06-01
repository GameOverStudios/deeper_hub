# Documentação Deeper: Esquema do Banco de Dados para Sistema de Reações (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite para um sistema genérico de reações no \"Deeper\".

## Tabela: `deeper_reaction_types` (Tipos de Reação Disponíveis - Opcional)

Esta tabela é útil se os tipos de reação forem configuráveis ou numerosos. Se forem fixos (ex: os 6 padrão do Facebook), podem ser hardcoded na lógica da aplicação.

```sql
CREATE TABLE IF NOT EXISTS deeper_reaction_types (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  reaction_key TEXT NOT NULL UNIQUE, -- Ex: 'like', 'love', 'haha', 'wow', 'sad', 'angry'
  title_lkey TEXT NOT NULL, -- Chave de tradução para o nome da reação
  icon_class TEXT, -- Classe CSS ou identificador do ícone para UI
  color_hex TEXT, -- Cor associada (opcional)
  is_positive INTEGER DEFAULT 1, -- 1 se geralmente positiva, 0 se neutra, -1 se negativa (para sumarização)
  \"order\" INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1
);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_reactions_track (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL, -- Identificador do sistema de reações (ex: 'deeper_articles_react')
  object_id INTEGER NOT NULL, -- ID da entidade que recebeu a reação
  reactor_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id de quem reagiu
  reaction_type_key TEXT NOT NULL, -- Chave da reação (ex: 'like', 'love'). FK para deeper_reaction_types.reaction_key se a tabela existir.
  reacted_at INTEGER NOT NULL, -- Unix Timestamp
  ip_address TEXT, -- Opcional
  UNIQUE (system_name, object_id, reactor_profile_id), -- Garante uma reação por usuário por objeto
  FOREIGN KEY (reactor_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- FOREIGN KEY (reaction_type_key) REFERENCES deeper_reaction_types(reaction_key) ON UPDATE CASCADE -- Se deeper_reaction_types existir
);

CREATE INDEX IF NOT EXISTS idx_dreactt_system_object_type ON deeper_reactions_track(system_name, object_id, reaction_type_key);
CREATE INDEX IF NOT EXISTS idx_dreactt_reactor ON deeper_reactions_track(reactor_profile_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_object_reactions_summary (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  system_name TEXT NOT NULL,
  object_id INTEGER NOT NULL,
  reaction_type_key TEXT NOT NULL, -- Chave da reação
  reaction_count INTEGER NOT NULL DEFAULT 0,
  UNIQUE (system_name, object_id, reaction_type_key)
  -- FOREIGN KEY (reaction_type_key) REFERENCES deeper_reaction_types(reaction_key) ...
);

CREATE INDEX IF NOT EXISTS idx_dors_system_object ON deeper_object_reactions_summary(system_name, object_id);
```

```sql
  -- ... outras colunas ...
  -- Opção 1: Colunas separadas
  reactions_like_count INTEGER NOT NULL DEFAULT 0,
  reactions_love_count INTEGER NOT NULL DEFAULT 0,
  reactions_haha_count INTEGER NOT NULL DEFAULT 0,
  -- ... etc.
  -- Opção 2: Campo JSON (mais flexível para adicionar novos tipos de reação)
  reactions_summary TEXT, -- JSON: {\"like\": 10, \"love\": 5, \"total_reactions\": 15}
  total_reactions_count INTEGER NOT NULL DEFAULT 0, -- Contagem total de todas as reações
  -- ...
```

## Tabela: `deeper_reactions_track` (Rastreamento de Reações Individuais)

*   A constraint `UNIQUE (system_name, object_id, reactor_profile_id)` garante que um usuário só pode ter uma reação por objeto. Se o usuário muda a reação, a entrada antiga é atualizada ou removida e uma nova é inserida.

## Tabela: `deeper_object_reactions_summary` (Agregados de Reações por Objeto - Opcional)

Alternativamente à atualização de múltiplas colunas na tabela da entidade principal, uma tabela de resumo pode ser usada.

*   Esta tabela armazenaria a contagem para cada tipo de reação para cada objeto.
*   Seria atualizada sempre que uma reação fosse adicionada, alterada ou removida.

**Atualização de Agregados nas Tabelas de Entidade (Alternativa):**
Se não usar `deeper_object_reactions_summary`, a tabela da entidade principal (ex: `deeper_articles_entries`) precisaria de colunas para cada tipo de reação principal ou um campo JSON:

A atualização desses contadores seria feita na lógica da aplicação Elixir (`ReactionsRepo`) ou com triggers.