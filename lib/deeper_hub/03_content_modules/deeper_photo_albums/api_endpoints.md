# Documentação Deeper: Endpoints da API para Módulo de Álbuns de Fotos

Este documento especifica os endpoints RESTful para o módulo de Álbuns de Fotos (`deeper_photo_albums`) do \"Deeper\".

Lembre-se das [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## Álbuns de Fotos (`/photo-albums`)

### 1. Criar um Novo Álbum de Fotos

*   **`POST /photo-albums`**
*   **Autenticação:** Requerida. O `profile_id` do criador virá do JWT.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"title\": \"Férias na Praia 2023\",
      \"slug\": \"ferias-praia-2023\", // Opcional
      \"description\": \"Fotos das minhas últimas férias.\", // Opcional
      \"privacy_level\": \"public\" // ex: \"public\", \"private_me_only\", \"private_link\"
      // \"allow_comments\": true // Opcional, default true
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"profile_id\": 45,
        \"title\": \"Férias na Praia 2023\",
        \"slug\": \"ferias-praia-2023\",
        \"description\": \"Fotos das minhas últimas férias.\",
        \"cover_photo_id\": null,
        \"cover_photo_details\": null,
        \"privacy_level\": \"public\",
        \"allow_comments\": 1,
        \"photos_count\": 0,
        \"created_at\": 1699980000,
        \"updated_at\": 1699980000,
        \"creator_profile\": { \"id\": 45, \"name\": \"Nome do Criador\" }
      }
    }
```

```json
    {
      \"album_photo_id\": 789 // ID da foto (de `deeper_album_photos.id`) a ser usada como capa
    }
```

```json
    // Para uma única foto
    {
      \"file_id\": 101, // ID do arquivo previamente carregado via POST /files/upload
      \"title\": \"Pôr do sol na praia\", // Legenda, opcional
      \"description\": \"Foto tirada no dia X.\", // Opcional
      \"order_index\": 0 // Opcional
    }
    // OU para múltiplas fotos
    // {
    //   \"photos\": [
    //     { \"file_id\": 101, \"title\": \"Foto 1\" },
    //     { \"file_id\": 102, \"title\": \"Foto 2\", \"order_index\": 1 }
    //   ]
    // }
```

```json
    // Para uma única foto
    {
      \"data\": {
        \"id\": 50, // ID de deeper_album_photos
        \"album_id\": 1,
        \"file_id\": 101,
        \"profile_id\": 45, // Quem fez upload do arquivo/adicionou ao álbum
        \"title\": \"Pôr do sol na praia\",
        \"order_index\": 0,
        \"created_at\": 1699980500,
        \"file_details\": { /* ... detalhes do arquivo de deeper_files ... */ }
      }
    }
```

```json
    {
      \"title\": \"Nova legenda para a foto\",
      \"description\": \"Descrição atualizada.\",
      \"order_index\": 2
    }
