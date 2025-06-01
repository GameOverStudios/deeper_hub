# Documentação Deeper: Módulos de Acesso a Dados para Álbuns de Fotos

Este documento descreve o módulo Elixir (Repositório) principal responsável por interagir com as tabelas do banco de dados relacionadas ao módulo de Álbuns de Fotos (`deeper_photo_albums` e `deeper_album_photos`).

## Módulo Principal: `Deeper.Content.PhotoAlbumsRepo`

Este módulo lida com todas as operações de banco de dados para o sistema de álbuns de fotos.

**Localização do Código Elixir:** `lib/deeper/content/photo_albums_repo.ex`

```elixir
defmodule Deeper.Content.PhotoAlbumsRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Files.StorageRepo # Para map_row_to_struct helper

  # Structs opcionais
  # defstruct [:id, :title, ..., :photos] # Album
  # defstruct [:id, :album_id, :file_id, :title, ..., :file_details] # AlbumPhoto

  # === Funções para Álbuns de Fotos (`deeper_photo_albums`) ===

  @doc \"\"\"
  Cria um novo álbum de fotos.
  `attrs` inclui :profile_id, :title, e opcionalmente :slug, :description, :privacy_level, etc.
  \"\"\"
  def create_album(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Gerar slug se não fornecido, etc.
    sql = \"\"\"
    INSERT INTO deeper_photo_albums (
      profile_id, title, slug, description, privacy_level, allow_comments,
      photos_count, created_at, updated_at
      -- cover_photo_id é tipicamente definido depois que uma foto é adicionada
    ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    RETURNING *;
    \"\"\"
    values = [
      attrs.profile_id, attrs.title, attrs.slug, attrs.description,
      attrs.privacy_level || \"public\", attrs.allow_comments || 1,
      0, # photos_count inicial
      current_ts, current_ts
    ]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      err -> err
    end
  end

  @doc \"\"\"
  Busca um álbum pelo seu ID.
  `opts` pode incluir `[:creator_profile, :cover_photo_details]`
  \"\"\"
  def get_album(id_or_slug, opts \\\\ [include: [:creator_profile, :cover_photo_details]]) do
    condition = if is_integer(id_or_slug), do: \"a.id = ?\", else: \"a.slug = ?\"
    select_fields = \"a.*\"
    joins = \"\"
    params = [id_or_slug]

    if Enum.member?(opts[:include], :creator_profile) do
      select_fields = select_fields <> \", p_creator.name as creator_name\"
      joins = joins <> \" LEFT JOIN sys_profiles sp_creator ON a.profile_id = sp_creator.id LEFT JOIN sys_accounts p_creator ON sp_creator.account_id = p_creator.id\"
    end

    if Enum.member?(opts[:include], :cover_photo_details) do
      select_fields = select_fields <> \"\"\",
        ap_cover.id as cover_photo_album_photo_id,
        ap_cover.title as cover_photo_title,
        f_cover.remote_id as cover_photo_remote_id,
        f_cover.storage_object as cover_photo_storage,
        f_cover.ext as cover_photo_ext
      \"\"\"
      joins = joins <> \"\"\"
        LEFT JOIN deeper_album_photos ap_cover ON a.cover_photo_id = ap_cover.id
        LEFT JOIN deeper_files f_cover ON ap_cover.file_id = f_cover.id
      \"\"\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_photo_albums a #{joins} WHERE #{condition} LIMIT 1\"

    case Repo.query(sql, params) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"\"\"
  Lista álbuns com filtros e paginação.
  `filters`: %{profile_id: 123, privacy_level: \"public\"}
  `pagination_opts`: %{limit: 10, offset: 0, sort_by: \"created_at\", sort_order: \"desc\"}
  \"\"\"
  def list_albums(filters \\\\ %{}, pagination_opts \\\\ %{}) do
    # ... (Implementação similar a list_articles/list_events, com filtros e joins apropriados) ...
    # Incluir JOIN para detalhes da foto de capa se `include=cover_photo_details` for comum aqui.
    select_clause = \"SELECT DISTINCT a.*, p_creator.name as creator_name\" # Adicionar campos de capa
    from_clause = \"FROM deeper_photo_albums a JOIN sys_profiles sp_creator ON a.profile_id = sp_creator.id JOIN sys_accounts p_creator ON sp_creator.account_id = p_creator.id\"
    # Opcional JOIN para capa (pode ser feito se `include` for solicitado)
    # join_cover_clause = \" LEFT JOIN deeper_album_photos ap_cover ON a.cover_photo_id = ap_cover.id LEFT JOIN deeper_files f_cover ON ap_cover.file_id = f_cover.id\"
    where_conditions = [\"1=1\"]
    params = []

    if creator_id = filters[:profile_id], do: (Array.push(where_conditions, \"a.profile_id = ?\"); Array.push(params, creator_id))
    if privacy = filters[:privacy_level], do: (Array.push(where_conditions, \"a.privacy_level = ?\"); Array.push(params, privacy))

    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"created_at\", \"title\", \"photos_count\"], \"created_at\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(DISTINCT a.id) as total_count #{from_clause} #{where_clause}\"
    # ... (executar e retornar) ...
    :not_implemented # Placeholder
  end

  @doc \"Atualiza um álbum.\"
  def update_album(id, attrs) do
    # ... (Lógica similar a update_article, construindo SET clause) ...
    # Campos permitidos: :title, :slug, :description, :cover_photo_id, :privacy_level, etc.
    # Não atualizar photos_count diretamente aqui; isso é feito por add/remove photo.
    current_ts = DateTime.to_unix(DateTime.utc_now())
    update_fields_map = Map.put(attrs, :updated_at, current_ts)
                       |> Map.drop([:profile_id, :created_at, :id, :photos_count])
    # ... (construir set_clause e params) ...
    :not_implemented
  end

  @doc \"Deleta um álbum (e suas entradas em deeper_album_photos via ON DELETE CASCADE).\"
  def delete_album(id) do
    sql = \"DELETE FROM deeper_photo_albums WHERE id = ?\"
    Repo.execute(sql, [id])
  end

  @doc \"Define a foto de capa para um álbum.\"
  def set_album_cover(album_id, album_photo_id) do
    # Verificar se album_photo_id pertence ao album_id
    check_sql = \"SELECT 1 FROM deeper_album_photos WHERE id = ? AND album_id = ? LIMIT 1\"
    case Repo.query(check_sql, [album_photo_id, album_id]) do
      {:ok, %{rows: [_]}} ->
        update_sql = \"UPDATE deeper_photo_albums SET cover_photo_id = ?, updated_at = ? WHERE id = ?\"
        Repo.execute(update_sql, [album_photo_id, DateTime.to_unix(DateTime.utc_now()), album_id])
      _ -> {:error, :photo_not_in_album_or_invalid}
    end
  end

  @doc \"Recalcula e atualiza a contagem de fotos para um álbum.\"
  def recalculate_photos_count(album_id) do
    count_sql = \"SELECT COUNT(id) FROM deeper_album_photos WHERE album_id = ?\"
    update_sql = \"UPDATE deeper_photo_albums SET photos_count = ? WHERE id = ?\"
    case Repo.query(count_sql, [album_id]) do
      {:ok, %{rows: [{count}]}} -> Repo.execute(update_sql, [count, album_id])
      _ -> Logger.error(\"Falha ao recalcular contagem de fotos para álbum #{album_id}\", module: __MODULE__)
    end
    :ok
  end


  # === Funções para Fotos em Álbuns (`deeper_album_photos`) ===

  @doc \"\"\"
  Adiciona uma foto (referência a um `deeper_files.id`) a um álbum.
  `attrs` inclui :album_id, :file_id, :profile_id (uploader da foto), e opcionalmente :title, :order_index.
  \"\"\"
  def add_photo_to_album(attrs) do
    current_ts = DateTime.to_unix(DateTime.utc_now())
    # Obter o próximo order_index se não fornecido
    order_index = attrs.order_index || get_next_photo_order_index(attrs.album_id)

    Repo.transaction(fn ->
      sql = \"\"\"
      INSERT INTO deeper_album_photos (
        album_id, file_id, profile_id, title, description, order_index, created_at, updated_at
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?)
      RETURNING *;
      \"\"\"
      values = [
        attrs.album_id, attrs.file_id, attrs.profile_id, attrs.title, attrs.description,
        order_index, current_ts, current_ts
      ]
      with {:ok, %{rows: [row], columns: cols}} <- Repo.query(sql, values),
           :ok <- recalculate_photos_count(attrs.album_id) do
        # Opcional: se for a primeira foto do álbum, defini-la como capa.
        # if get_album_cover_photo_id(attrs.album_id) == nil do
        #   album_photo_id = StorageRepo.map_row_to_struct(row, cols).id
        #   set_album_cover(attrs.album_id, album_photo_id)
        # end
        {:ok, StorageRepo.map_row_to_struct(row, cols)}
      else
        err -> Repo.rollback(err)
      end
    end)
  end

  defp get_next_photo_order_index(album_id) do
    sql = \"SELECT COALESCE(MAX(order_index), -1) + 1 FROM deeper_album_photos WHERE album_id = ?\"
    case Repo.query(sql, [album_id]) do
      {:ok, %{rows: [{next_index}]}} -> next_index
      _ -> 0
    end
  end

  @doc \"Busca uma foto de álbum pelo seu ID.\"
  def get_album_photo(album_photo_id, opts \\\\ [include: [:file_details, :uploader_profile]]) do
    select_fields = \"ap.*\"
    joins = \"\"
    params = [album_photo_id]

    if Enum.member?(opts[:include], :file_details) do
      select_fields = select_fields <> \", f.remote_id, f.storage_object, f.mime_type, f.ext, f.size as file_size, f.img_width, f.img_height\"
      joins = joins <> \" JOIN deeper_files f ON ap.file_id = f.id\"
    end
    if Enum.member?(opts[:include], :uploader_profile) do
      select_fields = select_fields <> \", p_uploader.name as uploader_name\"
      joins = joins <> \" LEFT JOIN sys_profiles sp_uploader ON ap.profile_id = sp_uploader.id LEFT JOIN sys_accounts p_uploader ON sp_uploader.account_id = p_uploader.id\"
    end

    sql = \"SELECT #{select_fields} FROM deeper_album_photos ap #{joins} WHERE ap.id = ? LIMIT 1\"
    case Repo.query(sql, params) do
      {:ok, %{rows: [row], columns: cols}} -> {:ok, StorageRepo.map_row_to_struct(row, cols)}
      {:ok, %{rows: []}} -> {:error, :not_found}
      err -> err
    end
  end

  @doc \"\"\"
  Lista fotos de um álbum específico.
  `pagination_opts` para sort_by (order_index ASC, created_at DESC), limit, offset.
  \"\"\"
  def list_photos_in_album(album_id, pagination_opts \\\\ %{}, opts \\\\ [include: [:file_details]]) do
    select_clause = \"SELECT ap.*\"
    from_clause = \"FROM deeper_album_photos ap\"
    joins = \"\"
    where_conditions = [\"ap.album_id = ?\"]
    params = [album_id]

    if Enum.member?(opts[:include], :file_details) do
      select_clause = select_clause <> \", f.remote_id, f.storage_object, f.mime_type, f.ext, f.size as file_size, f.img_width, f.img_height\"
      joins = joins <> \" JOIN deeper_files f ON ap.file_id = f.id\"
    end
    
    where_clause = \"WHERE \" <> Enum.join(where_conditions, \" AND \")
    order_clause = Deeper.Files.FilesRepo.build_order_clause(pagination_opts, [\"order_index\", \"created_at\"], \"order_index ASC, created_at ASC\")
    limit_offset_clause = Deeper.Files.FilesRepo.build_limit_offset_clause(pagination_opts)

    sql_data = \"#{select_clause} #{from_clause} #{joins} #{where_clause} #{order_clause} #{limit_offset_clause}\"
    sql_count = \"SELECT COUNT(ap.id) as total_count FROM deeper_album_photos ap #{where_clause}\" # Count sem joins desnecessários

    # ... (executar e retornar, similar a list_articles) ...
    :not_implemented
  end

  @doc \"Atualiza metadados de uma foto em um álbum (legenda, ordem).\"
  def update_album_photo(album_photo_id, attrs) do
    # `attrs` pode incluir :title, :description, :order_index
    # ... (Lógica similar a update_article) ...
    # Se order_index mudar, pode ser necessário reordenar outras fotos no álbum.
    :not_implemented
  end

  @doc \"\"\"
  Remove uma foto de um álbum.
  Isso remove a entrada de `deeper_album_photos`, mas não o arquivo de `deeper_files` (a menos que seja a única referência).
  \"\"\"
  def remove_photo_from_album(album_photo_id) do
    # Obter album_id antes de deletar para recalcular contagem
    get_album_photo(album_photo_id)
    |> case do
      {:ok, %{album_id: aid}} ->
        Repo.transaction(fn ->
          sql = \"DELETE FROM deeper_album_photos WHERE id = ?\"
          with {:ok, _} <- Repo.execute(sql, [album_photo_id]),
               :ok <- recalculate_photos_count(aid) do
            :ok
          else
            err -> Repo.rollback(err)
          end
        end)
      err -> err # :not_found ou outro erro
    end
  end

  @doc \"Atualiza a ordem das fotos em um álbum.\"
  def update_photos_order(album_id, ordered_photo_ids_list) when is_list(ordered_photo_ids_list) do
    # `ordered_photo_ids_list` é uma lista de `deeper_album_photos.id` na nova ordem.
    Repo.transaction(fn ->
      Enum.reduce_while(Enum.with_index(ordered_photo_ids_list), :ok, fn {photo_id, index}, _acc ->
        sql = \"UPDATE deeper_album_photos SET order_index = ? WHERE id = ? AND album_id = ?\"
        case Repo.execute(sql, [index, photo_id, album_id]) do
          {:ok, _} -> {:cont, :ok}
          err -> {:halt, Repo.rollback(err)}
        end
      end)
    end)
  end

end
```

