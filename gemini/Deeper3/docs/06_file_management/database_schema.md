# Documentação Deeper: Esquema do Banco de Dados para Gerenciamento de Arquivos (SQLite)

Este documento define os `CREATE TABLE` statements para SQLite das tabelas relacionadas ao sistema de gerenciamento de arquivos do \"Deeper\", adaptadas do UNA.

## Tabela: `sys_objects_storage`
Define os \"motores\" ou locais de armazenamento. Inicialmente, teremos \"local\".

```sql
CREATE TABLE IF NOT EXISTS sys_objects_storage (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  object TEXT NOT NULL UNIQUE, -- Nome único do objeto de armazenamento, ex: 'local_files', 's3_bucket_main'
  engine TEXT NOT NULL, -- Tipo de motor, ex: 'Local', 'S3', 'GoogleCloud'
  params TEXT, -- Parâmetros de configuração em JSON, ex: '{\"path_prefix\": \"/srv/uploads/deeper\"}' para Local
  token_life INTEGER NOT NULL DEFAULT 3600, -- Tempo de vida de tokens de acesso (em segundos)
  levels INTEGER NOT NULL DEFAULT 0, -- Níveis de subdiretório para organizar arquivos (0 = sem subdiretórios baseados em hash)
  table_files TEXT NOT NULL, -- Nome da tabela de arquivos principal associada a este storage (ex: 'sys_files')
  -- ext_mode, ext_allow, ext_deny: Para restrições de extensão (pode ser gerenciado na aplicação)
  quota_size INTEGER NOT NULL DEFAULT 0, -- Cota total do storage em bytes (0 = ilimitado)
  current_size INTEGER NOT NULL DEFAULT 0,
  quota_number INTEGER NOT NULL DEFAULT 0, -- Cota de número de arquivos (0 = ilimitado)
  current_number INTEGER NOT NULL DEFAULT 0,
  max_file_size INTEGER NOT NULL DEFAULT 0, -- Tamanho máximo de arquivo permitido em bytes (0 = ilimitado)
  ts INTEGER NOT NULL -- Timestamp da última atualização/verificação
);
```

```sql
CREATE TABLE IF NOT EXISTS deeper_files (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  profile_id INTEGER NOT NULL, -- ID do perfil do usuário que fez o upload
  storage_object TEXT NOT NULL, -- Referência ao 'object' da sys_objects_storage
  remote_id TEXT NOT NULL, -- Identificador único do arquivo no sistema de armazenamento (ex: nome do arquivo com hash ou UUID)
  path TEXT, -- Caminho relativo dentro do storage_object (se aplicável, útil para 'Local' engine)
  file_name TEXT NOT NULL, -- Nome original do arquivo enviado pelo usuário
  mime_type TEXT NOT NULL,
  ext TEXT NOT NULL, -- Extensão do arquivo
  size INTEGER NOT NULL, -- Tamanho do arquivo em bytes
  added INTEGER NOT NULL, -- Unix Timestamp do upload
  modified INTEGER NOT NULL, -- Unix Timestamp da última modificação dos metadados
  is_private INTEGER NOT NULL DEFAULT 0, -- 0 para público, 1 para privado
  -- Campos específicos para imagens (opcional, podem ser JSON em 'meta' ou colunas separadas)
  img_width INTEGER,
  img_height INTEGER,
  -- Campo genérico para metadados adicionais
  meta TEXT, -- JSON para metadados diversos (ex: dimensões de imagem, duração de vídeo)
  FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE SET NULL, -- Ou ON DELETE CASCADE dependendo da política
  FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object)
);

CREATE INDEX IF NOT EXISTS idx_deeper_files_profile_id ON deeper_files(profile_id);
CREATE INDEX IF NOT EXISTS idx_deeper_files_storage_object_remote_id ON deeper_files(storage_object, remote_id);
CREATE INDEX IF NOT EXISTS idx_deeper_files_mime_type ON deeper_files(mime_type);
CREATE INDEX IF NOT EXISTS idx_deeper_files_added ON deeper_files(added);
```

```sql
CREATE TABLE IF NOT EXISTS sys_storage_tokens (
  id INTEGER PRIMARY KEY AUTOINCREMENT, -- iid no original
  file_id INTEGER NOT NULL, -- file_id no original (referência a deeper_files.id)
  storage_object TEXT NOT NULL, -- object no original
  hash TEXT NOT NULL UNIQUE, -- Token de acesso
  created INTEGER NOT NULL, -- Unix Timestamp da criação do token
  FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE,
  FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object)
);

CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_hash ON sys_storage_tokens(hash);
CREATE INDEX IF NOT EXISTS idx_sys_storage_tokens_created ON sys_storage_tokens(created);
```

