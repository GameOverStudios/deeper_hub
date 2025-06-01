# Documentação Deeper: Esquema do Banco de Dados para Eventos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas principais do módulo de Eventos (`deeper_events`).

## Tabela: `deeper_events_categories` (Categorias de Eventos)

Opcional, mas útil para organizar eventos.

```sql
CREATE TABLE IF NOT EXISTS deeper_events_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  parent_id INTEGER DEFAULT 0, -- Para subcategorias
  name TEXT NOT NULL UNIQUE, -- Nome da categoria (ex: \"Música\", \"Tecnologia\", \"Esportes\")
  title_lang_key TEXT, -- Chave de linguagem para o título, se traduzível
  \"order\" INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_deeper_events_categories_parent_id ON deeper_events_categories(parent_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_events_entries (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  author_profile_id INTEGER NOT NULL, -- ID do perfil (sys_profiles.id) do criador do evento
  category_id INTEGER, -- FK para deeper_events_categories.id
  title TEXT NOT NULL,
  description TEXT,
  cover_image_file_id INTEGER, -- FK para uma futura tabela de arquivos (deeper_files.id)
  event_url TEXT, -- Link para uma página externa do evento, se houver
  
  -- Datas e Horários (armazenar como Unix Timestamps ou ISO8601 TEXT em UTC)
  start_datetime INTEGER NOT NULL, -- Timestamp UTC do início
  end_datetime INTEGER NOT NULL,   -- Timestamp UTC do fim
  timezone TEXT, -- Fuso horário original do evento (ex: \"America/Sao_Paulo\"), informativo

  -- Localização
  location_type TEXT DEFAULT 'physical' CHECK(location_type IN ('physical', 'online', 'tbd')),
  location_venue_name TEXT, -- Nome do local (ex: \"Centro de Convenções XPTO\")
  location_address TEXT,    -- Endereço completo
  location_city TEXT,
  location_state TEXT,
  location_country TEXT,
  location_zip TEXT,
  location_lat REAL,        -- Latitude
  location_lng REAL,        -- Longitude
  location_online_url TEXT, -- URL para eventos online

  -- Configurações de Participação
  max_participants INTEGER DEFAULT 0, -- 0 para ilimitado
  allow_rsvp INTEGER DEFAULT 1, -- 0 para não permitir RSVP, 1 para permitir
  rsvp_deadline INTEGER, -- Timestamp UTC do prazo para RSVP (opcional)

  -- Contadores (podem ser atualizados por triggers ou pela aplicação)
  participants_count INTEGER DEFAULT 0,
  interested_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  favorites_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  score_up_count INTEGER DEFAULT 0,
  score_down_count INTEGER DEFAULT 0,

  -- Status e Visibilidade
  status TEXT DEFAULT 'active' CHECK(status IN ('active', 'pending_approval', 'cancelled', 'draft', 'past')),
  visibility_group_id TEXT DEFAULT '3', -- ID do grupo de privacidade (similar ao allow_view_to do UNA)
  featured INTEGER DEFAULT 0, -- 0 ou 1

  created_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL, -- Unix Timestamp

  FOREIGN KEY (author_profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES deeper_events_categories(id) ON DELETE SET NULL
  -- FOREIGN KEY (cover_image_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL -- Quando deeper_files for definida
);

CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_author ON deeper_events_entries(author_profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_category ON deeper_events_entries(category_id);
CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_start_datetime ON deeper_events_entries(start_datetime);
CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_status ON deeper_events_entries(status);
-- Um índice geoespacial em (location_lat, location_lng) seria útil com extensões como R*Tree do SQLite.
-- CREATE INDEX IF NOT EXISTS idx_deeper_events_entries_location_city_state ON deeper_events_entries(location_city, location_state); -- Para buscas por localização
```

```sql
CREATE TABLE IF NOT EXISTS deeper_events_participants (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL, -- FK para deeper_events_entries.id
  profile_id INTEGER NOT NULL, -- FK para sys_profiles.id (quem está participando)
  rsvp_status TEXT NOT NULL CHECK(rsvp_status IN ('attending', 'interested', 'not_attending')),
  -- payment_status TEXT CHECK(payment_status IN ('pending', 'paid', 'free')), -- Se o evento for pago
  -- ticket_type TEXT, -- Tipo de ingresso, se aplicável
  added_at INTEGER NOT NULL, -- Unix Timestamp de quando o RSVP foi feito/alterado

  UNIQUE (event_id, profile_id), -- Um perfil só pode ter um status de RSVP por evento
  FOREIGN KEY (event_id) REFERENCES deeper_events_entries(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_deeper_events_participants_event_id_status ON deeper_events_participants(event_id, rsvp_status);
CREATE INDEX IF NOT EXISTS idx_deeper_events_participants_profile_id_event_id ON deeper_events_participants(profile_id, event_id);
```

*   **`id`**: Chave primária.
*   **`parent_id`**: Para categorias aninhadas.
*   **`name`**: Identificador único da categoria.
*   **`title_lang_key`**: Chave para buscar o título traduzido no sistema de localização.
*   **`order`**: Ordem de exibição das categorias.

## Tabela: `deeper_events_entries` (Entradas de Eventos)

Tabela principal para armazenar os detalhes dos eventos.

*   **`id`**: Chave primária.
*   **`author_profile_id`**: Criador do evento.
*   **`category_id`**: Categoria do evento.
*   **`title`, `description`, `cover_image_file_id`, `event_url`**: Detalhes básicos do evento.
*   **`start_datetime`, `end_datetime`, `timezone`**: Informações cruciais de data/hora. Recomenda-se armazenar `start_datetime` e `end_datetime` como timestamps Unix UTC para facilitar comparações e ordenação. O `timezone` é para exibição.
*   **`location_*`**: Campos detalhados para localização física ou online.
*   **`max_participants`, `allow_rsvp`, `rsvp_deadline`**: Configurações de participação.
*   **Contadores**: Para métricas de interação.
*   **`status`**: Status do evento (ativo, cancelado, rascunho, etc.).
*   **`visibility_group_id`**: Controle de privacidade.
*   **`created_at`, `updated_at`**: Timestamps de auditoria.

## Tabela: `deeper_events_participants` (Participantes de Eventos)

Registra quem está participando ou interessado em um evento.

*   **`id`**: Chave primária.
*   **`event_id`**: O evento ao qual o RSVP se refere.
*   **`profile_id`**: O perfil que está fazendo o RSVP.
*   **`rsvp_status`**: Status da participação ('attending', 'interested', 'not_attending').
*   **`added_at`**: Timestamp do RSVP.
*   A constraint `UNIQUE (event_id, profile_id)` garante que um usuário não possa ter múltiplos status de RSVP para o mesmo evento.

## Outras Tabelas Potenciais (Escopo Futuro):

*   **`deeper_events_tags`**: Para tags de eventos.
*   **`deeper_events_custom_fields`**: Se eventos precisarem de campos customizáveis.
*   **Tabelas para eventos recorrentes**: Modelagem mais complexa (ex: iCalendar RRULEs).

**Próximo Passo:** Definir os módulos de migração Elixir para criar estas tabelas.