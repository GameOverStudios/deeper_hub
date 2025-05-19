defmodule DeeperHub.Core.Security.Storage do
  @moduledoc """
  Módulo de armazenamento ETS personalizado para o PlugAttack.

  Este módulo implementa uma interface compatível com o PlugAttack
  para armazenamento de contadores de requisições.
  """

  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger

  @table_name :deeper_hub_attack_storage
  @cleanup_interval 60_000 # 1 minuto

  @doc """
  Inicializa o armazenamento ETS.

  ## Retorno

  - Referência ao armazenamento
  """
  def init do
    # Cria a tabela ETS se ainda não existir
    try do
      :ets.new(@table_name, [:named_table, :public, :set, {:read_concurrency, true}, {:write_concurrency, true}])
      Logger.debug("Tabela ETS #{@table_name} criada com sucesso", module: __MODULE__)
    rescue
      ArgumentError ->
        Logger.debug("Tabela ETS #{@table_name} já existe", module: __MODULE__)
    end

    # Agenda a limpeza periódica
    schedule_cleanup()

    # Retorna uma referência ao armazenamento
    @table_name
  end

  @doc """
  Incrementa o contador para uma chave específica.

  ## Parâmetros

  - `key` - Chave para incrementar
  - `increment` - Valor a incrementar (padrão: 1)
  - `expires_in` - Tempo em milissegundos até a expiração

  ## Retorno

  - Valor atual do contador
  """
  def increment(key, increment \\ 1, expires_in) do
    now = :os.system_time(:millisecond)
    expires_at = now + expires_in

    # Tenta atualizar o contador se a chave já existir
    case :ets.lookup(@table_name, key) do
      [{^key, count, old_expires_at}] when old_expires_at > now ->
        # Chave existe e não expirou, incrementa o contador
        new_count = count + increment
        :ets.insert(@table_name, {key, new_count, expires_at})
        new_count

      _ ->
        # Chave não existe ou expirou, cria uma nova entrada
        :ets.insert(@table_name, {key, increment, expires_at})
        increment
    end
  end

  # Agenda a limpeza periódica de entradas expiradas.
  defp schedule_cleanup do
    # Agenda a limpeza para executar após o intervalo definido
    Process.send_after(self(), :cleanup_expired_entries, @cleanup_interval)
  end

  @doc """
  Manipulador de mensagem para limpeza de entradas expiradas.
  """
  def handle_info(:cleanup_expired_entries, state) do
    cleanup_expired_entries()
    schedule_cleanup()
    {:noreply, state}
  end

  @doc """
  Remove entradas expiradas da tabela ETS.
  """
  def cleanup_expired_entries do
    now = :os.system_time(:millisecond)

    # Seleciona todas as chaves expiradas
    expired_keys = :ets.foldl(
      fn {key, _count, expires_at}, acc ->
        if expires_at < now do
          [key | acc]
        else
          acc
        end
      end,
      [],
      @table_name
    )

    # Remove as chaves expiradas
    Enum.each(expired_keys, fn key -> :ets.delete(@table_name, key) end)

    Logger.debug("Limpeza de entradas expiradas concluída. Removidas: #{length(expired_keys)}",
                 module: __MODULE__)
  end
end
