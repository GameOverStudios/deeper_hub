# Documentação Deeper: Módulo de Álbuns de Fotos (`deeper_photo_albums`)

Este módulo da API \"Deeper\" é responsável pelo gerenciamento de álbuns de fotos e as fotos contidas neles. Os usuários poderão criar álbuns, fazer upload de múltiplas fotos para esses álbuns, visualizá-los e interagir com eles. Visa replicar funcionalidades de módulos como `bx_photos` ou `bx_albums` do sistema UNA.

## Responsabilidades Principais:

*   Criação, leitura, atualização e exclusão (CRUD) de álbuns de fotos.
*   Armazenamento de informações do álbum: título, descrição, criador, data, privacidade, imagem de capa do álbum.
*   Upload de múltiplas fotos para um álbum.
*   Armazenamento de metadados para cada foto: título/legenda, data de upload, quem enviou, ordem dentro do álbum.
*   Visualização de álbuns e fotos individuais (com navegação).
*   Integração com sistemas de comentários, votos/reações (para álbuns e/ou fotos individuais).
*   Forte integração com o módulo `06_file_management/` para o armazenamento real dos arquivos de imagem.

## Componentes Detalhados:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite para as tabelas `deeper_photo_albums` e `deeper_album_photos` (que armazena a referência ao arquivo de imagem e metadados da foto no álbum).

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas do módulo de álbuns de fotos.

3.  [**Módulos de Acesso a Dados (`data_access_modules.md`)**](./data_access_modules.md):
    *   Descreve o módulo Elixir (ex: `Deeper.Content.PhotoAlbumsRepo`) que encapsula as queries SQL.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para todas as operações relacionadas a álbuns e fotos.

5.  [**Mapeamento da Lógica de Serviço (`service_logic_mapping.md`)**](./service_logic_mapping.md):
    *   Descreve como funcionalidades que seriam \"serviços\" no UNA (ex: \"últimos álbuns\", \"fotos populares\") são implementadas na API.

6.  [**Objetos Associados (`associated_objects.md`)**](./associated_objects.md):
    *   Detalha como este módulo se integra com perfis de usuário, o sistema de gerenciamento de arquivos, comentários, votos, etc.

## Estrutura de Dados Chave (a ser detalhada em `database_schema.md`):

*   **`deeper_photo_albums`**:
    *   `id`, `profile_id` (criador), `title`, `slug`, `description`, `cover_photo_id` (FK para `deeper_album_photos.id`), `privacy_level`, `photos_count`, `created_at`, `updated_at`.
*   **`deeper_album_photos`**:
    *   `id`, `album_id` (FK), `file_id` (FK para `deeper_files.id`), `profile_id` (quem enviou a foto, pode ser diferente do criador do álbum), `title` (legenda da foto), `order_index` (para ordenação no álbum), `created_at`.

Este módulo será central para o compartilhamento de mídia visual na plataforma \"Deeper\".