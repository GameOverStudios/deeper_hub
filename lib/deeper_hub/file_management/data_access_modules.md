# Documentação Deeper: Módulos de Acesso a Dados para Gerenciamento de Arquivos

Este documento descreve os módulos Elixir (Repositórios/Contextos) responsáveis por interagir com as tabelas do banco de dados relacionadas ao gerenciamento de arquivos. Eles encapsularão as queries SQL diretas e fornecerão uma interface para os controllers da API e outros serviços.

## Módulos Principais:

1.  **`Deeper.Files.StorageRepo`**:
    *   Responsável por interagir com a tabela `sys_objects_storage`.
    *   Funções para obter configurações de um storage object, listar storages, etc.

2.  **`Deeper.Files.FilesRepo`**:
    *   Responsável por interagir com a tabela `deeper_files`.
    *   Funções para criar (registrar) novos arquivos, obter metadados de arquivos, listar arquivos (com filtros e paginação), atualizar metadados, e marcar arquivos para exclusão (se não for exclusão física imediata).

3.  **`Deeper.Files.TokensRepo`**:
    *   Responsável por interagir com a tabela `sys_storage_tokens`.
    *   Funções para criar, validar e invalidar tokens de acesso a arquivos.

## 1. Módulo: `Deeper.Files.StorageRepo`

Este módulo lida com a tabela `sys_objects_storage`.

**Localização do Código Elixir:** `lib/deeper/files/storage_repo.ex`

```elixir
defmodule Deeper.Files.StorageRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.Files.Storage # Opcional: struct para representar um storage object

  @doc \"\"\"
  Retorna as configurações de um storage object pelo seu nome (object).
  Espera-se que os `params` sejam uma string JSON.
  \"\"\"
  def get_storage_by_object(object_name) do
    sql = \"SELECT id, object, engine, params, token_life, table_files FROM sys_objects_storage WHERE object = ? LIMIT 1\"
    case Repo.query(sql, [object_name]) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        storage_map = map_row_to_struct(row_tuple, columns, :storage)
        # Decodificar params JSON se necessário
        params_decoded =
          case Jason.decode(storage_map.params || \"{}\") do
            {:ok, decoded} -> decoded
            _ -> %{} # Ou logar um erro se o JSON for inválido mas esperado
          end
        {:ok, %{storage_map | params: params_decoded}}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Lista todos os storage objects configurados.
  \"\"\"
  def list_storages do
    sql = \"SELECT id, object, engine, params, token_life, table_files FROM sys_objects_storage ORDER BY object\"
    case Repo.query(sql, []) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        storages = Enum.map(rows_tuples, &map_row_to_struct(&1, columns, :storage))
        # Opcional: decodificar params JSON para cada um
        storages_with_params = Enum.map(storages, fn storage ->
          params_decoded = case Jason.decode(storage.params || \"{}\") do
            {:ok, decoded} -> decoded
            _ -> %{}
          end
          %{storage | params: params_decoded}
        end)
        {:ok, storages_with_params}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Funções para CRUD de sys_objects_storage (mais para admin API)
  # def create_storage(params) do ... end
  # def update_storage(object_name, params) do ... end
  # def delete_storage(object_name) do ... end

  # Função helper genérica para mapear linha do DB para um mapa/struct
  # Esta função pode ser movida para um helper comum se usada em múltiplos repos
  defp map_row_to_struct(row_tuple, columns, _type \\\\ :default) do
    # columns é uma lista de strings como [\"id\", \"object\", \"engine\", ...]
    # row_tuple é uma tupla como {1, \"local_files\", \"Local\", ...}
    columns
    |> Enum.map(&String.to_atom/1)
    |> Enum.zip(Tuple.to_list(row_tuple))
    |> Map.new()
    # Se estiver usando structs:
    # |> then(&struct(Deeper.Files.Storage, &1)) # Exemplo
  end
end
```

