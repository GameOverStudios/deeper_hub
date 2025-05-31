# Documentação Deeper: Gerenciamento de Arquivos da API

Este diretório detalha como a API \"Deeper\" lidará com o upload, armazenamento, recuperação e gerenciamento de arquivos, espelhando e adaptando as funcionalidades do sistema de armazenamento do UNA.

**Objetivo Principal:**

*   Fornecer endpoints seguros para upload de arquivos (ex: imagens, vídeos, documentos).
*   Permitir que a API associe arquivos a diferentes tipos de conteúdo (ex: avatares a perfis, anexos a posts).
*   Fornecer URLs para acessar os arquivos armazenados (potencialmente através de um CDN ou diretamente do servidor de API, dependendo da arquitetura).
*   Gerenciar metadados de arquivos.
*   (Opcional, futuro) Lidar com transcodificação de imagens/vídeos.

## Componentes Principais do UNA para Arquivos e Armazenamento:

1.  **`sys_objects_storage`**:
    *   Define diferentes \"objetos de armazenamento\" ou \"engines\" (ex: Local, S3, etc.).
    *   Campos: `object` (nome do storage object), `engine`, `params` (configurações do engine), `token_life`, `table_files` (nome da tabela SQL que armazena os metadados dos arquivos para este storage object), `ext_mode` (`allow-deny`, `deny-allow`), `ext_allow`, `ext_deny`, `quota_size`, `max_file_size`.

2.  **Tabelas de Arquivos (específicas por `sys_objects_storage.table_files`):**
    *   O UNA permite que cada \"storage object\" tenha sua própria tabela de metadados de arquivos. Exemplos comuns incluem:
        *   `sys_files` (um storage genérico).
        *   `bx_persons_pictures` (para fotos de perfil, já coberto).
        *   `sys_images_editor` (para imagens do editor de texto).
    *   Estas tabelas geralmente contêm: `id` (PK), `profile_id` (quem fez o upload), `remote_id` (identificador único no storage físico, ex: nome do arquivo no S3 ou caminho completo), `path`, `file_name`, `mime_type`, `ext`, `size`, `added`, `modified`, `private`.

3.  **`sys_storage_ghosts`**: Usado para rastrear arquivos que foram associados a um conteúdo, mas o conteúdo ainda não foi salvo permanentemente (ex: imagens carregadas em um formulário antes de submeter).
4.  **`sys_storage_tokens`**: Para gerar tokens de acesso temporário a arquivos privados.
5.  **`sys_objects_transcoder` e tabelas relacionadas (`sys_transcoder_filters`, `sys_transcoder_images_files`, etc.):**
    *   Lidam com o redimensionamento e processamento de imagens e vídeos.
    *   Para a API \"Deeper\" inicial, podemos simplificar a transcodificação ou adiá-la, focando no upload e recuperação do arquivo original. O cliente pode ser responsável por redimensionar imagens no frontend para certos casos, ou a API pode oferecer apenas alguns tamanhos pré-definidos.

## Estratégia da API \"Deeper\" para Gerenciamento de Arquivos:

A API \"Deeper\" precisará de:
*   Um endpoint genérico para upload de arquivos, que pode ser parametrizado pelo `storage_object_name` do UNA.
*   Mecanismos para associar os `file_id`s (ou `remote_id`s) retornados pelo upload a entidades específicas (ex: atualizar `bx_persons_data.picture` com o ID do arquivo).
*   Uma forma de servir/fornecer URLs para os arquivos.

### Módulo de Acesso a Dados (`Deeper.Files.StorageRepo` e `Deeper.Files.FilesRepo`):

