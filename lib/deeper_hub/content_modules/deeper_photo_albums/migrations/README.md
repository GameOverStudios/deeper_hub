# Documentação Deeper: Migrações para Módulo de Álbuns de Fotos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao módulo de Álbuns de Fotos (`deeper_photo_albums`) no sistema \"Deeper\".

## Migrações Definidas:

1.  [**Criar Tabela `deeper_photo_albums` (`create_deeper_photo_albums_table.elixir.md`)**](./create_deeper_photo_albums_table.elixir.md):
    *   Cria a tabela principal `deeper_photo_albums` para armazenar os detalhes dos álbuns.

2.  [**Criar Tabela `deeper_album_photos` (`create_deeper_album_photos_table.elixir.md`)**](./create_deeper_album_photos_table.elixir.md):
    *   Cria a tabela `deeper_album_photos` para armazenar as referências às fotos dentro de cada álbum e seus metadados específicos.

A ordem de execução destas migrações é importante devido às chaves estrangeiras. `deeper_photo_albums` deve existir antes de `deeper_album_photos` se `deeper_album_photos` a referenciar diretamente. A referência de `deeper_photo_albums.cover_photo_id` para `deeper_album_photos.id` precisa de atenção especial (veja notas no `database_schema.md`).