defmodule Deeper_Hub.Core.WebSockets.Security.BruteForceProtection do
  @moduledoc """
  Proteção contra ataques de Força Bruta para WebSockets.

  Este módulo implementa mecanismos para prevenir ataques de força bruta,
  como tentativas repetidas de login ou adivinhação de credenciais.
  """

  alias Deeper_Hub.Core.Logger

  # Configurações padrão
  @default_max_attempts 5      # Número máximo de tentativas falhas permitidas
  @default_lockout_time 900_000 # Tempo de bloqueio em milissegundos (15 minutos)
  @default_window_time 300_000  # Janela de tempo para contagem de tentativas (5 minutos)

  # Tabela ETS para armazenar contadores de tentativas
  @ets_table :brute_force_protection_counters

  @doc """
  Inicializa o módulo de proteção contra força bruta.

  Deve ser chamado durante a inicialização da aplicação.

  ## Retorno

    - `:ok` se a inicialização for bem-sucedida
  """
  def init do
    # Cria a tabela ETS se não existir
    if :ets.info(@ets_table) == :undefined do
      :ets.new(@ets_table, [:named_table, :set, :public])
    end

    # Inicia o processo de limpeza periódica
    spawn(fn -> cleanup_loop() end)

    :ok
  end

  @doc """
  Registra uma tentativa de autenticação.

  ## Parâmetros

    - `identifier`: Identificador para a tentativa (ex: username, IP)
    - `success`: Indica se a tentativa foi bem-sucedida
    - `opts`: Opções adicionais
      - `:max_attempts` - Número máximo de tentativas (padrão: 5)
      - `:lockout_time` - Tempo de bloqueio em ms (padrão: 900000)

  ## Retorno

    - `{:ok, attempts_left}` se ainda houver tentativas disponíveis
    - `{:error, :account_locked, retry_after}` se a conta estiver bloqueada
  """
  def record_attempt(identifier, success, opts \\ []) do
    max_attempts = Keyword.get(opts, :max_attempts, @default_max_attempts)
    lockout_time = Keyword.get(opts, :lockout_time, @default_lockout_time)

    # Verifica se o identificador está bloqueado
    case get_lockout_info(identifier) do
      {:locked, unlock_time} ->
        current_time = :os.system_time(:millisecond)
        retry_after = max(0, unlock_time - current_time)

        Logger.warn("Tentativa de autenticação em conta bloqueada", %{
          module: __MODULE__,
          identifier: identifier,
          retry_after: retry_after
        })

        {:error, :account_locked, retry_after}

      :not_locked ->
        if success do
          # Tentativa bem-sucedida, reseta o contador
          reset_attempts(identifier)

          Logger.info("Autenticação bem-sucedida, contador resetado", %{
            module: __MODULE__,
            identifier: identifier
          })

          {:ok, max_attempts}
        else
          # Tentativa falha, incrementa o contador
          attempts = increment_attempts(identifier)

          attempts_left = max_attempts - attempts

          if attempts_left <= 0 do
            # Bloqueia a conta
            lock_account(identifier, lockout_time)

            Logger.warn("Conta bloqueada após múltiplas tentativas falhas", %{
              module: __MODULE__,
              identifier: identifier,
              attempts: attempts,
              lockout_time: lockout_time
            })

            {:error, :account_locked, lockout_time}
          else
            Logger.info("Tentativa de autenticação falha", %{
              module: __MODULE__,
              identifier: identifier,
              attempts: attempts,
              attempts_left: attempts_left
            })

            {:ok, attempts_left}
          end
        end
    end
  end

  @doc """
  Verifica se um identificador está bloqueado.

  ## Parâmetros

    - `identifier`: Identificador a ser verificado

  ## Retorno

    - `{:locked, unlock_time}` se o identificador estiver bloqueado
    - `:not_locked` se o identificador não estiver bloqueado
  """
  def get_lockout_info(identifier) do
    case :ets.lookup(@ets_table, {:locked, identifier}) do
      [{_, unlock_time}] ->
        current_time = :os.system_time(:millisecond)

        if current_time >= unlock_time do
          # O bloqueio expirou, remove-o
          unlock_account(identifier)
          :not_locked
        else
          {:locked, unlock_time}
        end

      [] ->
        :not_locked
    end
  end

  @doc """
  Bloqueia uma conta temporariamente.

  ## Parâmetros

    - `identifier`: Identificador da conta a ser bloqueada
    - `duration`: Duração do bloqueio em milissegundos (padrão: 15 minutos)

  ## Retorno

    - `:ok` se o bloqueio for bem-sucedido
  """
  def lock_account(identifier, duration \\ @default_lockout_time) do
    current_time = :os.system_time(:millisecond)
    unlock_time = current_time + duration

    :ets.insert(@ets_table, {{:locked, identifier}, unlock_time})

    Logger.info("Conta bloqueada temporariamente", %{
      module: __MODULE__,
      identifier: identifier,
      duration: duration,
      unlock_time: unlock_time
    })

    :ok
  end

  @doc """
  Desbloqueia uma conta.

  ## Parâmetros

    - `identifier`: Identificador da conta a ser desbloqueada

  ## Retorno

    - `:ok` se o desbloqueio for bem-sucedido
  """
  def unlock_account(identifier) do
    :ets.delete(@ets_table, {:locked, identifier})
    reset_attempts(identifier)

    Logger.info("Conta desbloqueada", %{
      module: __MODULE__,
      identifier: identifier
    })

    :ok
  end

  @doc """
  Bloqueia uma conta permanentemente (alias para lock_account).

  ## Parâmetros

    - `identifier`: Identificador da conta a ser bloqueada

  ## Retorno

    - `:ok` se o bloqueio for bem-sucedido
  """
  def block_account(identifier) do
    # Usa um tempo de bloqueio muito longo (1 ano)
    lock_account(identifier, 365 * 24 * 60 * 60 * 1000)
  end

  @doc """
  Desbloqueia uma conta (alias para unlock_account).

  ## Parâmetros

    - `identifier`: Identificador da conta a ser desbloqueada

  ## Retorno

    - `:ok` se o desbloqueio for bem-sucedido
  """
  def unblock_account(identifier) do
    unlock_account(identifier)
  end

  @doc """
  Obtém o número atual de tentativas falhas para um identificador.

  ## Parâmetros

    - `identifier`: Identificador a ser verificado

  ## Retorno

    - `count` número de tentativas falhas
  """
  def get_attempts(identifier) do
    current_time = :os.system_time(:millisecond)
    window_start = current_time - @default_window_time

    case :ets.lookup(@ets_table, {:attempts, identifier}) do
      [{_, _attempts, timestamps}] ->
        # Filtra timestamps dentro da janela atual
        current_timestamps = Enum.filter(timestamps, fn ts -> ts >= window_start end)
        length(current_timestamps)

      [] ->
        0
    end
  end

  @doc """
  Alias para get_attempts para compatibilidade com os testes.

  ## Parâmetros

    - `ip`: Endereço IP
    - `username`: Nome de usuário

  ## Retorno

    - Número de tentativas registradas
  """
  def get_attempt_count(ip, username) do
    # Combina IP e username para criar um identificador único
    identifier = "#{ip}:#{username}"
    get_attempts(identifier)
  end

  @doc """
  Verifica se um login é permitido para um IP e usuário específicos.

  ## Parâmetros

    - `ip`: Endereço IP
    - `username`: Nome de usuário

  ## Retorno

    - `{:ok, attempts_left}` se o login for permitido
    - `{:error, reason, retry_after}` se o login não for permitido
  """
  def check_login_allowed(ip, username) do
    # Combina IP e username para criar um identificador único
    identifier = "#{ip}:#{username}"

    # Verifica se o identificador está bloqueado
    case get_lockout_info(identifier) do
      {:locked, unlock_time} ->
        current_time = :os.system_time(:millisecond)
        retry_after = max(0, unlock_time - current_time)
        {:error, "Too many failed login attempts", retry_after}

      :not_locked ->
        # Verifica o número de tentativas
        attempts = get_attempts(identifier)
        attempts_left = @default_max_attempts - attempts

        if attempts_left > 0 do
          {:ok, attempts_left}
        else
          # Bloqueia a conta se atingiu o limite
          lock_account(identifier)
          {:error, "Too many failed login attempts", @default_lockout_time}
        end
    end
  end

  @doc """
  Verifica o status de uma conta.

  ## Parâmetros

    - `account_id`: ID da conta a ser verificada

  ## Retorno

    - `{:ok, status}` se a conta estiver disponível
    - `{:error, reason, retry_after}` se a conta estiver bloqueada
  """
  def check_account_status(account_id) do
    case get_lockout_info(account_id) do
      {:locked, unlock_time} ->
        current_time = :os.system_time(:millisecond)
        retry_after = max(0, unlock_time - current_time)
        {:error, "Account is locked", retry_after}

      :not_locked ->
        {:ok, :active}
    end
  end

  @doc """
  Registra uma tentativa de login e atualiza contadores.

  ## Parâmetros

    - `ip`: Endereço IP
    - `username`: Nome de usuário
    - `success`: Se a tentativa foi bem-sucedida

  ## Retorno

    - `:ok`
  """
  def track_login_attempt(ip, username, success) do
    # Converte a tupla de IP para string no formato "x.x.x.x"
    ip_str = if is_tuple(ip) do
      ip |> Tuple.to_list() |> Enum.join(".")
    else
      to_string(ip)
    end

    identifier = "#{ip_str}:#{username}"

    # Registra a tentativa
    record_attempt(identifier, success)
    :ok
  end

  @doc """
  Limpa todos os contadores e bloqueios.

  ## Retorno

    - `:ok`
  """
  def reset_state do
    # Limpa a tabela ETS
    :ets.delete_all_objects(@ets_table)
    :ok
  end

  # Funções privadas

  defp increment_attempts(identifier) do
    current_time = :os.system_time(:millisecond)
    window_start = current_time - @default_window_time

    # Obtém ou cria o contador para este identificador
    {attempts, timestamps} = case :ets.lookup(@ets_table, {:attempts, identifier}) do
      [{_, _count, ts}] ->
        # Filtra timestamps dentro da janela atual
        current_ts = Enum.filter(ts, fn t -> t >= window_start end)
        {length(current_ts), current_ts}

      [] ->
        {0, []}
    end

    # Incrementa o contador
    new_timestamps = [current_time | timestamps]
    new_attempts = attempts + 1

    :ets.insert(@ets_table, {{:attempts, identifier}, new_attempts, new_timestamps})

    new_attempts
  end

  defp reset_attempts(identifier) do
    :ets.delete(@ets_table, {:attempts, identifier})
    :ok
  end

  defp cleanup_loop do
    # Remove entradas expiradas periodicamente
    cleanup_expired_entries()

    # Executa novamente após um intervalo
    :timer.sleep(60_000) # 1 minuto
    cleanup_loop()
  end

  defp cleanup_expired_entries do
    current_time = :os.system_time(:millisecond)
    window_start = current_time - @default_window_time

    # Limpa contadores expirados
    :ets.match(@ets_table, {{:attempts, :'$1'}, :'$2', :'$3'})
    |> Enum.each(fn [identifier, _count, timestamps] ->
      current_timestamps = Enum.filter(timestamps, fn ts -> ts >= window_start end)

      if current_timestamps == [] do
        # Remove entradas sem timestamps recentes
        :ets.delete(@ets_table, {:attempts, identifier})
      else
        # Atualiza com apenas timestamps recentes
        :ets.insert(@ets_table, {{:attempts, identifier}, length(current_timestamps), current_timestamps})
      end
    end)

    # Limpa bloqueios expirados
    :ets.match(@ets_table, {{:locked, :'$1'}, :'$2'})
    |> Enum.each(fn [identifier, unlock_time] ->
      if current_time >= unlock_time do
        unlock_account(identifier)
      end
    end)
  end
end
