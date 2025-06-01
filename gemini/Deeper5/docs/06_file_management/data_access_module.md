# Documentação Deeper: Módulos de Acesso a Dados para Gerenciamento de Arquivos

Este documento descreve os módulos Elixir responsáveis pela interação com o sistema de armazenamento de arquivos e o gerenciamento de seus metadados:
1.  `Deeper.FileManagement.StorageManager` (e seus adaptadores): Lida com a interação física com os backends de armazenamento (local, S3, etc.).
2.  `Deeper.FileManagement.FileRepo`: Lida com os metadados dos arquivos armazenados na tabela `deeper_files` e, opcionalmente, `deeper_file_versions` e `deeper_storage_backends`.

---

## 1. `Deeper.FileManagement.StorageManager` (Behaviour e Adaptadores)

Este não é um \"Repo\" no sentido tradicional de acesso ao DB, mas sim um conjunto de módulos que implementam um comportamento (behaviour) comum para interagir com diferentes sistemas de armazenamento.

**Localização do Código:**
*   Behaviour: `lib/deeper/file_management/storage_manager.ex`
*   Adaptadores: `lib/deeper/file_management/storage_adapters/local.ex`, `lib/deeper/file_management/storage_adapters/s3.ex`, etc.

### Behaviour: `Deeper.FileManagement.StorageManager`

```elixir
defmodule Deeper.FileManagement.StorageManager do
  @moduledoc \"\"\"
  Behaviour para adaptadores de armazenamento de arquivos.
  Cada backend de armazenamento (Local, S3, etc.) implementará este comportamento.
  \"\"\"

  @typedoc \"Configurações específicas para um backend de armazenamento.\"
  @type storage_config :: map() # Ex: %{engine: \"Local\", params: %{base_path: \"/srv/uploads\"}, base_url: \"/uploads\"}

  @typedoc \"Metadados do arquivo a ser salvo ou que foi salvo.\"
  @type file_meta :: %{
    original_filename: String.t(),
    stored_filename: String.t(), # Nome único gerado para armazenamento
    stored_path: String.t(),     # Caminho relativo no storage
    content_type: String.t(),
    size_bytes: integer(),
    temp_path: String.t()        # Caminho temporário do arquivo upado (para 'Local' e 'S3' upload)
  }

  @doc \"Inicializa o adaptador com sua configuração específica.\"
  @callback init(config :: storage_config()) :: {:ok, state :: term()} | {:error, any()}

  @doc \"Armazena um arquivo a partir de um caminho temporário.\"
  @callback store_file(state :: term(), file_meta :: file_meta()) ::
              {:ok, stored_file_meta :: file_meta()} | {:error, any()}
              # stored_file_meta pode ter campos adicionais como ETag (S3) ou full_path.

  @doc \"Recupera um arquivo. Pode retornar um stream ou um caminho local para o arquivo.\"
  @callback retrieve_file(state :: term(), stored_path :: String.t(), stored_filename :: String.t()) ::
              {:ok, Enumerable.t() | %{path: String.t()}} | {:error, :not_found | any()}

  @doc \"Deleta um arquivo do armazenamento.\"
  @callback delete_file(state :: term(), stored_path :: String.t(), stored_filename :: String.t()) ::
              :ok | {:error, any()}

  @doc \"Gera uma URL pública para um arquivo (se o storage suportar e o arquivo for público).\"
  @callback get_public_url(state :: term(), stored_path :: String.t(), stored_filename :: String.t()) ::
              {:ok, String.t()} | {:error, :not_available | any()}

  @doc \"Gera uma URL assinada (presigned URL) para acesso temporário a arquivos privados (especialmente S3).\"
  @callback get_presigned_url(state :: term(), stored_path :: String.t(), stored_filename :: String.t(), expires_in_seconds :: integer()) ::
              {:ok, String.t()} | {:error, :not_available | any()}
end
```

