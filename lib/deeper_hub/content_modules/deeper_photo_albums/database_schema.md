# Documentação Deeper: Esquema do Banco de Dados para Módulo de Álbuns de Fotos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao módulo de Álbuns de Fotos (`deeper_photo_albums`).

## Tabela: `deeper_photo_albums` (Álbuns de Fotos)

```sql
CREATE TABLE IF NOT EXISTS deeper_photo_albums (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- Criador do álbum
  title TEXT NOT NULL,
  slug TEXT NOT NULL UNIQUE, -- Slug para URL amigável do álbum
  description TEXT,
  cover_photo_id INTEGER, -- FK para deeper_album_photos.id (a foto de capa deste álbum)
  privacy_level TEXT NOT NULL DEFAULT 'public' CHECK(privacy_level IN ('public', 'private_members_only', 'private_link', 'private_me_only')), -- Níveis de privacidade do álbum
  -- 'private_members_only' poderia ser para álbuns de grupo, 'private_link' para acesso por link secreto
  allow_comments INTEGER NOT NULL DEFAULT 1, -- Se o álbum em si pode ser comentado
  photos_count INTEGER NOT NULL DEFAULT 0, -- Contagem denormalizada de fotos no álbum
  -- Outros contadores como views, votes_albums, etc.
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE, -- Se o perfil for deletado, seus álbuns também são
  -- A FK para cover_photo_id é uma dependência cíclica leve, será definida após deeper_album_photos
  -- ou a aplicação garante a integridade.
  FOREIGN KEY (cover_photo_id) REFERENCES deeper_album_photos(id) ON DELETE SET NULL
);

CREATE INDEX IF NOT EXISTS idx_dpa_profile_id ON deeper_photo_albums(profile_id);
CREATE INDEX IF NOT EXISTS idx_dpa_slug ON deeper_photo_albums(slug);
CREATE INDEX IF NOT EXISTS idx_dpa_privacy_level ON deeper_photo_albums(privacy_level);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_album_photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  album_id INTEGER NOT NULL,
  file_id INTEGER NOT NULL UNIQUE, -- FK para deeper_files.id (UNIQUE para garantir que um arquivo não esteja em múltiplas entradas de 'album_photos' se não for desejado)
  profile_id INTEGER NOT NULL, -- Quem fez o upload desta foto específica (pode ser diferente do criador do álbum)
  title TEXT, -- Legenda/título da foto
  description TEXT, -- Descrição mais longa da foto (opcional)
  order_index INTEGER NOT NULL DEFAULT 0, -- Para ordenação manual das fotos dentro do álbum
  -- Contadores específicos da foto (views, votes_photo, comments_photo)
  views_count INTEGER NOT NULL DEFAULT 0,
  -- Adicionar mais metadados se necessário (localização da foto, tags da foto, etc.)
  created_at INTEGER NOT NULL, -- Timestamp do upload/associação ao álbum
  updated_at INTEGER NOT NULL, -- Timestamp da última edição da legenda/metadados da foto
  FOREIGN KEY (album_id) REFERENCES deeper_photo_albums(id) ON DELETE CASCADE, -- Se o álbum for deletado, as entradas de fotos do álbum também são
  FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE, -- Se o arquivo original for deletado, esta entrada também é
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL -- Se o uploader for deletado, a foto permanece mas o autor é NULL
);

CREATE INDEX IF NOT EXISTS idx_dap_album_id_order_index ON deeper_album_photos(album_id, order_index);
CREATE INDEX IF NOT EXISTS idx_dap_file_id ON deeper_album_photos(file_id);
CREATE INDEX IF NOT EXISTS idx_dap_profile_id ON deeper_album_photos(profile_id);
```

*   **`cover_photo_id`**: Referencia uma foto específica dentro da tabela `deeper_album_photos` que serve como capa. `ON DELETE SET NULL` significa que se a foto de capa for excluída, o campo fica nulo (o álbum pode precisar de lógica para selecionar uma nova capa).
*   **`privacy_level`**: Define quem pode ver o álbum.
*   **`photos_count`**: Contagem denormalizada, atualizada quando fotos são adicionadas/removidas.

## Tabela: `deeper_album_photos` (Fotos dentro dos Álbuns)

*   **`album_id`**: Liga a foto ao seu álbum.
*   **`file_id`**: Chave estrangeira crucial para `deeper_files.id`, apontando para o arquivo de imagem real. A constraint `UNIQUE` em `file_id` aqui significaria que um mesmo arquivo (mesmo `deeper_files.id`) não poderia ser listado como duas \"fotos de álbum\" diferentes (ex: em dois álbuns diferentes ou duas vezes no mesmo álbum). Se você quiser permitir que o mesmo arquivo seja \"usado\" em múltiplos álbuns (como uma referência), então o `UNIQUE` em `file_id` deveria ser removido, e a chave primária da tabela seria apenas `id`, ou uma chave composta `(album_id, file_id)` se um arquivo só puder estar uma vez em um álbum específico. Para simplificar, vamos manter `UNIQUE(file_id)` por enquanto, assumindo que cada entrada aqui é uma instância única de uma foto em um álbum.
*   **`profile_id`**: Quem enviou a foto.
*   **`order_index`**: Para permitir que o usuário ordene as fotos dentro do álbum.

**Consideração sobre a FK `cover_photo_id` em `deeper_photo_albums`:**
Como `deeper_photo_albums.cover_photo_id` referencia `deeper_album_photos.id`, e `deeper_album_photos.album_id` referencia `deeper_photo_albums.id`, há uma dependência que precisa ser gerenciada na ordem de criação das tabelas ou usando FKs deferíveis.
A estratégia mais simples em SQLite é criar `deeper_photo_albums` sem a FK para `cover_photo_id` inicialmente, depois criar `deeper_album_photos`, e então, se necessário e possível com `ALTER TABLE` no SQLite, adicionar a FK a `deeper_photo_albums`. No entanto, SQLite tem limitações com `ALTER TABLE` para adicionar FKs a tabelas existentes. Uma abordagem comum é criar a coluna como `NULLABLE` e a aplicação garante a integridade, ou a FK é definida na criação da tabela e as inserções são feitas em uma ordem que satisfaça as constraints (ex: criar álbum, depois adicionar fotos, depois definir uma delas como capa). O `ON DELETE SET NULL` na FK para `cover_photo_id` é uma boa salvaguarda.

Este esquema fornece a estrutura básica para um sistema de álbuns de fotos.