*   **`Deeper.Files.StorageRepo`**: Lida com a tabela `sys_objects_storage`.
    *   **`get_storage_object_config(storage_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
        *   Busca a configuração de `sys_objects_storage`.
        *   SQL: `SELECT * FROM sys_objects_storage WHERE object = ? LIMIT 1;`

*   **`Deeper.Files.FilesRepo`**: Lida com as tabelas de arquivos específicas (ex: `sys_files`, `bx_persons_pictures`).
    *   Precisará ser parametrizável pelo `table_name` obtido da configuração do storage object.
    *   **`store_file_metadata(storage_object_name, uploader_profile_id, file_details :: map()) :: {:ok, file_meta :: map()} | {:error, any()}`**
        *   `file_details`: `remote_id`, `path`, `file_name`, `mime_type`, `ext`, `size`, `private`.
        1.  Busca `config` de `StorageRepo.get_storage_object_config`.
        2.  `target_files_table = config[\"table_files\"]`.
        3.  Valida `ext` contra `config.ext_allow`/`ext_deny` e `size` contra `config.max_file_size`.
        4.  Insere metadados na `target_files_table`.
            *   SQL: `INSERT INTO #{target_files_table} (profile_id, remote_id, path, file_name, ...) VALUES (?, ?, ?, ?, ...) RETURNING *;`
        5.  Retorna os metadados salvos (incluindo o `id` da tabela de arquivos).

    *   **`get_file_metadata(storage_object_name, file_id_or_remote_id :: String.t() | integer()) :: {:ok, file_meta :: map()} | {:error, :not_found}`**
        1.  Busca `config`. `target_files_table = config[\"table_files\"]`.
        2.  SQL: `SELECT * FROM #{target_files_table} WHERE id = ? OR remote_id = ? LIMIT 1;`

    *   **`delete_file_metadata(storage_object_name, file_id_or_remote_id)`** (e o arquivo físico)

### Lógica de Upload no Controller da API:

1.  Recebe a requisição `multipart/form-data`.
2.  Identifica o `storage_object_name` (pode ser parte da rota ou um parâmetro).
3.  Chama `StorageRepo.get_storage_object_config` para obter as regras (extensões permitidas, tamanho máximo).
4.  Valida o arquivo contra essas regras.
5.  **Armazena o Arquivo Físico:**
    *   Se `engine == \"Local\"`: Salva o arquivo no sistema de arquivos do servidor \"Deeper\" em um caminho configurado. Gera um `remote_id` (ex: UUID + extensão) e `path`.
    *   Se `engine == \"S3\"` (ou similar): Faz upload para o S3 usando uma biblioteca Elixir S3. O `remote_id` pode ser a chave S3.
    *   Outros engines seriam tratados de forma similar.
6.  Após o armazenamento físico bem-sucedido, chama `FilesRepo.store_file_metadata` para salvar os metadados.
7.  Retorna os metadados do arquivo (incluindo seu `id` e uma URL de acesso).

### Endpoints da API (`/api/v1/files`):

*   **Upload de Arquivo Genérico:**
    *   **Endpoint:** `POST /api/v1/files/upload/{storage_object_name}`
    *   **Path Parameter:** `storage_object_name` (ex: `bx_persons_pictures_uploads`, `sys_files_general`). Este `storage_object_name` deve existir em `sys_objects_storage`.
    *   **Autenticação:** Requer JWT. O `uploader_profile_id` vem do token.
    *   **Corpo da Requisição:** `multipart/form-data` com um campo `file`.
    *   **Resposta de Sucesso (201 Created):**

```json
        {
          \"data\": {
            \"file_id\": 567, // ID da tabela de metadados (ex: bx_persons_pictures.id)
            \"remote_id\": \"uuid-generated-filename.jpg\",
            \"file_name\": \"original_filename.jpg\",
            \"url\": \"https://cdn.example.com/path/to/uuid-generated-filename.jpg\", // URL de acesso
            \"mime_type\": \"image/jpeg\",
            \"size\": 102400 // bytes
          }
        }
```

```sql
    CREATE TABLE IF NOT EXISTS sys_objects_storage (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      object TEXT NOT NULL UNIQUE, -- Nome do storage object
      engine TEXT NOT NULL, -- 'Local', 'S3', etc.
      params TEXT, -- Configurações do engine (JSON ou string serializada)
      token_life INTEGER NOT NULL DEFAULT 3600, -- Para URLs temporárias
      cache_control INTEGER NOT NULL DEFAULT 2592000, -- Cache-Control header value
      levels INTEGER NOT NULL DEFAULT 0, -- Níveis de subdiretório para engine 'Local'
      table_files TEXT NOT NULL, -- Nome da tabela de metadados dos arquivos
      ext_mode TEXT NOT NULL DEFAULT 'allow-deny' CHECK(ext_mode IN ('allow-deny', 'deny-allow')),
      ext_allow TEXT DEFAULT 'jpg,jpeg,jpe,gif,png,webp,mp4,mp3,pdf,doc,docx,xls,xlsx,zip',
      ext_deny TEXT DEFAULT '',
      quota_size INTEGER NOT NULL DEFAULT 0, -- Quota total em bytes (0 = ilimitado)
      current_size INTEGER NOT NULL DEFAULT 0,
      quota_number INTEGER NOT NULL DEFAULT 0, -- Número máximo de arquivos (0 = ilimitado)
      current_number INTEGER NOT NULL DEFAULT 0,
      max_file_size INTEGER NOT NULL DEFAULT 0, -- Tamanho máximo por arquivo em bytes (0 = ilimitado)
      ts INTEGER NOT NULL DEFAULT 0 -- Timestamp da última atualização de current_size/number
    );
```

```sql
    CREATE TABLE IF NOT EXISTS sys_files ( -- Ou qualquer nome definido em sys_objects_storage.table_files
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      profile_id INTEGER NOT NULL, -- sys_profiles.id do uploader
      remote_id TEXT NOT NULL UNIQUE, -- Identificador no storage físico
      path TEXT NOT NULL, -- Caminho relativo ou identificador de bucket/folder
      file_name TEXT NOT NULL, -- Nome original do arquivo
      mime_type TEXT NOT NULL,
      ext TEXT NOT NULL,
      size INTEGER NOT NULL, -- Em bytes
      added INTEGER NOT NULL, -- Unix Timestamp
      modified INTEGER NOT NULL, -- Unix Timestamp
      private INTEGER NOT NULL DEFAULT 0 -- 0=público, 1=privado
    );
    CREATE INDEX IF NOT EXISTS idx_sys_files_profile_id ON sys_files(profile_id);
    CREATE INDEX IF NOT EXISTS idx_sys_files_remote_id ON sys_files(remote_id);
```

    *   A `url` retornada é crucial. Pode ser uma URL direta para um CDN, ou uma URL para um endpoint da API \"Deeper\" que serve o arquivo (especialmente para arquivos privados).

*   **Obter Metadados de um Arquivo (para Admins ou se o arquivo for público):**
    *   **Endpoint:** `GET /api/v1/files/{storage_object_name}/meta/{file_id_or_remote_id}`
    *   **Autenticação:** Requer JWT. Autorização para ver metadados.
    *   **Resposta:** JSON com os metadados da tabela de arquivos.

*   **Servir Arquivos Privados (se não usar URLs assinadas de S3/CDN):**
    *   **Endpoint:** `GET /api/v1/files/{storage_object_name}/access/{file_id_or_remote_id}`
    *   **Autenticação:** Requer JWT.
    *   **Lógica:**
        1.  Busca metadados do arquivo usando `FilesRepo.get_file_metadata`.
        2.  Verifica `private`. Se privado, verifica se o usuário tem permissão para acessar (lógica complexa, pode envolver verificar a entidade à qual o arquivo está associado).
        3.  Se permitido, lê o arquivo do storage físico e o transmite como resposta.
        4.  Define cabeçalhos `Content-Type`, `Content-Disposition` apropriados.
    *   Alternativa para arquivos privados em S3/Cloud: gerar uma URL pré-assinada com tempo de expiração limitado e redirecionar o cliente para ela.

## Tabelas de Gerenciamento de Arquivos (Esquema SQLite):

*   **`sys_objects_storage` (Configuração):**

*   **Exemplo de Tabela de Arquivos Genérica (`sys_files` - referenciada por `sys_objects_storage.table_files`):**

    *   Tabelas como `bx_persons_pictures` são instâncias especializadas desta estrutura.

## Considerações:

*   **Segurança de Upload:** Validação rigorosa de `mime_type`, `ext`, e `size` é crucial. Para arquivos executáveis ou HTML, precauções extras são necessárias.
*   **Armazenamento Físico:** A lógica para interagir com o sistema de arquivos local, S3, ou outros backends de storage precisa ser modular. Uma biblioteca como `Waffle` (Elixir) pode ajudar a abstrair isso.
*   **URLs de Acesso:** Determinar como as URLs dos arquivos serão construídas. Se os arquivos forem públicos, podem ser servidos diretamente por um CDN ou Nginx. Se privados, a API \"Deeper\" precisará de um endpoint para servir o arquivo após verificação de permissão, ou gerar URLs assinadas.
*   **Transcodificação (Futuro):** O sistema de `sys_objects_transcoder` do UNA é complexo. Para uma primeira versão da API \"Deeper\", a transcodificação pode ser simplificada ou adiada. Se implementada, o upload de um arquivo pode disparar um job de transcodificação assíncrono.
*   **Cotas (`sys_objects_storage.quota_size`, `sys_storage_user_quotas`):** A API de upload precisará verificar e atualizar as cotas do usuário e do storage object.

Este sistema de arquivos é um pilar para muitas funcionalidades e requer atenção cuidadosa à segurança e à integração com diferentes backends de armazenamento.