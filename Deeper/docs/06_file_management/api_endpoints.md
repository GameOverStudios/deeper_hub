# Documentação Deeper: Endpoints da API para Gerenciamento de Arquivos

Este documento especifica os endpoints da API RESTful \"Deeper\" para o upload, recuperação de metadados e acesso a arquivos. Estes endpoints interagem com os módulos `Deeper.Files.StorageRepo`, `Deeper.Files.FilesRepo`, e um serviço de upload como `Deeper.Files.FileUploaderService`.

Todos os endpoints estarão sob o prefixo `/api/v1/files`.

## Endpoints Principais:

### 1. Upload de Novo Arquivo

*   **Endpoint:** `POST /api/v1/files/upload/{storage_object_name}`
*   **Descrição:** Permite o upload de um novo arquivo para um \"objeto de armazenamento\" específico.
*   **Path Parameter:**
    *   `storage_object_name`: O nome do `object` de `sys_objects_storage` que define o destino e as regras do upload (ex: `bx_persons_pictures_main`, `general_attachments`).
*   **Autenticação:** Requer JWT. O `profile_id` do uploader é extraído do token.
*   **Corpo da Requisição:** `multipart/form-data`.
    *   Deve conter um campo de arquivo, comumente nomeado `file`.
    *   Pode conter campos adicionais opcionais, como `title`, `description`, `private` (0 ou 1, se o usuário puder definir na hora do upload e o storage object permitir).
*   **Resposta de Sucesso (201 Created):**

```json
    {
      \"data\": {
        \"file_id\": 567, // O ID do registro na tabela de metadados (ex: sys_files.id ou bx_persons_pictures.id)
        \"remote_id\": \"a1b2c3d4-e5f6-7777-8888-9999abcdef00.jpg\", // Identificador único no storage físico
        \"file_name_original\": \"minha_foto_de_ferias.jpg\", // Nome original do arquivo
        \"file_name_stored\": \"a1b2c3d4-e5f6-7777-8888-9999abcdef00.jpg\", // Nome como foi salvo (pode ser o remote_id)
        \"url\": \"https://cdn.deeper.example.com/files/a1b2c3d4-e5f6-7777-8888-9999abcdef00.jpg\", // URL pública ou de acesso ao arquivo
        \"mime_type\": \"image/jpeg\",
        \"size\": 123456, // Tamanho em bytes
        \"is_private\": false,
        \"added_timestamp\": 1678886400
      }
    }
```

```json
    {
      \"data\": {
        \"file_id\": 567,
        \"remote_id\": \"a1b2c3d4-e5f6-7777-8888-9999abcdef00.jpg\",
        \"profile_id_uploader\": 101, // ID do perfil que fez o upload
        \"file_name_original\": \"minha_foto_de_ferias.jpg\",
        \"url\": \"https://cdn.deeper.example.com/files/a1b2c3d4-e5f6-7777-8888-9999abcdef00.jpg\",
        \"mime_type\": \"image/jpeg\",
        \"size\": 123456,
        \"is_private\": false,
        \"added_timestamp\": 1678886400,
        \"modified_timestamp\": 1678886500
        // Outros metadados relevantes (dimensions, duration, etc.)
      }
    }
```

*   **Respostas de Erro:**
    *   `400 Bad Request`: Nenhum arquivo enviado, tipo de arquivo não permitido, arquivo excede o tamanho máximo, `storage_object_name` inválido.
    *   `401 Unauthorized`: Não autenticado.
    *   `403 Forbidden`: Cota de armazenamento excedida (pessoal ou do storage object).
    *   `500 Internal Server Error`: Falha ao salvar o arquivo físico ou ao registrar metadados.
*   **Lógica do Backend:**
    1.  Controller recebe a requisição.
    2.  Chama `Deeper.Files.FileUploaderService.upload_file/5` passando `storage_object_name`, `uploader_profile_id` (do JWT), o caminho do arquivo temporário no servidor (do Plug.Upload), nome original e mime_type.
    3.  O serviço lida com validações, armazenamento físico e registro de metadados.

### 2. Obter Metadados de um Arquivo

*   **Endpoint:** `GET /api/v1/files/meta/{storage_object_name}/{file_identifier}`
*   **Descrição:** Retorna os metadados de um arquivo específico.
*   **Path Parameters:**
    *   `storage_object_name`: O nome do `object` de `sys_objects_storage`.
    *   `file_identifier`: Pode ser o `id` numérico da tabela de metadados do arquivo OU o `remote_id` do arquivo. A API tentará buscar por ambos.
*   **Autenticação:** Requer JWT.
*   **Autorização:**
    *   Administradores podem ver metadados de qualquer arquivo.
    *   Usuários normais podem ver metadados de seus próprios arquivos.
    *   Se o arquivo for público ou se o usuário tiver permissão para ver o conteúdo ao qual o arquivo está associado, ele também poderá ver os metadados.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.
*   **Lógica do Backend:**
    1.  Controller chama `StorageRepo.get_storage_object_config`.
    2.  Chama `FilesRepo.get_file_metadata_by_id` ou `get_file_metadata_by_remote_id` (passando `table_files` da config).
    3.  Aplica lógica de autorização.

### 3. Acessar/Baixar um Arquivo

Este endpoint é usado principalmente para arquivos privados ou quando não se quer expor a URL direta do storage (ex: S3). Para arquivos públicos em CDNs, o cliente usaria a `url` retornada pelo endpoint de upload ou de metadados.

