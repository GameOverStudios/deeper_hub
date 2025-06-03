defmodule DeeperHub.Core.Data.Repo do
  @moduledoc """
  Interface principal para operações de banco de dados usando DBConnection.

  Este módulo fornece funções para executar consultas SQL, transações e outras
  operações de banco de dados usando o adaptador Exqlite.Connection.

  Características principais:
  - Mecanismo de retry para operações de banco de dados, aumentando a resiliência
  - Tratamento de erros robusto com logging detalhado
  - Suporte a transações para garantir a integridade dos dados
  - Interface unificada para consultas e execuções SQL

  Este módulo é o ponto central de acesso ao banco de dados para toda a aplicação
  e implementa práticas recomendadas para operações de banco de dados em produção.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  # Importa o protocolo Query para Exqlite
  alias Exqlite.Query, as: Q

  # Helper para obter o nome do pool configurado
  @spec pool_name() :: atom()
  defp pool_name do
    # Usando o caminho completo do módulo para garantir que a configuração seja encontrada
    Application.get_env(:deeper_hub, DeeperHub.Core.Data.Repo, [])
    # Padrão se não configurado
    |> Keyword.get(:pool_name, DeeperHub.DBConnectionPool)
  end

  # Helper para criar uma query Exqlite a partir de uma string SQL
  @spec prepare_query(String.t()) :: Exqlite.Query.t()
  defp prepare_query(sql_string) do
    # O Exqlite.Query é apenas um struct com o campo statement
    %Q{statement: sql_string}
  end

  @doc """
  Executa uma consulta SQL que não necessariamente retorna linhas (ex: INSERT, UPDATE, DELETE).

  ## Parâmetros
    * `sql_string` - String SQL a ser executada
    * `params` - Lista de parâmetros para a consulta SQL (opcional)
    * `opts` - Opções adicionais para a execução (opcional)
      * `:max_retries` - Número máximo de tentativas em caso de falha (padrão: 3)
      * `:retry_delay_ms` - Tempo de espera entre tentativas em milissegundos (padrão: 200)

  ## Retorno
    * `{:ok, result_map}` - Execução bem-sucedida
      * O `result_map` tipicamente contém `%{num_rows: integer, rows: list_of_tuples_or_maps}`
    * `{:error, exception}` - Falha na execução

  ## Exemplos

      iex> Repo.execute("INSERT INTO users (name, email) VALUES (?, ?)", ["João", "joao@exemplo.com"])
      {:ok, %{num_rows: 1, rows: []}}

      iex> Repo.execute("UPDATE users SET active = ? WHERE id = ?", [true, 123])
      {:ok, %{num_rows: 1, rows: []}}

  Esta função inclui mecanismos de retry para lidar com falhas temporárias de conexão.
  """
  @spec execute(String.t(), list(), keyword()) :: {:ok, map()} | {:error, Exception.t()}
  def execute(sql_string, params \\ [], opts \\ []) do
    Logger.debug("Executando SQL: #{sql_string} com parâmetros: #{inspect(params)}",
      module: __MODULE__
    )

    # Configuração de retry
    max_retries = Keyword.get(opts, :max_retries, 3)
    retry_delay_ms = Keyword.get(opts, :retry_delay_ms, 200)

    # Remove opções de retry para não passar para o DBConnection
    opts = Keyword.drop(opts, [:max_retries, :retry_delay_ms])

    # Executa com retry
    execute_with_retry(sql_string, params, opts, 1, max_retries, retry_delay_ms)
  end

  # Função auxiliar para executar com retry
  @spec execute_with_retry(
          String.t(),
          list(),
          keyword(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, map()} | {:error, Exception.t()}
  defp execute_with_retry(sql_string, params, opts, attempt, max_retries, retry_delay_ms) do
    # Cria uma query Exqlite
    query = prepare_query(sql_string)

    # Tenta executar a query usando o DBConnection
    try do
      case DBConnection.prepare_execute(pool_name(), query, params, opts) do
        {:ok, _query_struct, result} ->
          Logger.debug("Execução bem-sucedida. Resultado: #{inspect(result)}", module: __MODULE__)
          {:ok, result}

        {:error, exception} ->
          handle_execution_error(
            sql_string,
            params,
            opts,
            attempt,
            max_retries,
            retry_delay_ms,
            exception
          )
      end
    rescue
      exception ->
        handle_execution_error(
          sql_string,
          params,
          opts,
          attempt,
          max_retries,
          retry_delay_ms,
          exception
        )
    end
  end

  # Função auxiliar para lidar com erros de execução
  @spec handle_execution_error(
          String.t(),
          list(),
          keyword(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          Exception.t()
        ) :: {:ok, map()} | {:error, Exception.t()}
  defp handle_execution_error(
         sql_string,
         params,
         opts,
         attempt,
         max_retries,
         retry_delay_ms,
         exception
       ) do
    error_message =
      "Falha na execução. SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}"

    # Verifica se deve tentar novamente
    if attempt < max_retries and retriable_error?(exception) do
      Logger.warning(
        "#{error_message} - Tentativa #{attempt}/#{max_retries}. Tentando novamente em #{retry_delay_ms}ms...",
        module: __MODULE__
      )

      Process.sleep(retry_delay_ms)
      execute_with_retry(sql_string, params, opts, attempt + 1, max_retries, retry_delay_ms)
    else
      if attempt > 1 do
        Logger.error("#{error_message} - Desistindo após #{attempt} tentativas.",
          module: __MODULE__
        )
      else
        Logger.error(error_message, module: __MODULE__)
      end

      {:error, exception}
    end
  end

  # Determina se um erro é retriable
  @spec retriable_error?(Exception.t()) :: boolean()
  defp retriable_error?(exception) do
    # Adicione aqui lógica para determinar quais erros são retriable
    # Por exemplo, erros de timeout, conexão, ou banco de dados ocupado
    case exception do
      %DBConnection.ConnectionError{} ->
        true

      %Exqlite.Error{message: message} ->
        String.contains?(message, "busy") or
          String.contains?(message, "locked") or
          String.contains?(message, "timeout")

      _ ->
        false
    end
  end

  @doc """
  Executa uma consulta SQL esperada para retornar linhas (ex: SELECT).

  ## Parâmetros
    * `sql_string` - String SQL a ser executada
    * `params` - Lista de parâmetros para a consulta SQL (opcional)
    * `opts` - Opções adicionais para a execução (opcional)
      * `:max_retries` - Número máximo de tentativas em caso de falha (padrão: 3)
      * `:retry_delay_ms` - Tempo de espera entre tentativas em milissegundos (padrão: 200)

  ## Retorno
    * `{:ok, rows_list}` - Consulta bem-sucedida com lista de linhas resultantes
    * `{:error, exception}` - Falha na consulta

  ## Exemplos

      iex> Repo.query("SELECT * FROM users WHERE active = ?", [true])
      {:ok, [{1, "João", "joao@exemplo.com", true}, {2, "Maria", "maria@exemplo.com", true}]}

      iex> Repo.query("SELECT COUNT(*) FROM users")
      {:ok, [{42}]}

  Esta função inclui mecanismos de retry para lidar com falhas temporárias de conexão.
  """
  @spec query(String.t(), list(), keyword()) :: {:ok, list()} | {:error, Exception.t()}
  def query(sql_string, params \\ [], opts \\ []) do
    Logger.debug("Consultando SQL: #{sql_string} com parâmetros: #{inspect(params)}",
      module: __MODULE__
    )

    # Configuração de retry
    max_retries = Keyword.get(opts, :max_retries, 3)
    retry_delay_ms = Keyword.get(opts, :retry_delay_ms, 200)

    # Remove opções de retry para não passar para o DBConnection
    opts = Keyword.drop(opts, [:max_retries, :retry_delay_ms])

    # Executa com retry
    query_with_retry(sql_string, params, opts, 1, max_retries, retry_delay_ms)
  end

  # Função auxiliar para executar consulta com retry
  @spec query_with_retry(
          String.t(),
          list(),
          keyword(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer()
        ) :: {:ok, list()} | {:error, Exception.t()}
  defp query_with_retry(sql_string, params, opts, attempt, max_retries, retry_delay_ms) do
    # Cria uma query Exqlite
    query = prepare_query(sql_string)

    # Tenta executar a query usando o DBConnection
    try do
      case DBConnection.prepare_execute(pool_name(), query, params, opts) do
        {:ok, _query_struct, %{rows: rows} = result} ->
          Logger.debug(
            "Consulta bem-sucedida. Linhas: #{inspect(rows)}, Resultado completo: #{inspect(result)}",
            module: __MODULE__
          )

          {:ok, rows}

        # Fallback se o formato do resultado for diferente
        {:ok, _query_struct, result} ->
          Logger.warning(
            "Consulta bem-sucedida mas o formato do resultado não foi %{rows: ...}. Resultado completo: #{inspect(result)}",
            module: __MODULE__
          )

          # Ou talvez um erro, dependendo da rigidez desejada
          {:ok, result}

        {:error, exception} ->
          handle_query_error(
            sql_string,
            params,
            opts,
            attempt,
            max_retries,
            retry_delay_ms,
            exception
          )
      end
    rescue
      exception ->
        handle_query_error(
          sql_string,
          params,
          opts,
          attempt,
          max_retries,
          retry_delay_ms,
          exception
        )
    end
  end

  # Função auxiliar para lidar com erros de consulta
  @spec handle_query_error(
          String.t(),
          list(),
          keyword(),
          non_neg_integer(),
          non_neg_integer(),
          non_neg_integer(),
          Exception.t()
        ) :: {:ok, list()} | {:error, Exception.t()}
  defp handle_query_error(
         sql_string,
         params,
         opts,
         attempt,
         max_retries,
         retry_delay_ms,
         exception
       ) do
    error_message =
      "Falha na consulta. SQL: #{sql_string}, Parâmetros: #{inspect(params)}, Erro: #{inspect(exception)}"

    # Verifica se deve tentar novamente
    if attempt < max_retries and retriable_error?(exception) do
      Logger.warning(
        "#{error_message} - Tentativa #{attempt}/#{max_retries}. Tentando novamente em #{retry_delay_ms}ms...",
        module: __MODULE__
      )

      Process.sleep(retry_delay_ms)
      query_with_retry(sql_string, params, opts, attempt + 1, max_retries, retry_delay_ms)
    else
      if attempt > 1 do
        Logger.error("#{error_message} - Desistindo após #{attempt} tentativas.",
          module: __MODULE__
        )
      else
        Logger.error(error_message, module: __MODULE__)
      end

      {:error, exception}
    end
  end

  @doc """
  Executa uma função dentro de uma transação de banco de dados.

  ## Parâmetros
    * `fun` - Função a ser executada dentro da transação (recebe a conexão como parâmetro)
    * `opts` - Opções adicionais para a transação (opcional)

  ## Retorno
    * `{:ok, result_of_fun}` - Transação confirmada com sucesso
    * `{:error, reason}` - Transação falhou ou foi revertida

  ## Exemplos

      iex> Repo.transaction(fn conn ->
      ...>   DBConnection.prepare_execute(conn, %Exqlite.Query{statement: "INSERT INTO users (name) VALUES (?)"}, ["João"])
      ...>   DBConnection.prepare_execute(conn, %Exqlite.Query{statement: "INSERT INTO profiles (user_id, bio) VALUES (?, ?)"}, [last_id, "Olá, sou João"])
      ...>   "Sucesso!"
      ...> end)
      {:ok, "Sucesso!"}

  Se qualquer operação dentro da função falhar, todas as alterações serão revertidas automaticamente.
  """
  @spec transaction((DBConnection.conn() -> any()), keyword()) :: {:ok, any()} | {:error, any()}
  def transaction(fun, opts \\ []) when is_function(fun, 1) do
    Logger.info("Iniciando transação.", module: __MODULE__)

    case DBConnection.transaction(pool_name(), fun, opts) do
      {:ok, result} ->
        Logger.info("Transação confirmada com sucesso. Resultado: #{inspect(result)}",
          module: __MODULE__
        )

        {:ok, result}

      {:error, reason} ->
        Logger.error("Transação falhou ou foi revertida. Motivo: #{inspect(reason)}",
          module: __MODULE__
        )

        {:error, reason}
    end
  end

  # TODO: Implement Repo.stream/3_or_4 if needed
  # TODO: Implement functions for managing prepared statements if distinct from execute's internal prep is needed
end
