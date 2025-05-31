# API de Administração: Gerenciamento de Álbuns de Fotos (`deeper_photo_albums`)

Endpoints da API para administradores e moderadores globais gerenciarem os álbuns de fotos e as fotos contidas neles, do módulo `deeper_photo_albums`.

**Permissões:** Todos os endpoints aqui requerem um papel de administrador do site ou um super-moderador com permissões para gerenciar todo o conteúdo de álbuns e fotos.

## Endpoints para Álbuns de Fotos

### 1. Listar Todos os Álbuns de Fotos (Visão Administrativa)

*   **`GET /admin/photo-albums`**
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública (`GET /photo-albums`):**
    *   Retorna álbuns de **todos** os criadores.
    *   Pode listar álbuns com **qualquer nível de privacidade** por padrão ou via filtro.
*   **Query Parameters:**
    *   `profile_id` (integer): Filtrar por criador.
    *   `privacy_level` (string).
    *   `q` (string): Termo de busca (título, descrição).
    *   `page`, `per_page`.
    *   `sort_by` (ex: `created_at_desc`, `photos_count_desc`, `updated_at_desc`).
    *   `include` (ex: `creator_profile,cover_photo_details,admin_notes`).
*   **Resposta de Sucesso (200 OK):** Lista paginada de todos os álbuns.

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"title\": \"Álbum Sob Revisão de Conteúdo\",
          \"privacy_level\": \"private_me_only\", // Mesmo que privado, admin pode ver
          \"creator_profile\": { \"id\": 45, \"name\": \"Usuário Z\" },
          // ... outros campos do álbum ...
          \"admin_notes\": \"Verificar conformidade das imagens.\"
        }
      ],
      \"pagination\": { /* ... */ }
    }
```

```json
    {
      \"title\": \"Título do Álbum Ajustado (Admin)\",
      \"privacy_level\": \"public\", // Ex: Admin torna público um álbum privado após revisão
      // \"profile_id\": 60, // Transferir propriedade
      \"admin_notes\": \"Conteúdo aprovado.\"
    }
```

```json
    {
      \"title\": \"Legenda Revisada pelo Admin\",
      \"description\": \"Descrição adicional ou nota de moderação.\",
      // \"profile_id\": 70, // Reatribuir uploader da foto (se permitido)
      \"admin_notes\": \"Legenda inadequada foi alterada.\"
    }
```

```json
    {
      \"file_id\": 205, // ID de um arquivo existente em `deeper_files`
      \"profile_id\": 10, // ID do perfil a ser creditado pelo upload (pode ser o do admin ou o original)
      \"title\": \"Foto Adicionada por Admin\",
      \"order_index\": 99 // Opcional
    }
```

*   **Respostas de Erro:** `401`, `403`.

### 2. Obter Detalhes de Qualquer Álbum (Visão Administrativa)

*   **`GET /admin/photo-albums/{id_or_slug}`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include` (ex: `creator_profile,cover_photo_details,all_photos_summary,moderation_logs`).
*   **Resposta de Sucesso (200 OK):** Objeto completo do álbum.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 3. Atualizar Qualquer Álbum (Ação Administrativa)

*   **`PUT /admin/photo-albums/{id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Diferenças da API Pública:** Permite editar álbuns de qualquer criador. Pode permitir a alteração de campos como `profile_id` (transferir propriedade) ou forçar nível de privacidade.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados.

*   **Resposta de Sucesso (200 OK):** Objeto do álbum atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. Excluir Qualquer Álbum (Ação Administrativa)

*   **`DELETE /admin/photo-albums/{id}`**
*   **Autenticação:** Admin Requerida.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da exclusão.
    *   `delete_contained_files` (boolean, default: false): Se os arquivos originais em `deeper_files` também devem ser marcados para exclusão (operação perigosa, requer lógica de contagem de referência).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Deleta o álbum e suas entradas `deeper_album_photos`. A exclusão dos arquivos físicos é uma consideração separada.
*   **Respostas de Erro:** `401`, `403`, `404`.

## Endpoints para Fotos dentro de Álbuns (Visão Administrativa)

Estes endpoints permitem que um administrador do site gerencie fotos dentro de *qualquer* álbum.

### 1. Listar Fotos de Qualquer Álbum

*   **`GET /admin/photo-albums/{album_id}/photos`**
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `page`, `per_page`, `sort_by` (ex: `order_index_asc`, `created_at_desc`), `include=file_details,uploader_profile`.
*   **Resposta de Sucesso (200 OK):** Lista paginada de fotos do álbum.

### 2. Obter Detalhes de Qualquer Foto de Álbum

*   **`GET /admin/album-photos/{album_photo_id}`** (Rota não aninhada para acesso direto por ID da foto do álbum)
*   **Autenticação:** Admin Requerida.
*   **Query Parameters:** `include=file_details,uploader_profile,album_details`.
*   **Resposta de Sucesso (200 OK):** Objeto completo da foto do álbum.

### 3. Atualizar Metadados de Qualquer Foto de Álbum (Ação Administrativa)

*   **`PUT /admin/album-photos/{album_photo_id}`** (ou `PATCH`)
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Objeto da foto do álbum atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

### 4. Remover Qualquer Foto de um Álbum (Ação Administrativa)

*   **`DELETE /admin/album-photos/{album_photo_id}`**
*   **Autenticação:** Admin Requerida.
*   **Opções (Query Param ou Corpo):**
    *   `reason` (string): Motivo da remoção.
    *   `delete_original_file` (boolean, default: false): Se o arquivo original em `deeper_files` deve ser marcado para exclusão.
*   **Resposta de Sucesso (200 OK ou 204 No Content):**
*   **Ação do Backend:** Remove a entrada `deeper_album_photos`, recalcula `photos_count` no álbum.
*   **Respostas de Erro:** `401`, `403`, `404`.

### 5. Adicionar Foto a Qualquer Álbum (Ação Administrativa)
    (Menos comum para admin, mas pode ser útil para reconstruir álbuns ou corrigir erros)

*   **`POST /admin/photo-albums/{album_id}/photos`**
*   **Autenticação:** Admin Requerida.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (201 Created):** Objeto da foto do álbum criada.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

## Considerações para Repositórios e Contextos:

*   **`Deeper.Content.PhotoAlbumsRepo`:**
    *   Funções de listagem e obtenção precisarão de variantes ou flags `as_admin: true`.
    *   Funções CRUD para álbuns e fotos de álbuns precisarão bypassar verificações de propriedade quando chamadas por um admin.
    *   Lógica para reatribuir propriedade de álbuns ou uploaders de fotos.
    *   A lógica de exclusão de arquivos físicos (se `delete_original_file` for true) é complexa e deve ser manuseada com cuidado, idealmente por um serviço assíncrono que verifica outras referências ao arquivo.
*   **`Deeper.Content.PhotoAlbums` (Contexto/Serviço):**
    *   Verificará as permissões de administrador do `current_user_profile`.
    *   Orquestrará ações mais complexas, como transferir um álbum inteiro para outro usuário.
*   **Log de Auditoria:** Todas as ações administrativas devem ser logadas.

Estes endpoints fornecem a base para a administração de álbuns e fotos, permitindo controle total sobre o conteúdo visual da plataforma.