```elixir
defmodule Deeper.Files.FilesRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.Files.File # Opcional: struct para representar um arquivo

  @doc \"\"\"
  Registra um novo arquivo no banco de dados.
  `attrs` deve ser um mapa contendo:
  :profile_id, :storage_object, :remote_id, :file_name, :mime_type, :ext, :size,
  :path (opcional), :is_private (opcional, default 0),
  :img_width (opcional), :img_height (opcional), :meta (opcional, string JSON)
  Retorna {:ok, file_map} ou {:error, reason}.
  \"\"\"
  def create_file(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    sql = \"\"\"
    INSERT INTO deeper_files (
      profile_id, storage_object, remote_id, path, file_name, mime_type, ext, size,
      added, modified, is_private, img_width, img_height, meta
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    RETURNING *;
    \"\"\"
    values = [
      attrs.profile_id,
      attrs.storage_object,
      attrs.remote_id,
      attrs.path,
      attrs.file_name,
      attrs.mime_type,
      attrs.ext,
      attrs.size,
      current_ts, # added
      current_ts, # modified
      attrs.is_private || 0,
      attrs.img_width,
      attrs.img_height,
      attrs.meta # Deve ser uma string JSON ou NULL
    ]

    case Repo.query(sql, values) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        {:ok, Deeper.Files.StorageRepo.map_row_to_struct(row_tuple, columns, :file)} # Reutilizando helper
      {:error, reason} ->
        Logger.error(\"Erro ao criar arquivo no DB: #{inspect(reason)}, attrs: #{inspect(attrs)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca um arquivo pelo seu ID.
  \"\"\"
  def get_file(id) do
    sql = \"SELECT f.*, s.engine as storage_engine, s.params as storage_params
           FROM deeper_files f
           JOIN sys_objects_storage s ON f.storage_object = s.object
           WHERE f.id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        file_map = Deeper.Files.StorageRepo.map_row_to_struct(row_tuple, columns, :file_details)
        # Decodificar storage_params JSON
        params_decoded =
          case Jason.decode(file_map.storage_params || \"{}\") do
            {:ok, decoded} -> decoded
            _ -> %{}
          end
        {:ok, %{file_map | storage_params: params_decoded}}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca um arquivo pelo storage_object e remote_id.
  \"\"\"
  def get_file_by_remote_id(storage_object, remote_id) do
    sql = \"SELECT f.*, s.engine as storage_engine, s.params as storage_params
           FROM deeper_files f
           JOIN sys_objects_storage s ON f.storage_object = s.object
           WHERE f.storage_object = ? AND f.remote_id = ? LIMIT 1\"
    case Repo.query(sql, [storage_object, remote_id]) do
      {:ok, %{rows: [row_tuple], columns: columns}} ->
        file_map = Deeper.Files.StorageRepo.map_row_to_struct(row_tuple, columns, :file_details)
        params_decoded = case Jason.decode(file_map.storage_params || \"{}\") do
            {:ok, decoded} -> decoded
            _ -> %{}
          end
        {:ok, %{file_map | storage_params: params_decoded}}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Lista arquivos com filtros e paginação.
  `filters` é um mapa, ex: %{profile_id: 123, mime_type: \"image/jpeg\", is_private: 0}
  `pagination_opts` é um mapa, ex: %{limit: 20, offset: 0, sort_by: \"added\", sort_order: \"desc\"}
  \"\"\"
  def list_files(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    {where_clause, params} = build_where_clause(filters)
    order_clause = build_order_clause(pagination_opts)
    limit_offset_clause = build_limit_offset_clause(pagination_opts)

    # Query para os dados
    sql_data = \"SELECT * FROM deeper_files #{where_clause} #{order_clause} #{limit_offset_clause}\"
    # Query para a contagem total (com os mesmos filtros)
    sql_count = \"SELECT COUNT(*) as total_count FROM deeper_files #{where_clause}\"

    case Repo.query(sql_data, params) do
      {:ok, %{rows: rows_tuples, columns: columns}} ->
        files = Enum.map(rows_tuples, &Deeper.Files.StorageRepo.map_row_to_struct(&1, columns, :file))

        # Obter contagem total
        case Repo.query(sql_count, params) do
          {:ok, %{rows: [{total_count}]}} ->
            {:ok, %{data: files, total_count: total_count}}
          err_count ->
            Logger.error(\"Erro ao contar arquivos: #{inspect(err_count)}\", module: __MODULE__)
            {:ok, %{data: files, total_count: -1}} # Retorna dados mas indica erro na contagem
        end
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Funções de atualização e exclusão
  # def update_file_meta(id, meta_attrs) do ... end
  # def delete_file(id) do
  #   -- Cuidado: deletar o registro no DB e o arquivo físico no storage.
  #   -- Pode usar sys_storage_deletions para uma fila.
  # end

  # --- Funções Helper para list_files ---
  defp build_where_clause(filters) do
    conditions =
      Enum.map_join(filters, \" AND \", fn {field, value} ->
        # Mapear field para nome de coluna real e adicionar placeholder
        # Cuidado com SQL injection se field vier diretamente do usuário sem sanitização.
        # Para este exemplo, assumimos que `field` é um atom seguro.
        \"#{Atom.to_string(field)} = ?\"
      end)

    params = Map.values(filters)

    if String.length(conditions) > 0 do
      {\"WHERE \" <> conditions, params}
    else
      {\"\", []}
    end
  end

  defp build_order_clause(pagination_opts) do
    sort_by = Map.get(pagination_opts, :sort_by, \"added\") # Coluna de ordenação padrão
    sort_order = Map.get(pagination_opts, :sort_order, \"desc\") |> String.upcase()

    # Validar sort_by e sort_order para evitar SQL injection
    allowed_sort_fields = [\"id\", \"file_name\", \"mime_type\", \"ext\", \"size\", \"added\", \"modified\"]
    allowed_sort_orders = [\"ASC\", \"DESC\"]

    if Enum.member?(allowed_sort_fields, sort_by) and Enum.member?(allowed_sort_orders, sort_order) do
      \"ORDER BY #{sort_by} #{sort_order}\"
    else
      \"ORDER BY added DESC\" # Fallback seguro
    end
  end

  defp build_limit_offset_clause(pagination_opts) do
    limit = Map.get(pagination_opts, :limit, 20)
    offset = Map.get(pagination_opts, :offset, 0)
    \"LIMIT #{limit} OFFSET #{offset}\"
  end
end
```

