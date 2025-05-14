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
  alias Deeper_Hub.Core.Data.RepositoryCore

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
  def join_inner(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []) do
    # Início da operação de inner join

    query_start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Realizando INNER JOIN", %{
      module: __MODULE__,
      schema1: schema1,
      schema2: schema2,
      select_fields: select_fields,
      where_conditions: where_conditions,
      opts: opts
    })

    result = try do
      # Determina os campos para a condição de join
      {field1, field2} = determine_join_fields(schema1, schema2, opts)

      # Constrói a query base com o join
      query = from(s1 in schema1,
                  inner_join: s2 in ^schema2,
                  on: field(s1, ^field1) == field(s2, ^field2))

      # Aplica seleção de campos se especificada
      query = apply_select(query, schema1, schema2, select_fields)

      # Aplica condições where se especificadas
      query = apply_where_conditions(query, where_conditions)

      # Aplica limit e offset se fornecidos
      query = RepositoryCore.apply_limit_offset(query, opts)

      # Executa a query
      records = Repo.all(query)

      duration = System.monotonic_time() - query_start_time

      # Registra o resultado
      Logger.debug("INNER JOIN realizado com sucesso", %{
        module: __MODULE__,
        schema1: schema1,
        schema2: schema2,
        count: length(records),
        duration_ms: System.convert_time_unit(duration, :native, :millisecond)
      })

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

        # Tabela não encontrada

        {:error, :table_not_found}

      e ->
        # Outros erros
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
  def join_left(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []) do
    # Início da operação de left join

    query_start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Realizando LEFT JOIN", %{
      module: __MODULE__,
      schema1: schema1,
      schema2: schema2,
      select_fields: select_fields,
      where_conditions: where_conditions,
      opts: opts
    })

    result = try do
      # Determina os campos para a condição de join
      {field1, field2} = determine_join_fields(schema1, schema2, opts)

      # Constrói a query base com o join
      query = from(s1 in schema1,
                  left_join: s2 in ^schema2,
                  on: field(s1, ^field1) == field(s2, ^field2))

      # Aplica seleção de campos se especificada
      query = apply_select(query, schema1, schema2, select_fields)

      # Aplica condições where se especificadas
      query = apply_where_conditions(query, where_conditions)

      # Aplica limit e offset se fornecidos
      query = RepositoryCore.apply_limit_offset(query, opts)

      # Executa a query
      records = Repo.all(query)

      duration = System.monotonic_time() - query_start_time

      # Registra o resultado
      Logger.debug("LEFT JOIN realizado com sucesso", %{
        module: __MODULE__,
        schema1: schema1,
        schema2: schema2,
        count: length(records),
        duration_ms: System.convert_time_unit(duration, :native, :millisecond)
      })

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

        # Tabela não encontrada

        {:error, :table_not_found}

      e ->
        # Outros erros
        Logger.error("Falha ao realizar LEFT JOIN", %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Erro ao realizar join

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
  def join_right(schema1, schema2, select_fields \\ nil, where_conditions \\ nil, opts \\ []) do
    # Início da operação de right join

    query_start_time = System.monotonic_time()

    # Registra a operação
    Logger.debug("Realizando RIGHT JOIN", %{
      module: __MODULE__,
      schema1: schema1,
      schema2: schema2,
      select_fields: select_fields,
      where_conditions: where_conditions,
      opts: opts
    })

    result = try do
      # Determina os campos para a condição de join
      {field1, field2} = determine_join_fields(schema1, schema2, opts)

      # Constrói a query base com o join
      query = from(s1 in schema1,
                  right_join: s2 in ^schema2,
                  on: field(s1, ^field1) == field(s2, ^field2))

      # Aplica seleção de campos se especificada
      query = apply_select(query, schema1, schema2, select_fields)

      # Aplica condições where se especificadas
      query = apply_where_conditions(query, where_conditions)

      # Aplica limit e offset se fornecidos
      query = RepositoryCore.apply_limit_offset(query, opts)

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
        # Tabela pode não existir
        error_msg = "Tabela para schema não encontrada"
        Logger.error(error_msg, %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Tabela não encontrada

        {:error, :table_not_found}

      e ->
        # Outros erros
        Logger.error("Falha ao realizar RIGHT JOIN", %{
          module: __MODULE__,
          schema1: schema1,
          schema2: schema2,
          error: e,
          stacktrace: __STACKTRACE__
        })

        # Erro ao realizar join

        {:error, e}
    end

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
  defp apply_select(query, _schema1, _schema2, nil) do
    # Se não houver seleção específica, seleciona todos os campos
    query
  end

  @doc false
  defp apply_select(query, schema1, schema2, select_fields) when is_list(select_fields) do
    # Aplica seleção de campos específicos
    schema1_alias = schema1 |> Module.split() |> List.last() |> String.downcase()
    schema2_alias = schema2 |> Module.split() |> List.last() |> String.downcase()
    
    # Constrói um mapa de seleção para os campos especificados
    select_map = Enum.reduce(select_fields, %{}, fn
      {schema_name, field_name}, acc when is_atom(schema_name) and is_atom(field_name) ->
        # Campo com prefixo de schema específico
        schema_alias = case schema_name do
          ^schema1 -> schema1_alias
          ^schema2 -> schema2_alias
          _ -> raise ArgumentError, "Schema inválido: #{inspect(schema_name)}"
        end
        
        Map.put(acc, :"#{schema_alias}_#{field_name}", dynamic([s1, s2], field(s1, ^field_name)))
      
      field_name, acc when is_atom(field_name) ->
        # Campo sem prefixo de schema (assume schema1)
        Map.put(acc, field_name, dynamic([s1, s2], field(s1, ^field_name)))
    end)
    
    # Aplica a seleção na query
    from([s1, s2] in query, select: ^select_map)
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