### Notas para `PhotoAlbumsRepo`:
*   **Gerenciamento de `cover_photo_id`:** A lógica para definir ou atualizar a foto de capa (`set_album_cover/2`) é importante. A primeira foto adicionada a um álbum poderia se tornar a capa por padrão.
*   **Contagem de Fotos (`photos_count`):** A função `recalculate_photos_count/1` é chamada após adicionar ou remover fotos para manter a contagem na tabela `deeper_photo_albums` atualizada.
*   **Ordenação de Fotos (`order_index`):** `add_photo_to_album` inclui lógica para obter o próximo `order_index`. `update_photos_order/2` permite a reordenação em lote.
*   **Exclusão de Fotos:** `remove_photo_from_album/1` remove a *referência* da foto do álbum (entrada em `deeper_album_photos`). A exclusão do arquivo físico em `deeper_files` seria uma operação separada, possivelmente acionada se nenhuma outra entidade referenciar o `file_id`.
*   **JOINs e Performance:** As funções de listagem e obtenção individual podem se tornar complexas com múltiplos `JOIN`s para incluir detalhes do criador, capa, arquivos, etc. O uso do parâmetro `opts` para `include` ajuda a controlar quais dados são buscados.
*   **Transações:** Operações que modificam múltiplas tabelas ou que precisam de consistência (como adicionar foto e atualizar contagem) são envolvidas em transações.

Este Repo fornece a base para a funcionalidade de álbuns de fotos. O próximo passo seria definir os `api_endpoints.md`.