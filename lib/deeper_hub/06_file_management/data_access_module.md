# Documentação Deeper: Módulos de Acesso a Dados para Gerenciamento de Arquivos

Este documento descreve os módulos Elixir que interagem com as tabelas de gerenciamento de arquivos: `Deeper.Files.StorageRepo` (para `sys_objects_storage`) e `Deeper.Files.FilesRepo` (para as tabelas de metadados de arquivos como `sys_files`, `bx_persons_pictures`, etc.).

## 1. `Deeper.Files.StorageRepo`

Responsável por ler as configurações dos \"objetos de armazenamento\".

### Funções Principais:

*   **`get_storage_object_config(storage_object_name :: String.t()) :: {:ok, config :: map()} | {:error, :not_found}`**
    *   Busca a configuração completa de `sys_objects_storage` pelo `object` (nome).
    *   SQL: `SELECT * FROM sys_objects_storage WHERE object = ? LIMIT 1;`
    *   O `params` (JSON string) deve ser parseado para um mapa Elixir.
    *   `ext_allow` e `ext_deny` (CSV strings) devem ser parseados para listas.
    *   Pode ser cacheado para performance.

*   **`update_storage_object_size_and_number(storage_object_name :: String.t(), size_delta :: integer(), number_delta :: integer()) :: :ok | {:error, any()}`**
    *   Atualiza `current_size` e `current_number` em `sys_objects_storage`.
    *   SQL: `UPDATE sys_objects_storage SET current_size = current_size + ?, current_number = current_number + ?, ts = ? WHERE object = ?;`
    *   Deve ser chamado atomicamente com a inserção/deleção de metadados de arquivo.

## 2. `Deeper.Files.FilesRepo`

Responsável por operações CRUD nas tabelas de metadados de arquivos (nome da tabela obtido de `sys_objects_storage.table_files`).

### Funções Principais (parametrizadas por `target_files_table_name`):

*   **`create_file_metadata(target_files_table_name :: String.t(), uploader_profile_id :: integer(), file_details :: map()) :: {:ok, file_meta_with_id :: map()} | {:error, any()}`**
    *   `file_details`: `remote_id`, `path`, `file_name`, `mime_type`, `ext`, `size`, `private` (0 ou 1), `dimensions` (opcional), `duration` (opcional).
    *   `added_ts = System.os_time(:second)`, `modified_ts = added_ts`.
    *   SQL: `INSERT INTO #{target_files_table_name} (profile_id, remote_id, path, file_name, mime_type, ext, size, added, modified, private, ...) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ...) RETURNING *;`
    *   Retorna o mapa completo do registro inserido, incluindo o `id` gerado.

*   **`get_file_metadata_by_id(target_files_table_name :: String.t(), file_id :: integer()) :: {:ok, file_meta :: map()} | {:error, :not_found}`**
    *   SQL: `SELECT * FROM #{target_files_table_name} WHERE id = ? LIMIT 1;`

*   **`get_file_metadata_by_remote_id(target_files_table_name :: String.t(), remote_id :: String.t()) :: {:ok, file_meta :: map()} | {:error, :not_found}`**
    *   SQL: `SELECT * FROM #{target_files_table_name} WHERE remote_id = ? LIMIT 1;`

*   **`delete_file_metadata(target_files_table_name :: String.t(), file_id :: integer()) :: {:ok, deleted_file_size :: integer()} | {:error, :not_found | any()}`**
    *   SQL: `DELETE FROM #{target_files_table_name} WHERE id = ? RETURNING size;`
    *   Retorna o tamanho do arquivo deletado para que o `StorageRepo` possa atualizar `current_size`.

*   **`list_files_by_profile_id(target_files_table_name :: String.t(), uploader_profile_id :: integer(), opts :: Keyword.t()) :: {:ok, {files :: list(map()), pagination_meta :: map()}} | {:error, any()}`**
    *   `opts`: `limit`, `offset`, `filter_ext_in` (lista de extensões), `filter_private` (0 ou 1).
    *   SQL (dados): `SELECT * FROM #{target_files_table_name} WHERE profile_id = ? AND (ext IN (?) OR ? IS NULL) AND (private = ? OR ? IS NULL) ORDER BY added DESC LIMIT ? OFFSET ?;`
    *   SQL (contagem): `SELECT COUNT(*) FROM #{target_files_table_name} WHERE profile_id = ? AND (ext IN (?) OR ? IS NULL) AND (private = ? OR ? IS NULL);`