```

```json
    {
      \"ordered_photo_ids\": [10, 15, 12] // Lista de `deeper_album_photos.id` na nova ordem
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `400` (validação), `401`, `403`.

### 2. Listar Álbuns de Fotos

*   **`GET /photo-albums`**
*   **Autenticação:** Opcional. Filtra por privacidade se não autenticado ou não for o proprietário.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por criador.
    *   `privacy_level` (string).
    *   `q` (string): Buscar por título/descrição.
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `title_asc`, `photos_count_desc`).
    *   `include` (string CSV, ex: `creator_profile,cover_photo_details`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de álbuns.
*   **Respostas de Erro:** `400`.

### 3. Obter um Álbum de Fotos Específico

*   **`GET /photo-albums/{id_or_slug}`**
*   **Autenticação:** Opcional. Necessária para álbuns não públicos se não for o proprietário.
*   **Query Parameters:** `include` (ex: `creator_profile,cover_photo_details,photos_list_preview`).
    *   `photos_list_preview` poderia retornar as primeiras N fotos do álbum.
*   **Resposta de Sucesso (200 OK):** Objeto do álbum.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 4. Atualizar um Álbum de Fotos

*   **`PUT /photo-albums/{id}`** ou **`PATCH /photo-albums/{id}`**
*   **Autenticação:** Requerida (proprietário ou admin).
*   **Corpo da Requisição (JSON):** Campos a atualizar (ex: `title`, `description`, `privacy_level`).
*   **Resposta de Sucesso (200 OK):** Objeto do álbum atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Excluir um Álbum de Fotos

*   **`DELETE /photo-albums/{id}`**
*   **Autenticação:** Requerida (proprietário ou admin).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Deleta o álbum e suas entradas em `deeper_album_photos` (devido ao `ON DELETE CASCADE`). Não deleta os arquivos em `deeper_files` automaticamente, a menos que uma lógica de contagem de referência seja implementada.

### 6. Definir Foto de Capa do Álbum

*   **`PUT /photo-albums/{album_id}/cover`**
*   **Autenticação:** Requerida (proprietário do álbum).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Objeto do álbum atualizado com a nova capa.
*   **Respostas de Erro:** `400` (foto não pertence ao álbum), `401`, `403`, `404`.

## Fotos dentro de um Álbum (`/photo-albums/{album_id}/photos`)

### 1. Adicionar Foto(s) a um Álbum

*   **`POST /photo-albums/{album_id}/photos`**
*   **Autenticação:** Requerida (proprietário do álbum ou usuário com permissão para adicionar fotos ao álbum, se houver tal conceito).
*   **Corpo da Requisição (JSON):** Pode ser uma única foto ou uma lista para upload em lote de referências.

*   **Resposta de Sucesso (201 Created):**
    *   Se uma foto: Objeto da foto do álbum criada.
    *   Se múltiplas fotos: Lista dos objetos das fotos do álbum criadas, ou um status de sucesso geral.

*   **Ação do Backend:** Cria entrada(s) em `deeper_album_photos` e atualiza `photos_count` em `deeper_photo_albums`.
*   **Respostas de Erro:** `400` (`file_id` inválido/já usado), `401`, `403`, `404` (álbum não encontrado).

### 2. Listar Fotos de um Álbum

*   **`GET /photo-albums/{album_id}/photos`**
*   **Autenticação:** Opcional (depende da privacidade do álbum).
*   **Query Parameters:**
    *   `page`, `per_page`.
    *   `sort_by` (ex: `order_index_asc`, `created_at_desc`).
    *   `include` (ex: `file_details,uploader_profile`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de fotos do álbum.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Obter Detalhes de uma Foto Específica de um Álbum
    (Embora uma foto de álbum seja mais um link para `deeper_files`, pode ter metadados próprios como legenda e ordem).

*   **`GET /photo-albums/{album_id}/photos/{album_photo_id}`** (ou simplesmente `GET /album-photos/{album_photo_id}` se o ID for globalmente único)
*   **Autenticação:** Opcional.
*   **Query Parameters:** `include` (ex: `file_details,uploader_profile,album_details`).
*   **Resposta de Sucesso (200 OK):** Objeto da foto do álbum.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 4. Atualizar Metadados de uma Foto em um Álbum (Legenda, Ordem)

*   **`PUT /photo-albums/{album_id}/photos/{album_photo_id}`** (ou `PATCH`)
    (Ou `PUT /album-photos/{album_photo_id}`)
*   **Autenticação:** Requerida (proprietário do álbum/foto ou admin).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Objeto da foto do álbum atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 5. Reordenar Fotos em um Álbum

*   **`PUT /photo-albums/{album_id}/photos/order`**
*   **Autenticação:** Requerida (proprietário do álbum).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 6. Remover uma Foto de um Álbum

*   **`DELETE /photo-albums/{album_id}/photos/{album_photo_id}`**
    (Ou `DELETE /album-photos/{album_photo_id}`)
*   **Autenticação:** Requerida (proprietário do álbum/foto ou admin).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Remove a entrada de `deeper_album_photos`. Atualiza `photos_count` no álbum. Não deleta o arquivo em `deeper_files` (a menos que haja lógica de contagem de referências).
*   **Respostas de Erro:** `401`, `403`, `404`.

## Interações (Comentários, Votos - Exemplos)

*   **Comentários em um Álbum:** `GET /photo-albums/{album_id}/comments` (delegaria ao sistema de comentários usando `object_name=\"deeper_photo_albums\"`)
*   **Comentários em uma Foto de Álbum:** `GET /album-photos/{album_photo_id}/comments` (delegaria usando `object_name=\"deeper_album_photos\"`)
*   **Votos/Reações:** Similarmente, usando `object_name` apropriados.

Estes endpoints fornecem uma interface completa para o gerenciamento de álbuns de fotos e suas fotos. A principal interação com o sistema de arquivos (`06_file_management`) ocorre no momento do upload inicial do arquivo, e depois o módulo de álbuns apenas referencia esses `file_id`s.