```elixir
defmodule Deeper.FileManagement.StorageAdapters.Local do
  @behaviour Deeper.FileManagement.StorageManager

  alias Deeper.FileManagement.StorageManager # Para os @type

  defstruct [:base_path, :base_url] # Estado do adaptador

  @impl Deeper.FileManagement.StorageManager
  def init(config) do
    params = Map.get(config, :params, %{})
    base_path = Map.get(params, :base_path)
    base_url = Map.get(config, :base_url, \"\") # URL base para arquivos públicos

    if is_nil(base_path) do
      {:error, \"Local storage :base_path não configurado.\"}
    else
      File.mkdir_p!(base_path) # Garante que o diretório base exista
      {:ok, %__MODULE__{base_path: base_path, base_url: base_url}}
    end
  end

  @impl Deeper.FileManagement.StorageManager
  def store_file(state, file_meta) do
    destination_folder = Path.join(state.base_path, file_meta.stored_path)
    File.mkdir_p!(destination_folder) # Garante que o subdiretório exista
    destination_path = Path.join(destination_folder, file_meta.stored_filename)

    case File.cp(file_meta.temp_path, destination_path) do
      :ok -> {:ok, Map.put(file_meta, :full_storage_path, destination_path)}
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Deeper.FileManagement.StorageManager
  def retrieve_file(state, stored_path, stored_filename) do
    full_path = Path.join([state.base_path, stored_path, stored_filename])
    if File.exists?(full_path) do
      # Poderia retornar um stream: {:ok, File.stream!(full_path, [], 65536)}
      # Ou apenas o caminho para o controller lidar:
      {:ok, %{path: full_path}}
    else
      {:error, :not_found}
    end
  end

  @impl Deeper.FileManagement.StorageManager
  def delete_file(state, stored_path, stored_filename) do
    full_path = Path.join([state.base_path, stored_path, stored_filename])
    case File.rm(full_path) do
      :ok -> :ok
      {:error, :enoent} -> :ok # Arquivo já não existe, considerar sucesso
      {:error, reason} -> {:error, reason}
    end
  end

  @impl Deeper.FileManagement.StorageManager
  def get_public_url(state, stored_path, stored_filename) do
    # Concatena base_url com o caminho relativo e nome do arquivo
    # Ex: /uploads/user_uploads/2023/10/unique_name.jpg
    # O cliente/frontend precisará adicionar o host da API se for uma URL relativa.
    # Se base_url for uma URL completa (https://cdn.example.com), então tudo bem.
    url_path = Path.join([stored_path, stored_filename]) |> String.trim_leading(\"/\")
    full_url = Path.join(state.base_url, url_path)
    {:ok, full_url}
  end

  @impl Deeper.FileManagement.StorageManager
  def get_presigned_url(_state, _stored_path, _stored_filename, _expires_in_seconds) do
    # Armazenamento local não suporta URLs pré-assinadas nativamente da mesma forma que S3.
    # O acesso a arquivos privados locais seria via um endpoint da API que verifica permissões
    # e depois serve o arquivo.
    {:error, :not_available}
  end
end
```