```elixir
defmodule Deeper.Files.TokensRepo do
  alias Deeper.Core.Data.Repo
  # alias Deeper.Files.StorageToken # Opcional: struct

  @doc \"\"\"
  Cria um novo token de acesso para um arquivo.
  Retorna {:ok, token_hash} ou {:error, reason}.
  \"\"\"
  def create_token(file_id, storage_object) do
    token_hash = :crypto.strong_rand_bytes(32) |> Base.url_encode64(padding: false)
    created_ts = DateTime.to_unix(DateTime.utc_now())

    sql = \"\"\"
    INSERT INTO sys_storage_tokens (file_id, storage_object, hash, created)
    VALUES (?, ?, ?, ?)
    \"\"\"
    values = [file_id, storage_object, token_hash, created_ts]

    case Repo.execute(sql, values) do
      # Para INSERT sem RETURNING, o resultado pode variar (ex: número de linhas afetadas)
      # Vamos assumir que Repo.execute para INSERT retorna {:ok, %{num_rows: 1}} ou similar
      {:ok, _result_info} -> # Ajustar conforme o retorno real de Repo.execute para INSERT
        {:ok, token_hash}
      {:error, reason} ->
        Logger.error(\"Erro ao criar token de arquivo: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc \"\"\"
  Valida um token e retorna os detalhes do arquivo associado se o token for válido e não expirado.
  `token_life_seconds` vem da configuração do storage_object.
  \"\"\"
  def validate_token(token_hash, token_life_seconds) do
    sql_token = \"SELECT id, file_id, storage_object, created FROM sys_storage_tokens WHERE hash = ? LIMIT 1\"

    case Repo.query(sql_token, [token_hash]) do
      {:ok, %{rows: [{_token_id, file_id, storage_object, created_ts}], columns: _}} ->
        # Verificar expiração
        current_ts = DateTime.to_unix(DateTime.utc_now())
        if (created_ts + token_life_seconds) >= current_ts do
          # Token válido e não expirado, buscar detalhes do arquivo
          Deeper.Files.FilesRepo.get_file(file_id) # Reutiliza a função do FilesRepo
        else
          invalidate_token_by_hash(token_hash) # Opcional: limpar token expirado
          {:error, :token_expired}
        end
      {:ok, %{rows: []}} ->
        {:error, :token_not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Invalida (deleta) um token pelo seu hash.
  \"\"\"
  def invalidate_token_by_hash(token_hash) do
    sql = \"DELETE FROM sys_storage_tokens WHERE hash = ?\"
    Repo.execute(sql, [token_hash])
    # Retorno pode ser ignorado ou verificado
    :ok
  end

  @doc \"\"\"
  Limpa tokens expirados para um determinado storage object.
  `token_life_seconds` vem da configuração do storage_object.
  Pode ser chamado por uma tarefa periódica.
  \"\"\"
  def cleanup_expired_tokens(storage_object, token_life_seconds) do
    expiration_threshold_ts = DateTime.to_unix(DateTime.utc_now()) - token_life_seconds
    sql = \"DELETE FROM sys_storage_tokens WHERE storage_object = ? AND created < ?\"
    
    case Repo.execute(sql, [storage_object, expiration_threshold_ts]) do
      {:ok, %{num_rows: num_deleted}} ->
        Logger.info(\"Limpou #{num_deleted} tokens expirados para o storage #{storage_object}.\", module: __MODULE__)
        {:ok, num_deleted}
      {:error, reason} ->
        Logger.error(\"Erro ao limpar tokens expirados para #{storage_object}: #{inspect(reason)}\", module: __MODULE__)
        {:error, reason}
    end
  end
end
```

