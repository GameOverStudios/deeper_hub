# Documentação Deeper: Mapeamento da Lógica de \"Serviço\" para API (Módulo `deeper_photo_albums`)

No sistema UNA, um módulo de álbuns de fotos (`bx_photos` ou `bx_albums`) ofereceria \"serviços\" para renderizar blocos de UI, como galerias de álbuns recentes, visualizações de fotos populares, ou a página de um álbum específico. A API RESTful \"Deeper\" traduz essas funcionalidades em endpoints que retornam dados JSON, deixando a responsabilidade da apresentação para o cliente frontend.

## 1. Serviço: \"Listar Últimos Álbuns Criados\"

*   **Funcionalidade UNA PHP (Exemplo Hipotético):**
    *   `BxPhotosModule->service_latest_albums(int $count = 6, bool $show_cover = true)`
    *   Retornaria HTML com uma grade dos `N` álbuns mais recentes, mostrando a capa e o título.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/photo-albums`
    *   **Query Parameters:**
        *   `sort_by=created_at_desc`
        *   `privacy_level=public` (ou lógica para incluir álbuns visíveis ao usuário logado)
        *   `per_page={N}` (ex: `per_page=6`)
        *   `page=1`
        *   `include=creator_profile,cover_photo_details` (para obter a URL da imagem de capa e nome do criador).
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** A função `list_albums/2` lidaria com esses parâmetros.
    *   **Responsabilidade do Cliente:** Buscar os dados e renderizar a grade de álbuns.

## 2. Serviço: \"Listar Fotos de um Álbum\" (Página de Visualização do Álbum)

*   **Funcionalidade UNA PHP:**
    *   `BxPhotosModule->service_view_album(int $album_id, int $page = 1, int $per_page = 20)`
    *   Retornaria HTML da página do álbum, incluindo informações do álbum e uma grade paginada de suas fotos.

*   **Mapeamento para API \"Deeper\":**
    *   **Passo 1: Obter detalhes do álbum:**
        *   `GET /api/v1/photo-albums/{album_id_or_slug}?include=creator_profile,cover_photo_details`
    *   **Passo 2: Obter fotos do álbum (paginado):**
        *   `GET /api/v1/photo-albums/{album_id}/photos?page={page_num}&per_page={count}&sort_by=order_index_asc&include=file_details`
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** Funções `get_album/2` e `list_photos_in_album/3`.
    *   **Responsabilidade do Cliente:** Fazer as duas chamadas (ou uma se a API for projetada para aninhar fotos na resposta do álbum com paginação), exibir informações do álbum, e renderizar a grade paginada de fotos.

## 3. Serviço: \"Visualizar uma Foto Específica\" (com navegação anterior/próxima)

*   **Funcionalidade UNA PHP:**
    *   `BxPhotosModule->service_view_photo(int $album_photo_id)`
    *   Retornaria HTML da página da foto, com a imagem, legenda, e links para foto anterior/próxima no mesmo álbum.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/photo-albums/{album_id}/photos/{album_photo_id}` (ou `GET /api/v1/album-photos/{album_photo_id}`)
    *   **Query Parameters:** `include=file_details,uploader_profile,album_details`
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** A função `get_album_photo/2`. Para a navegação \"anterior/próxima\", o `PhotoAlbumsRepo` poderia ter uma função adicional:
        *   `get_sibling_photos(album_photo_id, album_id)`: Retornaria os IDs (ou dados básicos) da foto anterior e próxima baseada no `order_index`.

```elixir
        # Exemplo no PhotoAlbumsRepo
        # def get_sibling_photos(current_photo_order_index, album_id) do
        #   prev_sql = \"SELECT id, title FROM deeper_album_photos WHERE album_id = ? AND order_index < ? ORDER BY order_index DESC LIMIT 1\"
        #   next_sql = \"SELECT id, title FROM deeper_album_photos WHERE album_id = ? AND order_index > ? ORDER BY order_index ASC LIMIT 1\"
        #   # Executar queries e retornar mapa como %{previous: ..., next: ...}
        # end
```

        Esta informação de `previous` e `next` poderia ser incluída na resposta do `GET /album-photos/{album_photo_id}` se um parâmetro `include=siblings` fosse passado.
    *   **Responsabilidade do Cliente:** Exibir a foto, legenda, e usar os dados de `siblings` para renderizar links de navegação.

## 4. Serviço: \"Formulário de Upload de Fotos para um Álbum\"

