# Documentação Deeper: Esquema do BD para Gerenciamento de Arquivos (SQLite)

Define `CREATE TABLE` para as tabelas do sistema de gerenciamento de arquivos.

## Tabela: `sys_objects_storage` (Adaptada para Configurações de Storage do Deeper)

Esta tabela do UNA define motores de armazenamento. Para \"Deeper\", podemos simplificá-la ou usá-la para armazenar configurações de diferentes \"backends\" de armazenamento (ex: 'local_public', 'local_private', 's3_bucket_xyz').

```sql
CREATE TABLE IF NOT EXISTS deeper_storage_backends (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  storage_name TEXT NOT NULL UNIQUE, -- Nome único do backend (ex: 'local_default', 's3_main')
  engine TEXT NOT NULL CHECK(engine IN ('Local', 'S3', 'Other')), -- Tipo de motor
  params TEXT, -- Configurações em JSON (ex: path para Local, bucket/credenciais para S3)
  base_url TEXT, -- URL base pública para arquivos neste storage (se aplicável)
  is_default INTEGER NOT NULL DEFAULT 0,
  active INTEGER NOT NULL DEFAULT 1
);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- Ou TEXT para UUIDs gerados pela aplicação
  uploader_profile_id INTEGER NOT NULL, -- FK para sys_profiles.id
  storage_backend_name TEXT NOT NULL, -- FK (lógica) para deeper_storage_backends.storage_name
  original_filename TEXT NOT NULL,
  stored_filename TEXT NOT NULL UNIQUE, -- Nome único do arquivo no backend de armazenamento
  stored_path TEXT, -- Caminho relativo dentro do backend de armazenamento (ex: 'user_uploads/2023/10/')
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  extension TEXT,
  -- Meta dados específicos do tipo de arquivo (ex: dimensões para imagem, duração para áudio/vídeo)
  meta_data TEXT, -- Armazenado como JSON
  is_private INTEGER NOT NULL DEFAULT 0, -- 0 para público, 1 para privado
  -- Campos para relacionar o arquivo a uma entidade específica (opcional, mas útil)
  -- entity_system_name TEXT, -- Ex: 'deeper_articles', 'bx_persons_avatar'
  -- entity_object_id INTEGER,
  -- entity_field_name TEXT, -- Ex: 'featured_image', 'profile_picture'
  created_at INTEGER NOT NULL, -- Unix Timestamp
  updated_at INTEGER NOT NULL,
  FOREIGN KEY (uploader_profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL ON UPDATE CASCADE
  -- FOREIGN KEY (storage_backend_name) REFERENCES deeper_storage_backends(storage_name) ON UPDATE CASCADE -- Lógica
);

CREATE INDEX IF NOT EXISTS idx_df_uploader_id ON deeper_files(uploader_profile_id);
CREATE INDEX IF NOT EXISTS idx_df_storage_filename ON deeper_files(storage_backend_name, stored_path, stored_filename);
-- CREATE INDEX IF NOT EXISTS idx_df_entity_link ON deeper_files(entity_system_name, entity_object_id, entity_field_name); -- Se usar campos de entidade
```

```sql
CREATE TABLE IF NOT EXISTS deeper_file_versions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  original_file_id INTEGER NOT NULL, -- FK para deeper_files.id
  version_profile_name TEXT NOT NULL, -- Nome do perfil de transformação (ex: 'thumbnail_small', 'video_480p')
  storage_backend_name TEXT NOT NULL,
  stored_filename TEXT NOT NULL,
  stored_path TEXT,
  mime_type TEXT NOT NULL,
  size_bytes INTEGER NOT NULL,
  meta_data TEXT, -- JSON para dimensões, etc. da versão
  created_at INTEGER NOT NULL,
  UNIQUE (original_file_id, version_profile_name),
  FOREIGN KEY (original_file_id) REFERENCES deeper_files(id) ON DELETE CASCADE ON UPDATE CASCADE
  -- FOREIGN KEY (storage_backend_name) REFERENCES deeper_storage_backends(storage_name) ...
);

CREATE INDEX IF NOT EXISTS idx_dfv_original_file ON deeper_file_versions(original_file_id);
```

*   **`storage_name`**: Identificador usado pela aplicação.
*   **`engine`**: Especifica o tipo de driver de armazenamento a ser usado.
*   **`params`**: Configurações específicas do engine (ex: diretório raiz para 'Local', credenciais e bucket para 'S3').
*   **`base_url`**: Se os arquivos podem ser acessados diretamente via uma URL base.

## Tabela: `deeper_files` (Tabela Unificada de Metadados de Arquivos)

*   **`id`**: Pode ser um UUID gerado pela aplicação para servir como nome de arquivo público, ou um auto-incremento se `stored_filename` for o identificador público.
*   **`storage_backend_name`**: Indica qual configuração de `deeper_storage_backends` foi usada.
*   **`stored_filename`**: Nome do arquivo como está no sistema de arquivos/S3 (geralmente um hash ou UUID para evitar conflitos e não expor o nome original).
*   **`stored_path`**: Subdiretório no storage (ex: `avatars/`, `attachments/2023/10/`).
*   **`meta_data`**: JSON para armazenar dimensões de imagem, hash do arquivo, etc.
*   **`is_private`**: Controla o acesso.

## Tabela: `deeper_file_versions` (Para Versões/Transformações, ex: Thumbnails)

Se o sistema precisar de múltiplas versões de um arquivo (ex: thumbnails de imagem, diferentes qualidades de vídeo), esta tabela pode rastreá-las.

*   **`version_profile_name`**: Identifica o tipo de transformação (ex: \"avatar_thumb\", \"preview_large\").
*   Esta tabela é mais relevante se houver um sistema de transcodificação (`08_advanced_features/sys_transcoding_api.md`). Para redimensionamento simples de imagem no upload, os metadados dos thumbnails podem ser armazenados no `meta_data` do arquivo original em `deeper_files`.