### Notas para `StorageRepo`:
*   A função `map_row_to_struct` é um exemplo. A forma como o `Deeper.Core.Data.Repo.query/2` retorna os dados (mapas, tuplas) influenciará essa implementação. Assumi que retorna tuplas e uma lista de nomes de colunas.
*   A decodificação do JSON na coluna `params` é importante.

## 2. Módulo: `Deeper.Files.FilesRepo`

Este módulo lida com a tabela `deeper_files`.

**Localização do Código Elixir:** `lib/deeper/files/files_repo.ex`

### Notas para `FilesRepo`:
*   A função `create_file/1` assume que o arquivo já foi salvo no storage e o `remote_id` (e `path`, se aplicável) é conhecido. A lógica de salvar o arquivo físico ocorreria no controller da API antes de chamar `create_file/1`.
*   `get_file/1` e `get_file_by_remote_id/2` fazem um `JOIN` com `sys_objects_storage` para retornar também informações do storage, o que é útil para o cliente saber como acessar o arquivo.
*   `list_files/2` implementa uma lógica básica de construção de query dinâmica para filtros e paginação. É crucial validar e sanitizar as entradas para `sort_by` e os campos de filtro para prevenir SQL injection.
*   A exclusão de arquivos (`delete_file/1`) é complexa: precisa remover o registro do DB e o arquivo físico do storage. Usar uma tabela como `sys_storage_deletions` para uma exclusão assíncrona pode ser uma boa estratégia.

## 3. Módulo: `Deeper.Files.TokensRepo`

Este módulo lida com a tabela `sys_storage_tokens`.

**Localização do Código Elixir:** `lib/deeper/files/tokens_repo.ex`

### Notas para `TokensRepo`:
*   `create_token/2` gera um hash seguro aleatório para o token.
*   `validate_token/2` verifica a existência e a expiração do token antes de buscar os detalhes do arquivo. A lógica de expiração usa o `token_life` que viria da configuração do `sys_objects_storage`.
*   `cleanup_expired_tokens/2` é uma função útil para manutenção, que pode ser executada periodicamente.

Estes módulos de acesso a dados fornecem a camada de abstração sobre o SQL direto, tornando os controllers da API mais limpos e focados na lógica da requisição/resposta.