```elixir
defmodule Deeper.FileManagement.FileRepo do
  alias Deeper.Core.Data.Repo

  # --- Funções para Storage Backends (deeper_storage_backends) ---

  @doc \"Busca uma configuração de storage backend pelo nome.\"
  @spec get_storage_backend_config(storage_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_storage_backend_config(storage_name) do
    sql = \"SELECT storage_name, engine, params, base_url FROM deeper_storage_backends WHERE storage_name = ? AND active = 1 LIMIT 1\"
    case Repo.query(sql, [storage_name]) do
      {:ok, %{rows: [row_data], columns: cols}} ->
        config = map_row_to_generic_struct(row_data, cols)
        # Parsear params de JSON para mapa Elixir
        params_map =
          case Map.get(config, \"params\") || Map.get(config, :params) do
            nil -> %{}
            json_str when is_binary(json_str) -> Jason.decode(json_str) |> elem(1) # Assume :ok
            map when is_map(map) -> map # Se já for mapa (improvável do DB direto)
          end
        {:ok, Map.put(config, :params, params_map)} # Usa :params como atom
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Busca a configuração do storage backend padrão.\"
  @spec get_default_storage_backend_config() :: {:ok, map()} | {:error, :not_found | any()}
  def get_default_storage_backend_config() do
    sql = \"SELECT storage_name, engine, params, base_url FROM deeper_storage_backends WHERE is_default = 1 AND active = 1 LIMIT 1\"
    # Lógica similar a get_storage_backend_config para parsear params
    # ... (implementação omitida por brevidade, mas seguiria o padrão acima) ...
    # Se não houver default, pode buscar o primeiro ativo ou retornar erro.
    case Repo.query(sql, []) do
      {:ok, %{rows: [row_data], columns: cols}} -> # ... (parse params) ...
        config = map_row_to_generic_struct(row_data, cols)
        params_map = Jason.decode(config[\"params\"] || config[:params] || \"{}\", []) |> elem(1)
        {:ok, Map.put(config, :params, params_map)}
      _ -> {:error, :no_default_storage_found}
    end
  end

  # --- Funções CRUD para Arquivos (deeper_files) ---

  @doc \"Registra os metadados de um arquivo no banco de dados.\"
  @spec create_file_record(params :: map()) :: {:ok, map()} | {:error, any()}
  def create_file_record(params) do
    # params: :uploader_profile_id, :storage_backend_name, :original_filename,
    #         :stored_filename, :stored_path, :mime_type, :size_bytes, :extension,
    #         :meta_data (mapa, será convertido para JSON), :is_private (opc)
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    meta_data_json = if params[:meta_data], do: Jason.encode!(params[:meta_data]), else: nil

    sql = \"\"\"
    INSERT INTO deeper_files (
      uploader_profile_id, storage_backend_name, original_filename, stored_filename,
      stored_path, mime_type, size_bytes, extension, meta_data, is_private,
      created_at, updated_at
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    RETURNING *;
    \"\"\"
    values = [
      params[:uploader_profile_id], params[:storage_backend_name], params[:original_filename], params[:stored_filename],
      params[:stored_path], params[:mime_type], params[:size_bytes], params[:extension],
      meta_data_json, params[:is_private] || 0,
      current_timestamp, current_timestamp
    ]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row_data], columns: cols}} ->
        file_map = map_row_to_generic_struct(row_data, cols)
        {:ok, Map.update(file_map, \"meta_data\", nil, &parse_json_string/1)}
      err -> err # Tratar erro de stored_filename UNIQUE
    end
  end

  @doc \"Busca metadados de um arquivo pelo seu ID.\"
  @spec get_file_record_by_id(id :: integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_file_record_by_id(id) do
    sql = \"SELECT * FROM deeper_files WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row_data], columns: cols}} ->
        file_map = map_row_to_generic_struct(row_data, cols)
        {:ok, Map.update(file_map, \"meta_data\", nil, &parse_json_string/1)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Busca metadados de um arquivo pelo stored_filename e storage_backend_name.\"
  @spec get_file_record_by_stored_name(storage_backend_name :: String.t(), stored_filename :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_file_record_by_stored_name(storage_backend_name, stored_filename) do
    sql = \"SELECT * FROM deeper_files WHERE storage_backend_name = ? AND stored_filename = ? LIMIT 1\"
    # ... (lógica similar a get_file_record_by_id) ...
    case Repo.query(sql, [storage_backend_name, stored_filename]) do
      {:ok, %{rows: [row_data], columns: cols}} ->
        file_map = map_row_to_generic_struct(row_data, cols)
        {:ok, Map.update(file_map, \"meta_data\", nil, &parse_json_string/1)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"Deleta os metadados de um arquivo (não deleta o arquivo físico do storage).\"
  @spec delete_file_record(id :: integer()) :: :ok | {:error, :not_found | any()}
  def delete_file_record(id) do
    sql = \"DELETE FROM deeper_files WHERE id = ?\"
    case Repo.execute(sql, [id]) do
      {:ok, %{num_rows: 1}} -> :ok
      {:ok, %{num_rows: 0}} -> {:error, :not_found}
      err -> err
    end
  end

  # TODO: Funções para `deeper_file_versions` se necessário.
  # Ex: create_file_version_record, get_file_versions, get_specific_file_version

  # --- Funções Auxiliares ---
  defp parse_json_string(json_string) do
    if json_string && String.length(json_string) > 0 do
      case Jason.decode(json_string) do
        {:ok, map} -> map
        _ -> json_string
      end
    else
      nil
    end
  end

  defp map_row_to_generic_struct(row_data_list, columns_list) do
    # ... (mesma função de antes) ...
    Enum.zip(columns_list, row_data_list)
    |> Enum.map(fn {col, val} ->
        key = try do String.to_atom(Atom.to_string(col)) rescue _ -> Atom.to_string(col) end
        {key, val}
      end)
    |> Enum.into(%{})
  end
end
```

### Adaptador Exemplo: `Deeper.FileManagement.StorageAdapters.Local`

*   **Adaptador S3:** Um adaptador `Deeper.FileManagement.StorageAdapters.S3` usaria uma biblioteca como `ExAws.S3` para interagir com o S3.

---

### 2. Módulo: `Deeper.FileManagement.FileRepo`

Este módulo gerencia os metadados dos arquivos na tabela `deeper_files` e configurações de storage em `deeper_storage_backends`.

**Localização do Código:** `lib/deeper/file_management/file_repo.ex`