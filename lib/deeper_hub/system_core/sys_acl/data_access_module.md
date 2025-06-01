# Documentação Deeper: Módulo de Acesso a Dados para ACL (`ACLRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.ACLRepo`, responsável por interagir com as tabelas do sistema de Controle de Acesso (ACL) no banco de dados SQLite. Ele fornecerá funções para consultar informações de níveis, ações, permissões da matriz e rastreamento de ações.

**Nota:** Este módulo foca em **consultar** dados de ACL para validação. Funções para **modificar** dados de ACL (ex: adicionar um nível, mudar uma permissão na matriz) pertenceriam à API de administração e seriam implementadas aqui ou em um `AdminACLRepo` dedicado, conforme necessário para `07_studio_admin_api/acl_admin_api.md`.

**Localização do Código:** `lib/deeper/system_core/acl_repo.ex`

```elixir
defmodule Deeper.SystemCore.ACLRepo do
  alias Deeper.Core.Data.Repo # Seu módulo de acesso ao DB

  # Estruturas de dados (mapas) esperadas para retorno (exemplos):
  # Level: %{id: integer, name: string, ...}
  # Action: %{id: integer, module: string, name: string, countable: integer, disabled_for_levels: integer, ...}
  # Membership: %{level_id: integer, date_starts: integer, date_expires: integer | nil, state: string}
  # MatrixRule: %{allowed_count: integer | nil, period_len: integer | nil, ...}
  # ActionTrack: %{actions_left: integer, valid_since: integer | nil}

  @doc \"\"\"
  Busca o(s) nível(is) de ACL ativos e válidos para um determinado ID de conta.
  Pode haver múltiplos níveis se as datas não se sobrepuserem ou se o sistema permitir.
  Retorna uma lista de mapas de associação de nível.
  \"\"\"
  @spec get_active_user_levels(account_id :: integer()) :: {:ok, list(map())} | {:error, any()}
  def get_active_user_levels(account_id) do
    current_timestamp = DateTime.to_unix(DateTime.utc_now())
    sql = \"\"\"
    SELECT lm.IDLevel, lm.DateStarts, lm.DateExpires, lm.State, l.Name as LevelName
    FROM sys_acl_levels_members lm
    JOIN sys_acl_levels l ON lm.IDLevel = l.ID
    WHERE lm.IDMember = ?
      AND lm.DateStarts <= ?
      AND (lm.DateExpires IS NULL OR lm.DateExpires >= ?)
      AND l.Active = 'yes'
      AND (lm.State = 'active' OR lm.State = '') -- Considerar '' como ativo se não houver gerenciamento de estado de pagamento
    ORDER BY l.\"Order\" ASC, lm.DateStarts DESC; -- Prioriza por ordem do nível e depois o mais recente
    \"\"\"
    # O cliente/lógica de validação pode precisar escolher o \"melhor\" ou o de maior prioridade
    # se múltiplos níveis forem retornados e aplicáveis.
    case Repo.query(sql, [account_id, current_timestamp, current_timestamp]) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        memberships = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, memberships}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca detalhes de uma ação ACL pelo nome da ação e nome do módulo.\"
  @spec get_action_details(action_name :: String.t(), module_name :: String.t(), additional_param_name :: String.t() | nil) :: {:ok, map()} | {:error, :not_found | any()}
  def get_action_details(action_name, module_name, additional_param_name \\\\ nil) do
    # O tratamento de additional_param_name NULL vs. string vazia no DB precisa ser consistente.
    # Se AdditionalParamName pode ser NULL na tabela:
    sql_base = \"SELECT ID, Module, Name, Countable, DisabledForLevels, Title FROM sys_acl_actions WHERE Name = ? AND Module = ?\"
    params_base = [action_name, module_name]

    {sql_final, params_final} =
      if is_nil(additional_param_name) do
        {sql_base <> \" AND AdditionalParamName IS NULL\", params_base}
      else
        {sql_base <> \" AND AdditionalParamName = ?\", params_base ++ [additional_param_name]}
      end

    sql_final = sql_final <> \" LIMIT 1\"

    case Repo.query(sql_final, params_final) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} ->
        {:error, :not_found} # Ação não definida no sistema
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Verifica a permissão na matriz ACL para um nível e uma ação.\"
  @spec get_matrix_permission(level_id :: integer(), action_id :: integer()) :: {:ok, map() | nil} | {:error, any()}
  def get_matrix_permission(level_id, action_id) do
    sql = \"\"\"
    SELECT AllowedCount, AllowedPeriodLen, AllowedPeriodStart, AllowedPeriodEnd, AdditionalParamValue
    FROM sys_acl_matrix
    WHERE IDLevel = ? AND IDAction = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [level_id, action_id]) do
      {:ok, %{rows: [row_data], columns: columns}} -> # Permissão existe
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} -> # Nenhuma regra explícita na matriz para este nível/ação
        {:ok, nil} # Indica que não há regra; a lógica de validação tratará como não permitido ou verificará defaults.
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"Busca informações de rastreamento para uma ação contável de um membro.\"
  @spec get_action_track_info(account_id :: integer(), action_id :: integer()) :: {:ok, map() | nil} | {:error, any()}
  def get_action_track_info(account_id, action_id) do
    sql = \"\"\"
    SELECT ActionsLeft, ValidSince
    FROM sys_acl_actions_track
    WHERE IDMember = ? AND IDAction = ?
    LIMIT 1;
    \"\"\"
    case Repo.query(sql, [account_id, action_id]) do
      {:ok, %{rows: [row_data], columns: columns}} ->
        {:ok, map_row_to_generic_struct(row_data, columns)}
      {:ok, %{rows: []}} -> # Nenhum rastreamento existe ainda para esta ação/membro
        {:ok, nil}
      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc \"\"\"
  Atualiza ou insere informações de rastreamento para uma ação contável de um membro.
  Usado para decrementar ActionsLeft ou resetar o contador.
  \"\"\"
  @spec upsert_action_track_info(account_id :: integer(), action_id :: integer(), actions_left :: integer(), valid_since :: integer() | nil) :: :ok | {:error, any()}
  def upsert_action_track_info(account_id, action_id, actions_left, valid_since) do
    # SQLite UPSERT (INSERT OR REPLACE ou INSERT ON CONFLICT DO UPDATE)
    sql = \"\"\"
    INSERT INTO sys_acl_actions_track (IDMember, IDAction, ActionsLeft, ValidSince)
    VALUES (?, ?, ?, ?)
    ON CONFLICT(IDMember, IDAction) DO UPDATE SET
      ActionsLeft = excluded.ActionsLeft,
      ValidSince = excluded.ValidSince;
    \"\"\"
    # excluded.ColumnName é a sintaxe do SQLite para referenciar o valor da linha que seria inserida
    case Repo.execute(sql, [account_id, action_id, actions_left, valid_since]) do
      {:ok, _results} -> :ok # Repo.execute para DML pode retornar contagem de linhas ou similar
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Funções para Administração de ACL (exemplo, podem ser movidas para AdminACLRepo) ---

  @doc \"Lista todos os níveis de ACL.\"
  @spec list_acl_levels() :: {:ok, list(map())} | {:error, any()}
  def list_acl_levels() do
    sql = \"SELECT ID, Name, \\\"Order\\\", Active FROM sys_acl_levels ORDER BY \\\"Order\\\" ASC\"
    case Repo.query(sql, []) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        levels = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, levels}
      {:error, reason} -> {:error, reason}
    end
  end

  @doc \"Lista todas as ações ACL, opcionalmente filtradas por módulo.\"
  @spec list_acl_actions(module_filter :: String.t() | nil) :: {:ok, list(map())} | {:error, any()}
  def list_acl_actions(module_filter \\\\ nil) do
    base_sql = \"SELECT ID, Module, Name, Title, Countable FROM sys_acl_actions\"
    params = []

    {final_sql, final_params} =
      if module_filter do
        {base_sql <> \" WHERE Module = ? ORDER BY Module, Name\", [module_filter]}
      else
        {base_sql <> \" ORDER BY Module, Name\", params}
      end

    case Repo.query(final_sql, final_params) do
      {:ok, %{rows: rows_data, columns: columns}} ->
        actions = Enum.map(rows_data, &map_row_to_generic_struct(&1, columns))
        {:ok, actions}
      {:error, reason} -> {:error, reason}
    end
  end

  # --- Função Auxiliar de Mapeamento ---
  # Assume que Repo.query retorna {:ok, %{rows: list_of_lists, columns: list_of_atoms}}
  # ou algo similar que possa ser zipado. Ajuste conforme a sua implementação de Repo.
  defp map_row_to_generic_struct(row_data_list, columns_list) when is_list(row_data_list) and is_list(columns_list) do
    Enum.zip(columns_list, row_data_list)
    |> Enum.map(fn {col, val} -> {String.to_atom(Atom.to_string(col)), val} end) # Garante que as chaves sejam atoms
    |> Enum.into(%{})
  catch
    # Para lidar com nomes de colunas que não são atoms válidos (ex: \"Order\")
    # ou se columns_list já são atoms.
    # Se columns_list já são atoms, o String.to_atom(Atom.to_string(col)) é redundante.
    # Esta função de mapeamento genérica pode precisar de mais refinamento.
    _error ->
      # Tenta um mapeamento mais simples se o acima falhar ou se as colunas já são atoms
      if Keyword.keyword?(columns_list) and length(columns_list) == length(row_data_list) do
         Enum.zip(Keyword.keys(columns_list), row_data_list) |> Enum.into(%{})
      else
        # Fallback ou log de erro
        Logger.warn(\"Falha ao mapear linha do DB: #{inspect {row_data_list, columns_list}}\")
        %{} # Retorna mapa vazio ou lança erro
      end
  end
end
```