*   **Endpoint:** `GET /api/v1/files/access/{storage_object_name}/{file_identifier}`
*   **Descrição:** Permite o download ou visualização inline de um arquivo.
*   **Path Parameters:**
    *   `storage_object_name`: O nome do `object` de `sys_objects_storage`.
    *   `file_identifier`: Pode ser o `id` ou `remote_id`.
*   **Query Parameters (Opcionais):**
    *   `download=true`: Sugere ao navegador para baixar o arquivo em vez de tentar exibi-lo inline (usando `Content-Disposition: attachment`).
    *   `token`: Um token de acesso temporário (se `sys_storage_tokens` for implementado para acesso de curto prazo sem JWT completo).
*   **Autenticação:** Requer JWT (ou um token de acesso válido, se aplicável).
*   **Autorização:**
    *   Se o arquivo for `private = 1`, verifica se o usuário autenticado é o `profile_id` que fez o upload, ou se tem permissão para ver o conteúdo ao qual o arquivo está associado (lógica complexa que pode envolver consultar a entidade pai).
    *   Pode usar o sistema `sys_storage_tokens` do UNA para gerar URLs temporárias seguras, especialmente para engines como S3.
*   **Resposta de Sucesso:**
    *   Corpo da resposta é o conteúdo binário do arquivo.
    *   Cabeçalhos HTTP importantes:
        *   `Content-Type`: (ex: `image/jpeg`, `application/pdf`).
        *   `Content-Length`: Tamanho do arquivo.
        *   `Content-Disposition`: `inline; filename=\"nome_original.jpg\"` ou `attachment; filename=\"nome_original.jpg\"`.
        *   `Cache-Control`, `ETag` para caching.
*   **Respostas de Erro:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.
*   **Lógica do Backend:**
    1.  Busca metadados do arquivo (como no endpoint de metadados).
    2.  Verifica permissões.
    3.  Se `engine == \"Local\"`: Lê o arquivo do sistema de arquivos do servidor \"Deeper\" e o transmite.
    4.  Se `engine == \"S3\"` (e não usando URL pré-assinada): A API \"Deeper\" pode atuar como um proxy, baixando do S3 e retransmitindo, ou (melhor) gerar uma **URL pré-assinada do S3** com curta duração e retornar um redirecionamento `302 Found` para essa URL. Isso desonera o servidor da API.
    5.  Define os cabeçalhos de resposta apropriados.

### 4. Deletar um Arquivo (Metadados e Físico)

*   **Endpoint:** `DELETE /api/v1/files/{storage_object_name}/{file_identifier}`
*   **Descrição:** Remove os metadados de um arquivo e o arquivo físico do armazenamento.
*   **Path Parameters:** `storage_object_name`, `file_identifier` (ID ou remote_id).
*   **Autenticação:** Requer JWT.
*   **Autorização:** Usuário deve ser o `profile_id` que fez o upload ou um administrador.
*   **Resposta de Sucesso (204 No Content).**
*   **Respostas de Erro:** `401 Unauthorized`, `403 Forbidden`, `404 Not Found`.
*   **Lógica do Backend (Exemplo `Deeper.Files.FileDeletionService`):**
    1.  Busca `storage_config`.
    2.  Busca `file_meta` usando `file_identifier`. Verifica propriedade.
    3.  **Inicia Transação DB.**
    4.  `{:ok, deleted_file_size} = FilesRepo.delete_file_metadata(storage_config[\"table_files\"], file_meta[\"id\"])`
    5.  `StorageRepo.update_storage_object_size_and_number(storage_object_name, -deleted_file_size, -1)`
    6.  (Atualizar cotas de usuário se implementado).
    7.  **Commita Transação DB.**
    8.  **Deleta Arquivo Físico:** Chama uma função `PhysicalStorage.delete(storage_config.engine, storage_config.params, file_meta[\"path\"], file_meta[\"remote_id\"])`.
        *   Se a deleção física falhar, logar o erro. A entrada do DB já foi removida. (Pode ser desejável tentar a deleção física primeiro, ou ter um mecanismo de limpeza para arquivos órfãos).

## Considerações Adicionais:

*   **URLs de Arquivos Públicos:** Para `storage_object`s configurados para servir arquivos publicamente (e `private=0` no metadado do arquivo), a `url` retornada pelo endpoint de upload ou metadados deve apontar diretamente para o arquivo (ex: CDN, bucket S3 público, ou um caminho no servidor web que serve estáticos). A API \"Deeper\" não precisaria de um endpoint `GET /access` para esses.
*   **Associação de Arquivos a Conteúdo:**
    *   Após o upload, o `file_id` (ou `remote_id`) retornado é usado pelo cliente para associar o arquivo a uma entidade.
    *   Ex: Ao criar um perfil de pessoa, o cliente faz upload do avatar, obtém o `file_id`, e então envia este `file_id` no corpo da requisição `POST /api/v1/profiles` (ou `POST /api/v1/auth/register`) no campo `picture_file_id`. O backend então atualiza `bx_persons_data.picture` com este ID.
*   **Transcodificação (Futuro):** Se a transcodificação for implementada, o upload de um arquivo de imagem/vídeo poderia disparar um job assíncrono. A API poderia retornar o status da transcodificação ou URLs para as diferentes versões quando prontas.

Estes endpoints fornecem a base para o gerenciamento de arquivos na API \"Deeper\".