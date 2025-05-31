# Documentação Deeper: Esquema do Banco de Dados para Módulo de Eventos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao módulo de Eventos (`deeper_events`).

## Tabela Principal: `deeper_events`

```sql
CREATE TABLE IF NOT EXISTS deeper_events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- Organizador/criador do evento
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE,
  description TEXT NOT NULL,
  start_datetime INTEGER NOT NULL, -- Unix Timestamp, UTC
  end_datetime INTEGER NOT NULL,   -- Unix Timestamp, UTC
  timezone TEXT, -- Ex: \"America/New_York\", \"Europe/London\". Opcional, mas recomendado.
  location_text TEXT, -- Descrição textual da localização (ex: \"Online\", \"Sala de Conferências X\")
  location_lat REAL,
  location_lng REAL,
  address TEXT,
  city TEXT,
  state TEXT, -- Adicionado
  country TEXT,
  zip_code TEXT, -- Adicionado
  banner_file_id INTEGER, -- FK para deeper_files.id
  visibility TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'private', 'unlisted')),
  allow_rsvps INTEGER NOT NULL DEFAULT 1, -- 0 = não, 1 = sim
  max_attendees INTEGER DEFAULT 0, -- 0 para ilimitado
  status TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'cancelled', 'past', 'draft')), -- 'past' pode ser setado por um job
  -- Contadores de RSVP (podem ser atualizados pela aplicação ou triggers)
  rsvps_yes_count INTEGER NOT NULL DEFAULT 0,
  rsvps_maybe_count INTEGER NOT NULL DEFAULT 0,
  rsvps_no_count INTEGER NOT NULL DEFAULT 0,
  views INTEGER NOT NULL DEFAULT 0,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE, -- Se o perfil do organizador for deletado, o evento também é
  FOREIGN KEY (banner_file_id) REFERENCES deeper_files(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_events_profile_id ON deeper_events(profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_events_slug ON deeper_events(slug);
CREATE INDEX IF NOT EXISTS idx_deeper_events_start_datetime ON deeper_events(start_datetime);
CREATE INDEX IF NOT EXISTS idx_deeper_events_status ON deeper_events(status);
CREATE INDEX IF NOT EXISTS idx_deeper_events_visibility ON deeper_events(visibility);
-- Índice geoespacial pode ser considerado se buscas por proximidade forem importantes (SQLite com extensões)
-- CREATE INDEX IF NOT EXISTS idx_deeper_events_location ON deeper_events(location_lat, location_lng);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_event_rsvps (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  event_id INTEGER NOT NULL,
  profile_id INTEGER NOT NULL, -- Perfil do participante
  rsvp_status TEXT NOT NULL CHECK(rsvp_status IN ('yes', 'no', 'maybe')),
  comment TEXT, -- Comentário opcional do participante ao RSVP
  guests_count INTEGER NOT NULL DEFAULT 0, -- Número de convidados adicionais que este participante está trazendo (se permitido pelo evento)
  rsvped_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL, -- Unix Timestamp
  UNIQUE (event_id, profile_id), -- Um perfil só pode ter um status de RSVP por evento
  FOREIGN KEY (event_id) REFERENCES deeper_events(id) ON DELETE CASCADE,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_deeper_event_rsvps_event_id_status ON deeper_event_rsvps(event_id, rsvp_status);
CREATE INDEX IF NOT EXISTS idx_deeper_event_rsvps_profile_id ON deeper_event_rsvps(profile_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_event_categories (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL UNIQUE,
  slug TEXT NOT NULL UNIQUE,
  description TEXT,
  parent_id INTEGER,
  FOREIGN KEY (parent_id) REFERENCES deeper_event_categories(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_deeper_event_categories_slug ON deeper_event_categories(slug);
CREATE INDEX IF NOT EXISTS idx_deeper_event_categories_parent_id ON deeper_event_categories(parent_id);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_events_to_categories (
  event_id INTEGER NOT NULL,
  category_id INTEGER NOT NULL,
  PRIMARY KEY (event_id, category_id),
  FOREIGN KEY (event_id) REFERENCES deeper_events(id) ON DELETE CASCADE,
  FOREIGN KEY (category_id) REFERENCES deeper_event_categories(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_detc_category_id_event_id ON deeper_events_to_categories(category_id, event_id);
```

*   **`start_datetime`, `end_datetime`**: Armazenados como Unix timestamps (inteiros) em UTC.
*   **`timezone`**: Importante para que o cliente possa exibir as datas/horas na hora local correta do evento.
*   **`location_*`**: Campos para informações de localização, incluindo coordenadas para mapas.
*   **`visibility`**: Controle de privacidade do evento.
*   **`allow_rsvps`, `max_attendees`**: Gerenciamento de participação.
*   **`status`**: Status do evento. O status `past` pode ser atualizado por uma tarefa agendada.
*   **`rsvps_*_count`**: Contadores desnormalizados para RSVPs. Alternativamente, poderiam ser calculados dinamicamente da tabela `deeper_event_rsvps`. Manter contadores pode melhorar a performance de listagem se muitos eventos forem exibidos com essas contagens.

## Tabela: `deeper_event_rsvps` (Para registrar participação)

*   Registra a resposta de cada perfil para um evento.
*   `UNIQUE (event_id, profile_id)` garante que um usuário só tenha um RSVP por evento. Uma atualização no RSVP seria um `UPDATE` nesta tabela.

## Tabela: `deeper_event_categories` (Para definir categorias de eventos)

*   Similar à tabela de categorias de artigos, mas específica para eventos.

## Tabela de Junção: `deeper_events_to_categories`

*   Liga eventos a uma ou mais categorias.

Este conjunto de tabelas forma a base para o módulo de eventos.