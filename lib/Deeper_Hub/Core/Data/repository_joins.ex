defmodule Deeper_Hub.Core.Data.RepositoryJoins do
  @moduledoc """
  Módulo para operações de join no repositório.
  
  Este módulo fornece funções para realizar diferentes tipos de joins entre tabelas,
  como inner join, left join e right join, permitindo consultas mais complexas
  com seleção de campos específicos e condições personalizadas.
  """

  import Ecto.Query
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.DBConnection.DBConnectionFacade, as: DBConn
  alias Deeper_Hub.Core.Telemetry.TelemetryEvents
  alias Deeper_Hub.Core.EventBus.EventDefinitions

  @doc """
  Realiza uma operação de INNER JOIN entre duas tabelas.

  ## Parâmetros

    - `schema1`: O módulo do schema Ecto principal
    - `schema2`: O módulo do schema Ecto a ser unido
    - `select_fields`: Lista de campos a serem selecionados (opcional)
    - `where_conditions`: Mapa com condições para o WHERE (opcional)
    - `opts`: Opções adicionais (como limit, offset, join_on, etc.)

  ## Opções

    - `:join_on`: Tupla {campo_schema1, campo_schema2} para definir a condição de join
                 Padrão: {:id, :id} ou {schema1_name_id, :id} se não especificado
    - `:limit`: Limite de registros a retornar
    - `:offset`: Deslocamento para paginação

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Join entre User e Profile onde User.id = Profile.user_id
      {:ok, results} = RepositoryJoins.join_inner(User, Profile, 
                                                  [:name, :email, :profile_picture],
                                                  %{active: true},
                                                  join_on: {:id, :user_id})
  """
  @spec join_inner(module(), module(), list() | nil, map() | nil, Keyword.t()) ::
          {:ok, list(map())} | {:error, term()}
  def join_inner(schema1, schema2, select_fields_arg \\ nil, where_conditions_arg \\ nil, opts_arg \\ []) do
    # Início da operação de inner join

    query_start_time = System.monotonic_time()

    # Log original arguments for better debugging insight
    Logger.debug("Realizando INNER JOIN", %{
      module: __MODULE__,
      schema1: schema1,
      schema2: schema2,
      select_fields: select_fields_arg,
      where_conditions: where_conditions_arg,
      opts: opts_arg
    })

    # Usa o pool de conexões gerenciado pelo DBConnection para executar a consulta
    # Isso garante que a conexão será devolvida ao pool após o uso
    result = DBConn.run(nil, fn ->
      try do
        # Parameter processing
        {processed_opts, actual_filters} =
          cond do
            is_list(where_conditions_arg) ->
              # Define keys that are options, not filters for where clause
              opt_keys = [:join_on, :preload, :limit, :offset]
              
              opts_from_where = Enum.filter(where_conditions_arg, fn {k, _v} -> k in opt_keys end)
              new_processed_opts = Keyword.merge(opts_arg, opts_from_where) # Start with original opts_arg

              filter_keywords = Keyword.drop(where_conditions_arg, opt_keys) # Corrected function
              
              new_actual_filters = 
                if Enum.empty?(filter_keywords) do
                  nil
                else
                  Map.new(filter_keywords) # Convert remaining keywords to map for filters
                end
              {new_processed_opts, new_actual_filters}
            
            is_map(where_conditions_arg) ->
              {opts_arg, where_conditions_arg} # opts_arg remains unchanged, actual_filters is where_conditions_arg
            
            true -> # where_conditions_arg is nil or other unexpected type
              {opts_arg, nil} # opts_arg remains unchanged, actual_filters is nil
          end

        # Determina os campos para a condição de join using processed_opts from cond
        {field1, field2} = determine_join_fields(schema1, schema2, processed_opts)

        # Constrói a query base com o join
        query = from(s1 in schema1,
                    inner_join: s2 in ^schema2,
                    on: field(s1, ^field1) == field(s2, ^field2))

        # Aplica seleção de campos se especificada (using original select_fields_arg)
        query = apply_select(query, schema1, schema2, select_fields_arg)

        # Aplica condições where se especificadas (using processed actual_filters)
        query = apply_where_conditions(query, actual_filters)

        # Aplica limit e offset se fornecidos (using processed_opts)
        query = Repository.apply_limit_offset(query, processed_opts)

        # Executa a query usando a conexão do pool
        records = Repo.all(query)
        
        # Retorna os registros encontrados
        {:ok, records}
      rescue
        e in [UndefinedFunctionError] ->
          # Tabela pode não existir
          error_msg = "Tabela para schema não encontrada"
          Logger.error(error_msg, %{
            module: __MODULE__,
            schema1: schema1,
            schema2: schema2,
            error: e,
            stacktrace: __STACKTRACE__
          })
          {:error, :table_not_found}

        e ->
          # Erro genérico
          Logger.error("Falha ao realizar INNER JOIN", %{
            module: __MODULE__,
            schema1: schema1,
            schema2: schema2,
            error: e,
            stacktrace: __STACKTRACE__
          })

          # Erro ao realizar join
          {:error, e}
      end
    end)
    
    # Calcula a duração total da operação
    duration = System.monotonic_time() - query_start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    # Registra o resultado final com métricas
    case result do
      {:ok, records} ->
        Logger.debug("INNER JOIN realizado com sucesso", %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          count: length(records),
          duration_ms: duration_ms
        })

      {:error, e} ->
        Logger.error("Erro ao realizar INNER JOIN", %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          error: e
        })

        # Erro ao realizar join

        {:error, e}
    end

    # Finaliza operação de inner join

    result
  end

  @doc """
  Realiza uma operação de LEFT JOIN entre duas tabelas.

  ## Parâmetros

    - `schema1`: O módulo do schema Ecto principal (lado esquerdo)
    - `schema2`: O módulo do schema Ecto a ser unido (lado direito)
    - `select_fields`: Lista de campos a serem selecionados (opcional)
    - `where_conditions`: Mapa com condições para o WHERE (opcional)
    - `opts`: Opções adicionais (como limit, offset, join_on, etc.)

  ## Opções

    - `:join_on`: Tupla {campo_schema1, campo_schema2} para definir a condição de join
                 Padrão: {:id, :id} ou {schema1_name_id, :id} se não especificado
    - `:limit`: Limite de registros a retornar
    - `:offset`: Deslocamento para paginação

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Left join entre User e Profile onde User.id = Profile.user_id
      # Retorna todos os usuários, mesmo os que não têm perfil
      {:ok, results} = RepositoryJoins.join_left(User, Profile,
                                                [:name, :email, :profile_picture],
                                                %{active: true},
                                                join_on: {:id, :user_id})
  """
  @spec join_left(module(), module(), list() | nil, map() | nil, Keyword.t()) ::
          {:ok, list(map())} | {:error, term()}
  def join_left(schema1, schema2, select_fields_arg \\ nil, where_conditions_arg \\ nil, opts_arg \\ []) do
    # Início da operação de left join

    query_start_time = System.monotonic_time()

    # Log original arguments for better debugging insight
    Logger.debug("Realizando LEFT JOIN", %{
      module: __MODULE__,
      schema1: schema1,
      schema2: schema2,
      select_fields: select_fields_arg,
      where_conditions: where_conditions_arg,
      opts: opts_arg
    })

    # Usa o pool de conexões gerenciado pelo DBConnection para executar a consulta
    # Isso garante que a conexão será devolvida ao pool após o uso
    result = DBConn.run(nil, fn ->
      try do
        # Parameter processing
        {processed_opts, actual_filters} =
          cond do
            is_list(where_conditions_arg) ->
              opt_keys = [:join_on, :preload, :limit, :offset]
              
              opts_from_where = Enum.filter(where_conditions_arg, fn {k, _v} -> k in opt_keys end)
              new_processed_opts = Keyword.merge(opts_arg, opts_from_where) # Start with original opts_arg

              filter_keywords = Keyword.drop(where_conditions_arg, opt_keys) # Corrected function
              
              new_actual_filters = 
                if Enum.empty?(filter_keywords) do
                  nil
                else
                  Map.new(filter_keywords) # Convert remaining keywords to map for filters
                end
              {new_processed_opts, new_actual_filters}
            
            is_map(where_conditions_arg) ->
              {opts_arg, where_conditions_arg} # opts_arg remains unchanged, actual_filters is where_conditions_arg
            
            true -> # where_conditions_arg is nil or other unexpected type
              {opts_arg, nil} # opts_arg remains unchanged, actual_filters is nil
          end

        # Determina os campos para a condição de join using processed_opts from cond
        {field1, field2} = determine_join_fields(schema1, schema2, processed_opts)

        # Constrói a query base com o join
        query = from(s1 in schema1,
                    left_join: s2 in ^schema2,
                    on: field(s1, ^field1) == field(s2, ^field2))

        # Aplica seleção de campos se especificada (using original select_fields_arg)
        query = apply_select(query, schema1, schema2, select_fields_arg)

        # Aplica condições where se especificadas (using processed actual_filters)
        query = apply_where_conditions(query, actual_filters)

        # Aplica limit e offset se fornecidos (using processed_opts)
        query = Repository.apply_limit_offset(query, processed_opts)

        # Executa a query usando a conexão do pool
        records = Repo.all(query)
        
        # Retorna os registros encontrados
        {:ok, records}
      rescue
        e in [UndefinedFunctionError] ->
          # Tabela pode não existir
          error_msg = "Tabela para schema não encontrada"
          Logger.error(error_msg, %{
            module: __MODULE__,
            schema1: schema1,
            schema2: schema2,
            error: e,
            stacktrace: __STACKTRACE__
          })
          {:error, :table_not_found}

        e ->
          # Erro genérico
          Logger.error("Falha ao realizar LEFT JOIN", %{
            module: __MODULE__,
            schema1: schema1,
            schema2: schema2,
            error: e,
            stacktrace: __STACKTRACE__
          })
          {:error, e}
      end
    end)
    
    # Calcula a duração total da operação
    duration = System.monotonic_time() - query_start_time
    duration_ms = System.convert_time_unit(duration, :native, :millisecond)
    
    # Registra o resultado final com métricas
    case result do
      {:ok, records} ->
        Logger.debug("LEFT JOIN realizado com sucesso", %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          count: length(records),
          duration_ms: duration_ms
        })

        # Emite evento de telemetria para consulta bem-sucedida
        TelemetryEvents.execute_db_query(
          %{duration: duration, rows: length(records)},
          %{status: :success, operation: :join_left, module: __MODULE__}
        )
        
        # Emite evento para o EventBus
        EventDefinitions.emit(
          EventDefinitions.db_query(),
          %{duration: duration, rows: length(records), status: :success, operation: :join_left},
          source: "#{__MODULE__}"
        )
        
        {:ok, records}
      {:error, e} ->
        # Emite evento de telemetria para consulta com erro
        TelemetryEvents.execute_db_query(
          %{duration: duration, rows: 0},
          %{status: :error, operation: :join_left, module: __MODULE__, reason: inspect(e)}
        )
        
        # Emite evento de erro para o EventBus
        EventDefinitions.emit(
          EventDefinitions.db_error(),
          %{duration: duration, status: :error, operation: :join_left, error: e},
          source: "#{__MODULE__}"
        )
        
        Logger.error("Erro ao realizar LEFT JOIN", %{
          module: __MODULE__,
          error: inspect(e),
          schema1: inspect(schema1),
          schema2: inspect(schema2)
        })
        {:error, e}
    end

    # Finaliza operação de left join

    result
  end

  @doc """
  Realiza uma operação de RIGHT JOIN entre duas tabelas.

  ## Parâmetros

    - `schema1`: O módulo do schema Ecto principal (lado esquerdo)
    - `schema2`: O módulo do schema Ecto a ser unido (lado direito)
    - `select_fields`: Lista de campos a serem selecionados (opcional)
    - `where_conditions`: Mapa com condições para o WHERE (opcional)
    - `opts`: Opções adicionais (como limit, offset, join_on, etc.)

  ## Opções

    - `:join_on`: Tupla {campo_schema1, campo_schema2} para definir a condição de join
                 Padrão: {:id, :id} ou {schema1_name_id, :id} se não especificado
    - `:limit`: Limite de registros a retornar
    - `:offset`: Deslocamento para paginação

  ## Retorno

    - `{:ok, list}` com a lista de registros
    - `{:error, reason}` em caso de falha

  ## Exemplo

      # Right join entre User e Profile onde User.id = Profile.user_id
      # Retorna todos os perfis, mesmo os que não estão associados a um usuário
      {:ok, results} = RepositoryJoins.join_right(User, Profile,
                                                 [:name, :email, :profile_picture],
                                                 %{active: true},
                                                 join_on: {:id, :user_id})
  """
  @spec join_right(module(), module(), list() | nil, map() | nil, Keyword.t()) ::
          {:ok, list(map())} | {:error, term()}
  def join_right(schema1, schema2, select_fields_arg \\ nil, where_conditions_arg \\ nil, opts_arg \\ []) do
    # Início da operação de right join
    query_start_time = System.monotonic_time()

    # Log original arguments for better debugging insight
    Logger.debug("Realizando RIGHT JOIN", %{
      module: __MODULE__,
      schema1: schema1,
      schema2: schema2,
      select_fields: select_fields_arg,
      where_conditions: where_conditions_arg,
      opts: opts_arg
    })

    # Usa o pool de conexões gerenciado pelo DBConnection para executar a consulta
    # Isso garante que a conexão será devolvida ao pool após o uso
    result = DBConn.run(nil, fn ->
      try do
        # Parameter processing
        {processed_opts, actual_filters} =
        cond do
          is_list(where_conditions_arg) ->
            opt_keys = [:join_on, :preload, :limit, :offset]
            opts_from_where = Enum.filter(where_conditions_arg, fn {k, _v} -> k in opt_keys end)
            new_processed_opts = Keyword.merge(opts_arg, opts_from_where) # Start with original opts_arg
            filter_keywords = Keyword.drop(where_conditions_arg, opt_keys) # Corrected function
            new_actual_filters = 
              if Enum.empty?(filter_keywords) do
                nil
              else
                Map.new(filter_keywords)
              end
            {new_processed_opts, new_actual_filters}
          is_map(where_conditions_arg) ->
            {opts_arg, where_conditions_arg}
          true ->
            {opts_arg, nil}
        end

      # Determina os campos para a condição de join using processed_opts
      {field1, field2} = determine_join_fields(schema1, schema2, processed_opts)

      # Constrói a query base com o join
      query = from(s1 in schema1,
                  right_join: s2 in ^schema2,
                  on: field(s1, ^field1) == field(s2, ^field2))

      # Aplica seleção de campos se especificada (using original select_fields_arg)
      query = apply_select(query, schema1, schema2, select_fields_arg)

      # Aplica condições where se especificadas (using processed actual_filters)
      query = apply_where_conditions(query, actual_filters)

      # Aplica limit e offset se fornecidos (using processed_opts)
      query = Repository.apply_limit_offset(query, processed_opts)

      # Executa a query
      records = Repo.all(query)

      duration = System.monotonic_time() - query_start_time

      # Registra o resultado
      Logger.debug("RIGHT JOIN realizado com sucesso", %{
        module: __MODULE__,
        schema1: schema1,
        schema2: schema2,
        count: length(records),
        duration_ms: System.convert_time_unit(duration, :native, :millisecond)
      })

      {:ok, records}
    rescue
      e in [UndefinedFunctionError] ->
        error_msg = "Tabela para schema não encontrada"
        Logger.error(error_msg, %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          error: e,
          stacktrace: __STACKTRACE__
        })
        {:error, :table_not_found}

      e ->
        Logger.error("Falha ao realizar RIGHT JOIN", %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          error: e,
          stacktrace: __STACKTRACE__
        })
        {:error, e}
      end
    end)

    # Finaliza operação de right join
    result
  end

  # Funções auxiliares privadas

  @doc false
  defp determine_join_fields(schema1, schema2, opts) do
    # Verifica se a condição de join foi especificada nas opções
    case Keyword.get(opts, :join_on) do
      {field1, field2} when is_atom(field1) and is_atom(field2) ->
        {field1, field2}
      
      nil ->
        # Tenta inferir os campos de join
        schema1_name = schema1 |> Module.split() |> List.last() |> Macro.underscore()
        _schema2_name = schema2 |> Module.split() |> List.last() |> Macro.underscore()
        
        # Verifica se existe um campo foreign_key no schema2 que referencia schema1
        field1 = :id
        field2 = String.to_atom("#{schema1_name}_id")
        
        {field1, field2}
      
      invalid ->
        # Formato inválido para join_on
        raise ArgumentError, "Formato inválido para join_on: #{inspect(invalid)}. Esperado: {field1, field2}"
    end
  end

  @doc false
  defp schema_to_alias_id_atom(schema_module) do
    schema_module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> then(&String.to_atom("#{&1}_id"))
  end

  @doc false
  defp schema_to_prefix(schema_module) do
    schema_module
    |> Module.split()
    |> List.last()
    |> Macro.underscore()
    |> then(&("#{&1}_"))
  end

  @doc false
  defp apply_select(query, schema1, schema2, select_fields_arg) do
    s1_fields = schema1.__schema__(:fields)
    s2_fields = schema2.__schema__(:fields)

    s2_id_alias = schema_to_alias_id_atom(schema2)
    s2_prefix = schema_to_prefix(schema2)

    select_map =
      cond do
        select_fields_arg == nil or select_fields_arg == %{} ->
          s1_select = Enum.into(s1_fields, %{}, fn field -> {field, dynamic([s1, _s2], field(s1, ^field))} end)
          s2_select_aliased = Enum.into(s2_fields, %{}, fn
            :id -> {s2_id_alias, dynamic([_s1, s2], field(s2, :id))}
            field -> {String.to_atom("#{s2_prefix}#{field}"), dynamic([_s1, s2], field(s2, ^field))}
          end)
          Map.merge(s1_select, s2_select_aliased)

        is_list(select_fields_arg) ->
          selected_s1_fields = Enum.filter(s1_fields, fn field -> field in select_fields_arg end)
          s1_select = Enum.into(selected_s1_fields, %{}, fn field -> {field, dynamic([s1, _s2], field(s1, ^field))} end)
          s2_select_aliased = Enum.into(s2_fields, %{}, fn
            :id -> {s2_id_alias, dynamic([_s1, s2], field(s2, :id))}
            field -> {String.to_atom("#{s2_prefix}#{field}"), dynamic([_s1, s2], field(s2, ^field))}
          end)
          Map.merge(s1_select, s2_select_aliased)
        
        is_map(select_fields_arg) ->
          s1_requested_fields_from_map = Map.keys(select_fields_arg)
          # Ensure :id from schema1 is always included, along with fields from map keys.
          # Filter against actual s1_fields to ensure validity.
          s1_final_field_atoms_to_select = 
            [:id | s1_requested_fields_from_map]
            |> Enum.uniq()
            |> Enum.filter(fn field_atom -> field_atom in s1_fields end)

          s1_select = Enum.into(s1_final_field_atoms_to_select, %{}, fn field -> {field, dynamic([s1, _s2], field(s1, ^field))} end)
          
          s2_select_aliased = Enum.into(s2_fields, %{}, fn
            :id -> {s2_id_alias, dynamic([_s1, s2], field(s2, :id))}
            field -> {String.to_atom("#{s2_prefix}#{field}"), dynamic([_s1, s2], field(s2, ^field))}
          end)
          Map.merge(s1_select, s2_select_aliased)

        true -> # Fallback for unsupported types, defaults to selecting all
          s1_select = Enum.into(s1_fields, %{}, fn field -> {field, dynamic([s1, _s2], field(s1, ^field))} end)
          s2_select_aliased = Enum.into(s2_fields, %{}, fn
            :id -> {s2_id_alias, dynamic([_s1, s2], field(s2, :id))}
            field -> {String.to_atom("#{s2_prefix}#{field}"), dynamic([_s1, s2], field(s2, ^field))}
          end)
          Map.merge(s1_select, s2_select_aliased)
      end

    from([_s1, _s2] in query, select: ^select_map)
  end

  @doc false
  defp apply_where_conditions(query, nil) do
    # Se não houver condições, retorna a query original
    query
  end

  @doc false
  defp apply_where_conditions(query, where_conditions) when is_map(where_conditions) do
    # Aplica as condições WHERE
    Enum.reduce(where_conditions, query, fn
      # Condições para o schema1 (primeiro na query)
      {{:schema1, field_name}, nil}, acc_query ->
        from([s1, s2] in acc_query, where: is_nil(field(s1, ^field_name)))
      
      {{:schema1, field_name}, :not_nil}, acc_query ->
        from([s1, s2] in acc_query, where: not is_nil(field(s1, ^field_name)))
      
      {{:schema1, field_name}, {:in, values}}, acc_query when is_list(values) ->
        from([s1, s2] in acc_query, where: field(s1, ^field_name) in ^values)
      
      {{:schema1, field_name}, {:not_in, values}}, acc_query when is_list(values) ->
        from([s1, s2] in acc_query, where: field(s1, ^field_name) not in ^values)
      
      {{:schema1, field_name}, {:like, term}}, acc_query ->
        from([s1, s2] in acc_query, where: like(field(s1, ^field_name), ^"%#{term}%"))
      
      {{:schema1, field_name}, {:ilike, term}}, acc_query ->
        from([s1, s2] in acc_query, where: ilike(field(s1, ^field_name), ^"%#{term}%"))
      
      {{:schema1, field_name}, value}, acc_query ->
        from([s1, s2] in acc_query, where: field(s1, ^field_name) == ^value)
      
      # Condições para o schema2 (segundo na query)
      {{:schema2, field_name}, nil}, acc_query ->
        from([s1, s2] in acc_query, where: is_nil(field(s2, ^field_name)))
      
      {{:schema2, field_name}, :not_nil}, acc_query ->
        from([s1, s2] in acc_query, where: not is_nil(field(s2, ^field_name)))
      
      {{:schema2, field_name}, {:in, values}}, acc_query when is_list(values) ->
        from([s1, s2] in acc_query, where: field(s2, ^field_name) in ^values)
      
      {{:schema2, field_name}, {:not_in, values}}, acc_query when is_list(values) ->
        from([s1, s2] in acc_query, where: field(s2, ^field_name) not in ^values)
      
      {{:schema2, field_name}, {:like, term}}, acc_query ->
        from([s1, s2] in acc_query, where: like(field(s2, ^field_name), ^"%#{term}%"))
      
      {{:schema2, field_name}, {:ilike, term}}, acc_query ->
        from([s1, s2] in acc_query, where: ilike(field(s2, ^field_name), ^"%#{term}%"))
      
      {{:schema2, field_name}, value}, acc_query ->
        from([s1, s2] in acc_query, where: field(s2, ^field_name) == ^value)
      
      # Condições sem especificação de schema (assume schema1)
      {field_name, nil}, acc_query ->
        from([s1, s2] in acc_query, where: is_nil(field(s1, ^field_name)))
      
      {field_name, :not_nil}, acc_query ->
        from([s1, s2] in acc_query, where: not is_nil(field(s1, ^field_name)))
      
      {field_name, {:in, values}}, acc_query when is_list(values) ->
        from([s1, s2] in acc_query, where: field(s1, ^field_name) in ^values)
      
      {field_name, {:not_in, values}}, acc_query when is_list(values) ->
        from([s1, s2] in acc_query, where: field(s1, ^field_name) not in ^values)
      
      {field_name, {:like, term}}, acc_query ->
        from([s1, s2] in acc_query, where: like(field(s1, ^field_name), ^"%#{term}%"))
      
      {field_name, {:ilike, term}}, acc_query ->
        from([s1, s2] in acc_query, where: ilike(field(s1, ^field_name), ^"%#{term}%"))
      
      {field_name, value}, acc_query ->
        from([s1, s2] in acc_query, where: field(s1, ^field_name) == ^value)
    end)
  end
end