## Lógica de Serviço de Upload (Exemplo Conceitual - `Deeper.Files.FileUploaderService`):

Este serviço coordenaria os repositórios e o armazenamento físico.

*   **`upload_file(storage_object_name :: String.t(), uploader_profile_id :: integer(), uploaded_file_path :: String.t(), original_filename :: String.t(), mime_type :: String.t()) :: {:ok, api_response_map :: map()} | {:error, reason :: atom() | String.t()}`**
    1.  `{:ok, storage_config} = StorageRepo.get_storage_object_config(storage_object_name)`
    2.  **Validações:**
        *   Tamanho do arquivo (`uploaded_file_path`) vs `storage_config.max_file_size`.
        *   Extensão (extraída de `original_filename`) vs `storage_config.ext_allow`/`ext_deny`.
        *   Cotas: `storage_config.current_number + 1 <= storage_config.quota_number` e `storage_config.current_size + file_size <= storage_config.quota_size` (pode precisar de bloqueio para evitar race conditions).
        *   (Validações de cota de usuário em `sys_storage_user_quotas` se implementado).
    3.  `file_ext = Path.extname(original_filename) |> String.trim_leading(\".\")`
    4.  `remote_id = \"#{UUID.uuid4()}.\" <> file_ext` (Exemplo de geração de ID único).
    5.  **Armazena Arquivo Físico:**
        *   Chama uma função interna ou um módulo `Deeper.Files.PhysicalStorage` para salvar o `uploaded_file_path` no `storage_config.engine` (Local, S3, etc.) usando `storage_config.params`. Esta função retorna o `storage_path` (caminho relativo ou identificador).
        *   Ex: `{:ok, storage_path} = PhysicalStorage.store(storage_config.engine, storage_config.params, uploaded_file_path, remote_id)`
    6.  Prepara `file_details_for_db` (remote_id, storage_path, original_filename, mime_type, ext, size, etc.).
    7.  **Inicia Transação DB:**
    8.  `{:ok, file_meta} = FilesRepo.create_file_metadata(storage_config[\"table_files\"], uploader_profile_id, file_details_for_db)`
    9.  `StorageRepo.update_storage_object_size_and_number(storage_object_name, file_meta[\"size\"], 1)`
    10. (Atualizar `sys_storage_user_quotas` se implementado).
    11. **Commita Transação DB.**
    12. Constrói a URL de acesso ao arquivo.
    13. Retorna `{:ok, %{file_id: file_meta[\"id\"], remote_id: remote_id, url: access_url, ...}}`.
    14. Se qualquer passo falhar (especialmente o armazenamento físico), deleta o arquivo físico se já foi salvo e não commita a transação DB.

## Considerações:

*   **Abstração do Armazenamento Físico:** É altamente recomendável usar uma biblioteca como `Waffle` ou construir uma abstração (`PhysicalStorage` com adaptadores para Local, S3, etc.) para lidar com o armazenamento físico real. O `engine` e `params` de `sys_objects_storage` seriam usados para configurar este adaptador.
*   **Segurança SQL Dinâmico:** Ao usar `target_files_table_name` em queries, validar que o nome da tabela é de uma lista permitida (obtida de `sys_objects_storage`) para evitar injeção se a fonte do nome puder ser manipulada.
*   **URLs de Acesso:** A construção da URL final para o cliente acessar o arquivo dependerá se os arquivos são públicos, se estão atrás de um CDN, ou se precisam ser servidos através de um endpoint da API \"Deeper\" que verifica permissões.

Este conjunto de repositórios e serviços forma a base para um sistema de gerenciamento de arquivos robusto na API \"Deeper\".