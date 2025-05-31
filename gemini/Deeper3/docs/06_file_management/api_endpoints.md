# Documentação Deeper: Endpoints da API para Gerenciamento de Arquivos

Este documento especifica os endpoints RESTful para o sistema de Gerenciamento de Arquivos do \"Deeper\". Estes endpoints permitirão o upload, download/acesso e listagem de metadados de arquivos.

Lembre-se das [Convenções de Design da API](../00_core_concepts/api_design_conventions.md) (versionamento, formato JSON, códigos de status, etc.). Todos os endpoints abaixo estão sob o prefixo `/api/v1`.

## 1. Upload de Arquivo

### `POST /files/upload`

*   **Descrição:** Faz o upload de um novo arquivo. O arquivo é enviado como `multipart/form-data`.
*   **Autenticação:** Requerida (o `profile_id` do uploader será extraído do token JWT).
*   **Corpo da Requisição:** `multipart/form-data`
    *   `file`: O arquivo binário.
    *   `storage_object` (opcional, string): O nome do `sys_objects_storage` a ser usado. Se omitido, um storage padrão (ex: \"deeper_local_files\") será usado.
    *   `is_private` (opcional, boolean ou 0/1): Indica se o arquivo deve ser privado. Default: `0` (público).
    *   `path_prefix` (opcional, string): Um prefixo de caminho para organizar o arquivo dentro do storage (ex: \"avatars/\", \"post_attachments/\").
    *   `meta` (opcional, string JSON): Metadados adicionais em formato JSON.
*   **Resposta de Sucesso (201 Created):**

```json
    {
      \"data\": {
        \"id\": 123, // ID do arquivo em deeper_files
        \"profile_id\": 45,
        \"storage_object\": \"deeper_local_files\",
        \"remote_id\": \"a1b2c3d4-e5f6-7890-1234-567890abcdef.jpg\", // UUID.ext ou hash.ext
        \"path\": \"avatars/a1b2c3d4-e5f6-7890-1234-567890abcdef.jpg\", // path_prefix + remote_id
        \"file_name\": \"minha_foto.jpg\",
        \"mime_type\": \"image/jpeg\",
        \"ext\": \"jpg\",
        \"size\": 102400, // em bytes
        \"added\": 1678886400, // Unix timestamp
        \"modified\": 1678886400,
        \"is_private\": 0,
        \"img_width\": 800, // Se for imagem
        \"img_height\": 600, // Se for imagem
        \"meta\": {\"custom_key\": \"custom_value\"}, // Opcional
        \"url\": \"/api/v1/files/view/deeper_local_files/avatars/a1b2c3d4-e5f6-7890-1234-567890abcdef.jpg\" // URL de acesso direto (se público)
      }
    }
```

```json
    {
      \"data\": {
        \"file_id\": 123,
        \"url\": \"https://s3.amazon.com/bucket/path/to/file.jpg?AssinaturaAqui...\",
        \"expires_at\": 1678887000 // Unix timestamp de expiração da URL (se aplicável)
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 123,
        \"profile_id\": 45,
        \"storage_object\": \"deeper_local_files\",
        \"remote_id\": \"a1b2c3d4.jpg\",
        \"path\": \"avatars/a1b2c3d4.jpg\",
        \"file_name\": \"minha_foto.jpg\",
        \"mime_type\": \"image/jpeg\",
        \"ext\": \"jpg\",
        \"size\": 102400,
        \"added\": 1678886400,
        \"modified\": 1678886400,
        \"is_private\": 0,
        \"img_width\": 800,
        \"img_height\": 600,
        \"meta\": null,
        // URL de acesso pode ser incluída aqui também
        \"access_url\": \"/api/v1/files/view/deeper_local_files/avatars/a1b2c3d4.jpg\"
      }
    }
```

```json
    {
      \"data\": [
        // ... array de objetos de metadados de arquivo (formato similar a GET /files/{file_id}) ...
      ],
      \"pagination\": {
        \"total_items\": 150,
        \"total_pages\": 8,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    {
      \"file_name\": \"novo_nome.jpg\",
      \"is_private\": 1,
      \"meta\": {\"nova_chave\": \"novo_valor\"}
    }
```

```json
    // Exemplo para 200 OK
    {
      \"message\": \"Arquivo excluído com sucesso.\"
    }
```

```json
    {
      \"data\": {
        \"file_id\": 123,
        \"access_token\": \"long_random_secure_hash_string\",
        \"storage_object\": \"deeper_local_files\",
        \"expires_in\": 3600, // segundos, baseado no token_life do storage_object
        \"access_url_with_token\": \"/api/v1/files/view/deeper_local_files/path/to/file.jpg?token=long_random_secure_hash_string\"
      }
    }
```

*   **Respostas de Erro:**
    *   `400 Bad Request`: Arquivo não enviado, `storage_object` inválido, `meta` JSON inválido.
    *   `401 Unauthorized`: Autenticação falhou.
    *   `403 Forbidden`: Usuário não tem permissão para upload ou excedeu cota (se implementado).
    *   `413 Payload Too Large`: Arquivo excede `max_file_size` do storage.
    *   `500 Internal Server Error`: Erro ao salvar arquivo ou registrar no DB.

## 2. Acesso/Visualização de Arquivos

Existem duas abordagens principais para servir arquivos: servir o binário diretamente ou redirecionar/fornecer uma URL para um CDN/storage.

### Abordagem A: Servir Arquivo Binário Diretamente pela API (para arquivos privados ou quando não há CDN)

#### `GET /files/view/{storage_object}/{+remote_path_and_id}`
    Exemplo: `/api/v1/files/view/deeper_local_files/avatars/a1b2c3d4.jpg`
    Onde `{+remote_path_and_id}` captura todo o caminho após o `storage_object`, incluindo subdiretórios.

*   **Descrição:** Retorna o conteúdo binário do arquivo.
*   **Autenticação:**
    *   Se o arquivo for público (`deeper_files.is_private = 0`): Opcional.
    *   Se o arquivo for privado (`deeper_files.is_private = 1`): Requerida, OU um `access_token` válido.
*   **Query Parameters (para acesso a arquivos privados sem header de autenticação):**
    *   `token` (string): Um `hash` válido da tabela `sys_storage_tokens`.
*   **Resposta de Sucesso (200 OK):**
    *   Corpo: O conteúdo binário do arquivo.
    *   Cabeçalhos:
        *   `Content-Type`: O `mime_type` do arquivo.
        *   `Content-Length`: O `size` do arquivo.
        *   `Content-Disposition`: `inline; filename=\"nome_original.jpg\"` (para visualização no navegador) ou `attachment; filename=\"nome_original.jpg\"` (para forçar download).
*   **Respostas de Erro:**
    *   `401 Unauthorized`: Token inválido/expirado ou autenticação necessária para arquivo privado.
    *   `403 Forbidden`: Usuário autenticado, mas sem permissão para acessar este arquivo privado.
    *   `404 Not Found`: Arquivo não encontrado no `storage_object` com o `remote_id` especificado.
    *   `500 Internal Server Error`.

### Abordagem B: Obter URL Assinada (para S3 ou outros storages em nuvem, ou para desacoplar o serving)

#### `GET /files/url/{file_id}`

*   **Descrição:** Retorna uma URL (potencialmente assinada e de curta duração) para acessar o arquivo diretamente do storage.
*   **Autenticação:** Requerida se o arquivo for privado ou se a política geral exigir.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401`, `403`, `404`.

**Nota:** A escolha entre Abordagem A e B (ou suportar ambas) dependerá da configuração do `storage_object` (se é local, S3, etc.) e da política de acesso. Para `engine: \"Local\"`, a Abordagem A é mais comum.

## 3. Obter Metadados de um Arquivo

### `GET /files/{file_id}`

*   **Descrição:** Retorna os metadados de um arquivo específico, conforme registrado na tabela `deeper_files`.
*   **Autenticação:** Requerida se o arquivo for privado ou se o acesso aos metadados for restrito.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401`, `403`, `404`.

## 4. Listar Metadados de Arquivos

### `GET /files`

*   **Descrição:** Retorna uma lista paginada de metadados de arquivos.
*   **Autenticação:** Opcional. Se autenticado, pode filtrar arquivos com base nas permissões do usuário ou listar apenas os arquivos do próprio usuário. Se não autenticado, lista apenas arquivos públicos.
*   **Query Parameters (para filtragem, paginação, ordenação - ver `api_design_conventions.md`):**
    *   `profile_id` (integer): Filtrar por ID do uploader.
    *   `mime_type` (string): Filtrar por tipo MIME (ex: `image/jpeg`, `video/%`).
    *   `ext` (string): Filtrar por extensão.
    *   `is_private` (0 ou 1): Filtrar por status de privacidade.
    *   `file_name` (string): Buscar por nome de arquivo (usando `LIKE %term%`).
    *   `storage_object` (string): Filtrar por storage.
    *   `added_since` (integer, Unix timestamp): Arquivos adicionados desde este tempo.
    *   `page`, `per_page` (ou `limit`, `offset`).
    *   `sort_by` (ex: `added_desc`, `size_asc`, `file_name_asc`).
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400` (parâmetros inválidos), `401`.

## 5. Atualizar Metadados de um Arquivo (Opcional/Admin)

### `PATCH /files/{file_id}`

*   **Descrição:** Atualiza metadados selecionados de um arquivo (ex: `file_name`, `is_private`, `meta`). Não altera o conteúdo do arquivo em si.
*   **Autenticação:** Requerida (geralmente, apenas o proprietário do arquivo ou um administrador).
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna o objeto de metadados do arquivo atualizado.
*   **Respostas de Erro:** `400`, `401`, `403`, `404`.

## 6. Excluir um Arquivo (Opcional/Admin)

### `DELETE /files/{file_id}`

*   **Descrição:** Exclui um arquivo (registro de metadados e, idealmente, o arquivo físico do storage).
*   **Autenticação:** Requerida (geralmente, apenas o proprietário ou um administrador).
*   **Resposta de Sucesso (200 OK ou 204 No Content):**

*   **Respostas de Erro:** `401`, `403`, `404`, `500` (se a exclusão física falhar).

## 7. Gerenciamento de Tokens de Acesso (para arquivos privados)

### `POST /files/{file_id}/access-token`

*   **Descrição:** Gera um novo token de acesso de curta duração para um arquivo específico.
*   **Autenticação:** Requerida. O usuário deve ter permissão para acessar o `file_id` (geralmente o proprietário ou alguém com permissão explícita).
*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:** `401`, `403`, `404`.

Estes endpoints fornecem uma base sólida para o gerenciamento de arquivos. A lógica nos controllers Elixir precisará interagir com os `StorageRepo`, `FilesRepo`, e `TokensRepo`, além de lidar com o salvamento físico dos arquivos enviados.