```elixir
defmodule Deeper.SystemCore.ACLValidator do
  alias Deeper.SystemCore.ACLRepo

  def can_perform_action?(account_id, action_name, module_name, additional_param \\\\ nil) do
    current_timestamp = DateTime.to_unix(DateTime.utc_now())

    # 1. Obter o nível ativo do usuário (pode retornar múltiplos, pegar o de maior prioridade)
    case ACLRepo.get_active_user_levels(account_id) do
      {:ok, [%{id_level: level_id, ...} | _tail_levels]} -> # Pega o primeiro/mais prioritário
        # 2. Obter detalhes da ação
        case ACLRepo.get_action_details(action_name, module_name, additional_param) do
          {:ok, %{id: action_id, disabled_for_levels: disabled_mask, countable: countable_flag}} ->
            # 3. Verificar se a ação está desabilitada para este nível
            if (Bitwise.band(disabled_mask, Bitwise.bsl(1, level_id - 1))) > 0 do # Assumindo que level_id 1 é bit 0
              false # Ação desabilitada para este nível
            else
              # 4. Verificar permissão na matriz
              case ACLRepo.get_matrix_permission(level_id, action_id) do
                {:ok, nil} -> false # Nenhuma regra na matriz, não permitido por padrão

                {:ok, %{allowed_count: allowed_count, period_len: period_len}} ->
                  # 5. Se a ação não é contável, ou é ilimitada, então é permitida
                  if countable_flag == 0 or is_nil(allowed_count) do
                    true
                  else
                    # 6. Lógica para ações contáveis
                    case ACLRepo.get_action_track_info(account_id, action_id) do
                      {:ok, track_info} ->
                        # track_info é %{actions_left: N, valid_since: TS} ou nil
                        # Lógica para verificar ActionsLeft, ValidSince, PeriodLen e AllowedCount
                        # Se necessário, resetar o contador se o período expirou
                        # Se actions_left > 0, então true, senão false
                        # Exemplo muito simplificado:
                        if is_nil(track_info) or track_info.actions_left > 0 do
                           # Se é a primeira vez ou ainda tem ações
                           # Aqui deveria verificar o período com 'valid_since' e 'period_len'
                           # E se o período expirou, resetar 'actions_left' para 'allowed_count'
                           # e atualizar 'valid_since'.
                           true # Permitido (simplificado)
                        else
                           false # Sem ações restantes
                        end
                      _ -> false # Erro ao buscar track info
                    end
                  end
                _ -> false # Erro ao buscar permissão da matriz
              end
            end
          _ -> false # Erro ao buscar detalhes da ação ou ação não encontrada
        end
      _ -> false # Erro ao buscar níveis do usuário ou usuário sem nível ativo
    end
  end
end
```

## Lógica de Validação de Permissão (Exemplo Conceitual)

A lógica completa para verificar se um usuário pode realizar uma ação seria mais complexa e residiria em um módulo como `Deeper.SystemCore.ACLValidator` ou diretamente nos plugs/controllers. Ela usaria as funções do `ACLRepo` da seguinte forma (pseudo-código):