*   **Funcionalidade UNA PHP:**
    *   `BxPhotosModule->service_upload_photos_form(int $album_id)`
    *   Retornaria HTML do formulário de upload.

*   **Mapeamento para API \"Deeper\":**
    *   **Não um endpoint que retorna UI.** O formulário/uploader é construído pelo cliente.
    *   **Fluxo:**
        1.  Cliente exibe um uploader (ex: Dropzone.js).
        2.  Para cada arquivo, o cliente faz `POST /api/v1/files/upload` para o sistema de gerenciamento de arquivos, obtendo um `file_id`.
        3.  Após todos os uploads de arquivos, o cliente faz `POST /api/v1/photo-albums/{album_id}/photos` com um corpo contendo uma lista de `{file_id: ..., title: ..., ...}` para associar os arquivos carregados ao álbum.
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** Função `add_photo_to_album/1` (que pode ser adaptada para aceitar uma lista de fotos a serem adicionadas).
    *   **Responsabilidade do Cliente:** Gerenciar o processo de upload de arquivos e depois a associação deles ao álbum.

## 5. Serviço: \"Bloco de Álbuns de um Perfil de Usuário\"

*   **Funcionalidade UNA PHP:**
    *   `BxPhotosModule->service_profile_albums_block(int $target_profile_id, int $count = 4)`
    *   Retornaria HTML com uma amostra dos álbuns do perfil.

*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `GET /api/v1/photo-albums`
    *   **Query Parameters:**
        *   `profile_id={target_profile_id}`
        *   `per_page={N}` (ex: 4)
        *   `sort_by=created_at_desc`
        *   `include=cover_photo_details`
        *   (Considerar `privacy_level` se o visualizador não for o proprietário do perfil).
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** Função `list_albums/2`.
    *   **Responsabilidade do Cliente:** Renderizar o bloco.

## 6. Serviço: \"Definir Foto como Capa do Álbum\"

*   **Funcionalidade UNA PHP:** Uma ação na UI, geralmente um botão em uma foto dentro de um álbum.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `PUT /api/v1/photo-albums/{album_id}/cover`
    *   **Corpo da Requisição:** `{ \"album_photo_id\": ... }`
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** Função `set_album_cover/2`.
    *   **Responsabilidade do Cliente:** Fornecer a UI (botão \"Definir como Capa\") e chamar o endpoint.

## 7. Serviço: \"Reordenar Fotos em um Álbum\"

*   **Funcionalidade UNA PHP:** Interface de arrastar e soltar para reordenar fotos.
*   **Mapeamento para API \"Deeper\":**
    *   **Endpoint:** `PUT /api/v1/photo-albums/{album_id}/photos/order`
    *   **Corpo da Requisição:** `{ \"ordered_photo_ids\": [id3, id1, id2] }`
    *   **Lógica no `Deeper.Content.PhotoAlbumsRepo`:** Função `update_photos_order/2`.
    *   **Responsabilidade do Cliente:** Implementar a UI de arrastar e soltar e, ao salvar, enviar a nova lista de IDs ordenados para a API.

## Considerações:

*   **Processamento de Imagens (Thumbnails, Redimensionamento):** O sistema UNA original, via `sys_objects_transcoder`, lidaria com a geração de diferentes tamanhos de imagem. Na API \"Deeper\":
    *   O `06_file_management/` poderia ser estendido para ter um sistema de transcodificação assíncrono após o upload.
    *   A API `GET /files/view/...` poderia aceitar parâmetros de query para solicitar um tamanho específico (ex: `?size=thumbnail`), e o backend serviria a versão apropriada ou a geraria sob demanda (com caching).
    *   Alternativamente, o `deeper_files` poderia armazenar referências a múltiplas versões de um arquivo geradas por um processo de transcodificação.
    Por enquanto, assumimos que o `file_id` aponta para a imagem original ou uma versão principal, e o cliente lida com o redimensionamento na exibição se necessário.
*   **Eficiência de Dados:** Para galerias com muitas fotos, retornar todos os detalhes de cada foto na listagem de álbuns pode ser pesado. O cliente deve solicitar apenas os campos necessários (ex: URL da miniatura) usando um parâmetro `fields` ou a API deve fornecer visualizações \"resumidas\" por padrão.

Este mapeamento mostra como funcionalidades de UI de um módulo de álbuns podem ser suportadas por uma API RESTful, focando na entrega de dados estruturados.