```sql
    CREATE TABLE IF NOT EXISTS sys_storage_ghosts (
      id INTEGER PRIMARY KEY AUTOINCREMENT, -- iid no original
      file_real_id INTEGER NOT NULL, -- id no original (o ID que o arquivo TERIA em deeper_files)
      profile_id INTEGER NOT NULL,
      storage_object TEXT NOT NULL, -- object no original
      content_id INTEGER, -- ID do conteúdo ao qual este arquivo fantasma está associado (ex: ID de um post)
      created INTEGER NOT NULL,
      order_in_content INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE,
      FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object)
    );
```

```sql
    CREATE TABLE IF NOT EXISTS sys_storage_user_quotas (
      profile_id INTEGER PRIMARY KEY,
      current_size INTEGER NOT NULL DEFAULT 0, -- Tamanho total usado em bytes
      current_number INTEGER NOT NULL DEFAULT 0, -- Número total de arquivos
      ts INTEGER NOT NULL, -- Timestamp da última atualização
      FOREIGN KEY (profile_id) REFERENCES sys_profiles(id) ON DELETE CASCADE
    );
```

```sql
    CREATE TABLE IF NOT EXISTS sys_storage_mime_types (
      ext TEXT PRIMARY KEY,
      mime_type TEXT NOT NULL,
      icon TEXT, -- Nome do ícone ou classe CSS
      icon_font TEXT -- Fonte do ícone, se aplicável
    );
    CREATE INDEX IF NOT EXISTS idx_sys_storage_mime_types_mime_type ON sys_storage_mime_types(mime_type);
```

```sql
    CREATE TABLE IF NOT EXISTS sys_storage_deletions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      storage_object TEXT NOT NULL,
      file_id INTEGER NOT NULL, -- ID do arquivo em deeper_files
      requested INTEGER NOT NULL, -- Unix Timestamp da solicitação de exclusão
      FOREIGN KEY (storage_object) REFERENCES sys_objects_storage(object),
      FOREIGN KEY (file_id) REFERENCES deeper_files(id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS idx_sys_storage_deletions_requested ON sys_storage_deletions(requested);
```

*   **`object`**: Identificador único do storage.
*   **`engine`**: Tipo de armazenamento (Local, S3, etc.).
*   **`params`**: Configurações específicas do engine (JSON).
*   **`token_life`**: Duração de tokens para acesso a arquivos.
*   **`table_files`**: Tabela de metadados de arquivos (ex: `deeper_files`) que usa este storage.
*   As demais colunas são para cotas e restrições, que podem ser implementadas progressivamente.

## Tabela: `deeper_files` (Substituindo `sys_files`, `sys_images`, etc. para simplificação inicial)
Tabela principal para metadados de todos os arquivos.

*   **`profile_id`**: Quem fez o upload.
*   **`storage_object`**: Qual `sys_objects_storage` está sendo usado.
*   **`remote_id`**: ID único do arquivo no storage (ex: `uuid.jpg`).
*   **`path`**: Caminho no storage (se o engine `Local` organizar em subdiretórios).
*   **`file_name`**: Nome original para exibição.
*   **`mime_type`, `ext`, `size`**: Metadados básicos.
*   **`added`, `modified`**: Timestamps.
*   **`is_private`**: Controle de acesso.
*   **`img_width`, `img_height`**: Específico para imagens.
*   **`meta`**: Campo JSON para metadados extras.

## Tabela: `sys_storage_tokens` (Para acesso seguro a arquivos)

*   Usada para gerar tokens de acesso de curta duração para arquivos, especialmente os privados.

## Tabelas Opcionais / Implementação Futura:

As seguintes tabelas do UNA podem ser implementadas posteriormente, conforme a necessidade de funcionalidades mais avançadas:

*   **`sys_storage_ghosts`**: Para rastrear referências a arquivos que ainda não foram processados ou que podem estar ausentes.

*   **`sys_storage_user_quotas`**: Para cotas de armazenamento por usuário.

*   **`sys_storage_mime_types`**: Mapeamento de extensões para tipos MIME e ícones (útil para a UI).

*   **`sys_storage_deletions`**: Fila para marcar arquivos para exclusão assíncrona.

**Simplificação Inicial:** Para a primeira fase, focaremos em `sys_objects_storage` e `deeper_files`. `sys_storage_tokens` será importante se implementarmos acesso privado a arquivos via token. As demais são para funcionalidades mais avançadas.