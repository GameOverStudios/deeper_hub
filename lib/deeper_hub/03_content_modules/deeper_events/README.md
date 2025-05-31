# Documentação Deeper: Módulo de Eventos (`deeper_events`)

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de eventos, permitindo que usuários criem, descubram, participem (RSVP) e interajam com eventos. Ele visa replicar funcionalidades encontradas em módulos de eventos como `bx_events` do sistema UNA.

## Responsabilidades Principais:

*   Criação, leitura, atualização e exclusão (CRUD) de eventos.
*   Armazenamento de informações do evento: título, descrição, datas de início e fim, localização, organizador.
*   Suporte para imagem de destaque/banner do evento.
*   Gerenciamento de participantes (RSVP: sim, não, talvez).
*   Categorização de eventos.
*   Controle de visibilidade/privacidade (público, privado, apenas para convidados).
*   Integração com sistemas de comentários, votos, favoritos.

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite para a tabela principal `deeper_events` e tabelas de suporte como `deeper_event_rsvps`, `deeper_event_categories`, e `deeper_events_to_categories`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir e sua documentação para criar as tabelas do módulo de eventos.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve os módulos Elixir (ex: `Deeper.Content.EventsRepo`, `Deeper.Content.EventCategoriesRepo`) que encapsulam as queries SQL.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a eventos e RSVPs.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como funcionalidades que seriam \"serviços\" no UNA (ex: \"próximos eventos\", \"eventos por categoria\") serão implementadas na API.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como este módulo se integra com comentários, votos, favoritos, e o sistema de gerenciamento de arquivos para imagens de eventos.

## Estrutura da Tabela Principal (`deeper_events` - a ser detalhada em `database_schema.md`):

*   `id` (INTEGER PRIMARY KEY AUTOINCREMENT)
*   `profile_id` (INTEGER, FK para `sys_profiles.id` - organizador/criador do evento)
*   `title` (TEXT NOT NULL)
*   `slug` (TEXT NOT NULL UNIQUE)
*   `description` (TEXT NOT NULL)
*   `start_datetime` (INTEGER NOT NULL - Unix Timestamp, UTC)
*   `end_datetime` (INTEGER NOT NULL - Unix Timestamp, UTC)
*   `timezone` (TEXT - ex: \"America/New_York\", para exibição correta no cliente)
*   `location_text` (TEXT - descrição textual da localização)
*   `location_lat` (REAL - latitude, opcional)
*   `location_lng` (REAL - longitude, opcional)
*   `address` (TEXT - opcional)
*   `city` (TEXT - opcional)
*   `country` (TEXT - opcional)
*   `banner_file_id` (INTEGER, FK para `deeper_files.id` - opcional)
*   `visibility` (TEXT NOT NULL DEFAULT 'public' CHECK(visibility IN ('public', 'private', 'unlisted')))
*   `allow_rsvps` (INTEGER NOT NULL DEFAULT 1)
*   `max_attendees` (INTEGER - 0 para ilimitado, opcional)
*   `status` (TEXT NOT NULL DEFAULT 'active' CHECK(status IN ('active', 'cancelled', 'past')))
*   `created_at` (INTEGER NOT NULL - Unix Timestamp)
*   `updated_at` (INTEGER NOT NULL - Unix Timestamp)
*   Contadores (views, rsvps_yes, rsvps_maybe, rsvps_no - podem ser atualizados pela aplicação ou dinâmicos)

Este módulo permitirá uma rica funcionalidade de eventos dentro da plataforma \"Deeper\".