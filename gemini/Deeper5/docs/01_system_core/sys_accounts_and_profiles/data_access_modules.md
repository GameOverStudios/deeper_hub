# Documentação Deeper: Módulos de Acesso a Dados para Contas e Perfis

Este documento descreve os módulos Elixir (\"Repositórios\" ou \"Contextos\") responsáveis por interagir com as tabelas `sys_accounts`, `sys_profiles`, e `bx_persons_data` no banco de dados SQLite. Estes módulos encapsulam as queries SQL diretas e fornecem uma interface funcional para a lógica de negócios e os controllers da API.

## Módulos Principais:

1.  **`Deeper.SystemCore.AccountsRepo`**: Lida com a tabela `sys_accounts`.
2.  **`Deeper.SystemCore.ProfilesRepo`**: Lida com a tabela `sys_profiles` e a lógica de associação entre contas e perfis.
3.  **`Deeper.Content.PersonsRepo`**: Lida com a tabela `bx_persons_data` e os dados específicos de perfis de pessoa.

**Nota sobre Mapeamento de Resultados:** As funções nestes módulos que executam queries `SELECT` retornarão mapas Elixir (ou structs simples definidas dentro de cada módulo de repositório, se preferível). Uma função auxiliar `map_row_to_struct/2` (ou similar) dentro de cada repo pode ser usada para converter as tuplas/listas de resultados da query SQL para um formato mais utilizável. O exemplo do `DeeperHub.Core.Data.Repo` pode ter convenções sobre como `Repo.query/2` retorna os dados. Assumiremos que ele retorna `{:ok, %{rows: list_of_row_data, columns: list_of_column_names}}` ou algo similar que possa ser facilmente mapeado.

---

### 1. Módulo: `Deeper.SystemCore.AccountsRepo`

Este módulo gerencia as interações com a tabela `sys_accounts`.

**Localização do Código:** `lib/deeper/system_core/accounts_repo.ex`

```elixir
defmodule Deeper.SystemCore.AccountsRepo do
  alias Deeper.Core.Data.Repo # Seu módulo de acesso ao DB
  # Poderia definir uma struct aqui se quisesse tipar o retorno
  # defstruct [:id, :profile_id, :name, :email, ..., :active]

  @doc \"Busca uma conta pelo ID.\"
  @spec get_account(integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_account(id) do
    sql = \"SELECT * FROM sys_accounts WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      # Ajustar o pattern matching conforme o retorno real de Repo.query/2
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_account(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca uma conta pelo email.\"
  @spec get_account_by_email(String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_account_by_email(email) do
    sql = \"SELECT * FROM sys_accounts WHERE email = ? LIMIT 1\"
    case Repo.query(sql, [email]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_account(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Cria uma nova conta. Retorna a conta criada.\"
  @spec create_account(map()) :: {:ok, map()} | {:error, any()}
  def create_account(params) do
    # Assume que params contém: :name, :email, :password_hash, :role (opc), :lang_id (opc), :active (opc)
    # Timestamps de 'added' e 'changed' devem ser gerados aqui ou passados em params.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    sql = \"\"\"
    INSERT INTO sys_accounts (
      name, email, password_hash, role, lang_id,
      added, changed, active,
      email_confirmed, phone_confirmed, receive_updates, receive_news,
      login_attempts, locked
    )
    VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 1, 1, 0, 0)
    RETURNING *;
    \"\"\"
    # Valores padrão para colunas não obrigatórias foram incluídos no VALUES
    # ou poderiam ser definidos nos DEFAULTs da tabela.

    values = [
      params[:name],
      params[:email],
      params[:password_hash],
      params[:role] || 1, # Default role se não fornecido
      params[:lang_id] || 0, # Default lang_id
      params[:added] || current_timestamp,
      params[:changed] || current_timestamp,
      params[:active] || 0 # Default active status
    ]

    case Repo.query(sql, values) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_account(row_data, columns)}
      {:error, reason} ->
        # Verificar se o erro é de constraint UNIQUE (ex: email já existe)
        # e retornar um erro mais específico se necessário.
        {:error, reason}
    end
  end

  @doc \"Atualiza uma conta existente. Retorna a conta atualizada.\"
  @spec update_account(integer(), map()) :: {:ok, map()} | {:error, :not_found | any()}
  def update_account(id, params) do
    # Constrói a query de UPDATE dinamicamente baseado nos params fornecidos.
    # Exemplo simples:
    # params pode conter :name, :phone, :email_confirmed, :active, etc.
    # O password_hash deve ser atualizado por uma função específica.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    
    set_clauses =
      params
      |> Enum.map(fn {key, _val} -> \"#{key} = ?\" end) # Cuidado com SQL injection se as chaves não forem seguras
      |> Enum.join(\", \")
    
    # É mais seguro listar explicitamente os campos permitidos para atualização
    # para evitar SQL injection nas chaves e garantir que apenas campos válidos sejam atualizados.
    # Exemplo:
    # updatable_fields = [:name, :phone, :phone_confirmed, :receive_updates, :receive_news, :active, :locked, :profile_id]
    # {clauses, values} = build_update_clause(params, updatable_fields)
    # sql = \"UPDATE sys_accounts SET #{clauses}, changed = ? WHERE id = ? RETURNING *\"
    # final_values = values ++ [current_timestamp, id]

    # Simplificação para ilustração (requer uma função build_update_clause mais robusta):
    if Enum.empty?(params) do
      get_account(id) # Nenhuma alteração, retorna a conta atual
    else
      # Exemplo com campos fixos para segurança:
      fields_to_set = []
      values_to_set = []

      # Nome
      if Map.has_key?(params, :name), do: {fields_to_set, values_to_set} = {\"name = ?\", params.name, fields_to_set, values_to_set}
      # Email (cuidado, requer verificação de unicidade e reconfirmação talvez)
      # if Map.has_key?(params, :email), do: {fields_to_set, values_to_set} = {\"email = ?\", params.email, fields_to_set, values_to_set}
      if Map.has_key?(params, :phone), do: {fields_to_set, values_to_set} = {\"phone = ?\", params.phone, fields_to_set, values_to_set}
      if Map.has_key?(params, :phone_confirmed), do: {fields_to_set, values_to_set} = {\"phone_confirmed = ?\", params.phone_confirmed, fields_to_set, values_to_set}
      if Map.has_key?(params, :profile_id), do: {fields_to_set, values_to_set} = {\"profile_id = ?\", params.profile_id, fields_to_set, values_to_set}
      # ... outros campos atualizáveis

      # Função auxiliar para construir a lista de forma mais limpa:
      # {fields_sql_parts, field_values} =
      #  Enum.reduce(params, {[], []}, fn {key, value}, {acc_fields, acc_values} ->
      #    # Lógica para validar a chave (key) e adicionar \"key = ?\" e value
      #  end)

      # Esta parte precisa de uma implementação cuidadosa para construir dinamicamente
      # a cláusula SET de forma segura.
      # Por agora, vamos assumir um exemplo mais simples e menos flexível:
      sql_set_parts = []
      sql_values = []

      # Exemplo: Atualizar apenas 'name' e 'active'
      if name = params[:name], do: (
        sql_set_parts = [\"name = ?\"] ++ sql_set_parts
        sql_values = [name] ++ sql_values
      )
      if active = params[:active], do: (
        sql_set_parts = [\"active = ?\"] ++ sql_set_parts
        sql_values = [active] ++ sql_values
      )

      if Enum.empty?(sql_set_parts) do
        get_account(id) # Nada para atualizar
      else
        sql_set_clause = Enum.join(sql_set_parts, \", \")
        sql = \"UPDATE sys_accounts SET #{sql_set_clause}, changed = ? WHERE id = ? RETURNING *\"
        final_values = Enum.reverse(sql_values) ++ [current_timestamp, id] # Reverter pois adicionamos no início

        case Repo.query(sql, final_values) do
          {:ok, %{rows: [row_data], columns: columns}} ->
            {:ok, map_row_to_account(row_data, columns)}
          {:ok, %{rows: []}} -> # Não deveria acontecer se o ID existir e RETURNING * for usado
            {:error, :not_found}
          {:error, reason} ->
            {:error, reason}
        end
      end
    end
  end
  
  @doc \"Atualiza o hash da senha de uma conta.\"
  @spec update_password_hash(integer(), String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def update_password_hash(id, new_password_hash) do
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    sql = \"UPDATE sys_accounts SET password_hash = ?, changed = ? WHERE id = ? RETURNING *\"
    case Repo.query(sql, [new_password_hash, current_timestamp, id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_account(row_data, columns)}
      {:ok, %{rows: []}} ->
         {:error, :not_found} # Se o ID não existir
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Incrementa tentativas de login e opcionalmente bloqueia a conta.\"
  @spec record_login_attempt(String.t(), non_neg_integer()) :: :ok | {:error, any()}
  def record_login_attempt(email, max_attempts \\\\ 5) do
    # Primeiro, busca o usuário para obter tentativas atuais e status de bloqueio
    case get_account_by_email(email) do
      {:ok, account} ->
        new_attempts = account.login_attempts + 1
        new_locked_status = if new_attempts >= max_attempts, do: 1, else: account.locked

        sql = \"UPDATE sys_accounts SET login_attempts = ?, locked = ? WHERE id = ?\"
        Repo.execute(sql, [new_attempts, new_locked_status, account.id])
        # Retorna :ok ou o erro de execute. O controller pode querer retornar o status de bloqueio.
      err -> err # Usuário não encontrado
    end
  end

  @doc \"Reseta tentativas de login e desbloqueia a conta.\"
  @spec reset_login_attempts(integer()) :: :ok | {:error, any()}
  def reset_login_attempts(id) do
    sql = \"UPDATE sys_accounts SET login_attempts = 0, locked = 0, logged = ? WHERE id = ?\"
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    Repo.execute(sql, [current_timestamp, id])
  end

  # Função auxiliar para mapear a linha do DB para um mapa/struct
  # O formato exato de row_data e columns depende de como Repo.query os retorna.
  # Assumindo que row_data é uma lista de valores e columns é uma lista de nomes de colunas (atoms).
  defp map_row_to_account(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list) |> Enum.into(%{})
  end
end
```

```elixir
defmodule Deeper.SystemCore.ProfilesRepo do
  alias Deeper.Core.Data.Repo
  # defstruct [:id, :account_id, :type, :content_id, :status]

  @doc \"Cria uma nova entrada de perfil. Retorna o perfil criado.\"
  @spec create_profile(map()) :: {:ok, map()} | {:error, any()}
  def create_profile(params) do
    # params deve conter :account_id, :type, :content_id, :status (opc)
    sql = \"\"\"
    INSERT INTO sys_profiles (account_id, type, content_id, status)
    VALUES (?, ?, ?, ?)
    RETURNING *;
    \"\"\"
    values = [
      params[:account_id],
      params[:type],
      params[:content_id],
      params[:status] || \"active\"
    ]
    case Repo.query(sql, values) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_profile(row_data, columns)}
      {:error, reason} ->
        # Verificar erro de FK (account_id não existe) ou UNIQUE constraint
        {:error, reason}
    end
  end

  @doc \"Busca um perfil pelo ID.\"
  @spec get_profile(integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_profile(id) do
    sql = \"SELECT * FROM sys_profiles WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_profile(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca todos os perfis para uma account_id.\"
  @spec list_profiles_by_account(integer()) :: {:ok, list(map())} | {:error, any()}
  def list_profiles_by_account(account_id) do
    sql = \"SELECT * FROM sys_profiles WHERE account_id = ?\"
    case Repo.query(sql, [account_id]) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        profiles = Enum.map(rows_data, &map_row_to_profile(&1, columns))
        {:ok, profiles}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca um perfil específico por account_id e type (ex: o perfil 'bx_persons' principal de uma conta).\"
  @spec get_profile_by_account_and_type(integer(), String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_profile_by_account_and_type(account_id, type) do
    sql = \"SELECT * FROM sys_profiles WHERE account_id = ? AND type = ? LIMIT 1\"
    case Repo.query(sql, [account_id, type]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_profile(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza o status de um perfil.\"
  @spec update_profile_status(integer(), String.t()) :: {:ok, map()} | {:error, :not_found | any()}
  def update_profile_status(id, new_status) do
    # Validar new_status contra ('active', 'pending', 'suspended')
    sql = \"UPDATE sys_profiles SET status = ? WHERE id = ? RETURNING *\"
    case Repo.query(sql, [new_status, id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_profile(row_data, columns)}
      {:ok, %{rows: []}} ->
         {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  # Associa um content_id a um profile_id (ou atualiza se já existe para o tipo)
  # Útil se sys_accounts.profile_id não for preenchido diretamente.
  @doc \"Define o profile_id em sys_accounts para um determinado perfil principal\"
  @spec set_account_main_profile(integer(), integer()) :: :ok | {:error, any()}
  def set_account_main_profile(account_id, profile_id) do
    # Esta função agora parece mais com AccountsRepo.update_account
    # Deveria ser movida para AccountsRepo ou AccountsRepo deveria ser chamado daqui.
    # Por simplicidade, vamos assumir que AccountsRepo tem uma função para isso.
    Deeper.SystemCore.AccountsRepo.update_account(account_id, %{profile_id: profile_id})
  end


  defp map_row_to_profile(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list) |> Enum.into(%{})
  end
end
```

```elixir
defmodule Deeper.Content.PersonsRepo do
  alias Deeper.Core.Data.Repo
  # defstruct [:id, :author, :added, ..., :settings]

  @doc \"Cria uma nova entrada de dados de pessoa. Retorna os dados criados.\"
  @spec create_person_data(map()) :: {:ok, map()} | {:error, any()}
  def create_person_data(params) do
    # params deve conter :author (sys_profiles.id), :fullname
    # Outros campos são opcionais ou têm defaults.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    sql = \"\"\"
    INSERT INTO bx_persons_data (
      author, added, changed, fullname, last_name, description, gender, birthday,
      location, views, rate, votes, score, sc_up, sc_down, favorites, comments,
      reports, featured, allow_view_to, allow_post_to, allow_contact_to, settings,
      picture, cover
    )
    VALUES (
      ?, ?, ?, ?, ?, ?, ?, ?, ?, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, '3', '5', '3', ?, ?, ?
    )
    RETURNING *;
    \"\"\"
    # Nota: picture e cover são ids, inicializados como NULL ou 0 se não fornecidos.
    values = [
      params[:author],
      params[:added] || current_timestamp,
      params[:changed] || current_timestamp,
      params[:fullname],
      params[:last_name], # Pode ser nil
      params[:description],
      params[:gender],
      params[:birthday],
      params[:location],
      params[:settings], # Pode ser nil ou JSON string
      params[:picture], # Pode ser nil
      params[:cover]  # Pode ser nil
    ]

    case Repo.query(sql, values) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_person_data(row_data, columns)}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca dados de uma pessoa pelo ID (bx_persons_data.id).\"
  @spec get_person_data(integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_person_data(id) do
    sql = \"SELECT * FROM bx_persons_data WHERE id = ? LIMIT 1\"
    case Repo.query(sql, [id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_person_data(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Busca dados detalhados do perfil de uma pessoa, incluindo informações da conta.
  Este é um exemplo de JOIN para obter uma visão mais completa.
  \"\"\"
  @spec get_full_person_profile_by_person_data_id(integer()) :: {:ok, map()} | {:error, :not_found | any()}
  def get_full_person_profile_by_person_data_id(person_data_id) do
    sql = \"\"\"
    SELECT
      pd.*, -- todos os campos de bx_persons_data
      p.id as profile_id, p.type as profile_type, p.status as profile_status,
      a.id as account_id, a.name as account_name, a.email as account_email, a.active as account_active
    FROM bx_persons_data pd
    JOIN sys_profiles p ON pd.id = p.content_id AND p.type = 'bx_persons' -- Assume-se que o tipo é 'bx_persons'
    JOIN sys_accounts a ON p.account_id = a.id
    WHERE pd.id = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [person_data_id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        # O mapeamento aqui será mais complexo pois tem colunas de 3 tabelas
        # Pode ser necessário agrupar em sub-mapas: %{person_data: {...}, profile: {...}, account: {...}}
        {:ok, map_row_to_full_profile(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Atualiza dados de uma pessoa. Retorna os dados atualizados.\"
  @spec update_person_data(integer(), map()) :: {:ok, map()} | {:error, :not_found | any()}
  def update_person_data(id, params) do
    # Similar ao AccountsRepo.update_account, requer uma construção segura da cláusula SET.
    # Deve listar campos atualizáveis: :fullname, :description, :gender, :birthday, :location,
    # :picture, :cover, :settings, :allow_view_to, etc.
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    
    # Implementação simplificada para exemplo (precisa de uma função auxiliar robusta)
    # {set_clause, values} = build_update_clause_for_person(params)
    # sql = \"UPDATE bx_persons_data SET #{set_clause}, changed = ? WHERE id = ? RETURNING *\"
    # final_values = values ++ [current_timestamp, id]

    # Exemplo: Atualizar 'fullname' e 'description'
    sql_set_parts = []
    sql_values = []
    if fullname = params[:fullname], do: (
      sql_set_parts = [\"fullname = ?\"] ++ sql_set_parts
      sql_values = [fullname] ++ sql_values
    )
    if description = params[:description], do: (
      sql_set_parts = [\"description = ?\"] ++ sql_set_parts
      sql_values = [description] ++ sql_values
    )
    # ... outros campos

    if Enum.empty?(sql_set_parts) do
      get_person_data(id) # Nada para atualizar
    else
      sql_set_clause = Enum.join(sql_set_parts, \", \")
      sql = \"UPDATE bx_persons_data SET #{sql_set_clause}, changed = ? WHERE id = ? RETURNING *\"
      final_values = Enum.reverse(sql_values) ++ [current_timestamp, id]

      case Repo.query(sql, final_values) do
        {:ok, %{rows: [row_data], columns: columns}} ->
          {:ok, map_row_to_person_data(row_data, columns)}
        {:ok, %{rows: []}} ->
           {:error, :not_found}
        {:error, reason} ->
          {:error, reason}
      end
    end
  end

  @doc \"\"\"
  Lista dados de pessoas com paginação e filtros (exemplo básico).
  Filtros podem ser: fullname (LIKE), status (do perfil associado), etc.
  \"\"\"
  @spec list_persons_data(map()) :: {:ok, {list(map()), map()}} | {:error, any()}
  def list_persons_data(opts \\\\ %{}) do
    page = Map.get(opts, :page, 1)
    per_page = Map.get(opts, :per_page, 20)
    offset = (page - 1) * per_page

    # Construção de WHERE e JOINs baseada em opts[:filters]
    where_clauses = [\"p.type = 'bx_persons'\"] # Sempre filtrar por perfis de pessoa
    query_params = []

    if fullname_filter = Map.get(opts, [:filters, :fullname]) do
      where_clauses = where_clauses ++ [\"pd.fullname LIKE ?\"]
      query_params = query_params ++ [\"%#{fullname_filter}%\"]
    end
    if status_filter = Map.get(opts, [:filters, :status]) do # Filtrar pelo status do perfil
        where_clauses = where_clauses ++ [\"p.status = ?\"]
        query_params = query_params ++ [status_filter]
    end
    # ... outros filtros ...

    where_sql = if Enum.empty?(where_clauses), do: \"\", else: \"WHERE \" <> Enum.join(where_clauses, \" AND \")

    # Query para os dados
    data_sql = \"\"\"
    SELECT pd.*, p.id as profile_id, p.status as profile_status, a.name as account_name
    FROM bx_persons_data pd
    JOIN sys_profiles p ON pd.id = p.content_id
    JOIN sys_accounts a ON p.account_id = a.id
    #{where_sql}
    ORDER BY pd.added DESC -- Exemplo de ordenação
    LIMIT ? OFFSET ?;
    \"\"\"
    final_query_params = query_params ++ [per_page, offset]

    # Query para contagem total (para paginação)
    count_sql = \"\"\"
    SELECT COUNT(pd.id) as total_count
    FROM bx_persons_data pd
    JOIN sys_profiles p ON pd.id = p.content_id
    JOIN sys_accounts a ON p.account_id = a.id
    #{where_sql};
    \"\"\"

    case Repo.query(count_sql, query_params) do
      {:ok, %{rows: [[total_count]], columns: _}} ->
        case Repo.query(data_sql, final_query_params) do
          {:ok, %{rows: rows_data, columns: data_columns}} ->
            persons = Enum.map(rows_data, &map_row_to_person_list_item(&1, data_columns)) # Mapeamento para item de lista
            pagination_meta = %{
              total_items: total_count,
              current_page: page,
              per_page: per_page,
              total_pages: ceil(total_count / per_page)
            }
            {:ok, {persons, pagination_meta}}
          err -> err
        end
      err -> err # Erro ao buscar contagem
    end
  end


  defp map_row_to_person_data(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list) |> Enum.into(%{})
  end

  defp map_row_to_full_profile(row_data_list, columns_list) do
    # Precisa mapear cuidadosamente as colunas para sub-mapas ou uma struct aninhada
    # Ex: all_data = Enum.zip(columns_list, row_data_list) |> Enum.into(%{})
    # %{
    #   person_data: Map.take(all_data, [...colunas de bx_persons_data...]),
    #   profile: %{id: all_data.profile_id, type: all_data.profile_type, ...},
    #   account: %{id: all_data.account_id, name: all_data.account_name, ...}
    # }
    Enum.zip(columns_list, row_data_list) |> Enum.into(%{}) # Simplificado por agora
  end

  defp map_row_to_person_list_item(row_data_list, columns_list) do
    # Similar a map_row_to_full_profile, mas pode selecionar menos campos para listas
    Enum.zip(columns_list, row_data_list) |> Enum.into(%{}) # Simplificado
  end
end
```

---

### 2. Módulo: `Deeper.SystemCore.ProfilesRepo`

Este módulo gerencia as interações com a tabela `sys_profiles`.

**Localização do Código:** `lib/deeper/system_core/profiles_repo.ex`

---

### 3. Módulo: `Deeper.Content.PersonsRepo`

Este módulo gerencia as interações com a tabela `bx_persons_data`.

**Localização do Código:** `lib/deeper/content/persons_repo.ex`