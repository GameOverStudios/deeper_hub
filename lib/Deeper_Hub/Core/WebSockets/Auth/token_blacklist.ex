defmodule Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist do
  @moduledoc """
  Gerencia a blacklist de tokens JWT revogados.

  Este módulo fornece funções para adicionar tokens à blacklist,
  verificar se um token está na blacklist e limpar tokens expirados.
  """

  use GenServer
  alias Deeper_Hub.Core.Logger

  @table_name :token_blacklist
  @cleanup_interval 60 * 60 * 1000 # 1 hora em milissegundos

  # API Pública

  @doc """
  Inicia o serviço de blacklist de tokens.
  """
  def start_link(_opts \\ []) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  @doc """
  Adiciona um token à blacklist.

  ## Parâmetros
    * `token` - Token a ser adicionado à blacklist
    * `expiry` - Timestamp de expiração do token
  """
  def add(token, expiry) do
    GenServer.cast(__MODULE__, {:add, token, expiry})
  end

  @doc """
  Verifica se um token está na blacklist.

  ## Parâmetros
    * `token` - Token a ser verificado

  ## Retorno
    * `true` - Token está na blacklist
    * `false` - Token não está na blacklist
  """
  def is_blacklisted?(token) do
    GenServer.call(__MODULE__, {:is_blacklisted, token})
  end

  @doc """
  Remove tokens expirados da blacklist.
  """
  def cleanup do
    GenServer.cast(__MODULE__, :cleanup)
  end

  # Callbacks do GenServer

  @impl true
  def init(_) do
    # Cria a tabela ETS para armazenar os tokens na blacklist
    :ets.new(@table_name, [:set, :named_table, :public, read_concurrency: true])

    # Agenda a limpeza periódica
    schedule_cleanup()

    Logger.info("Serviço de blacklist de tokens iniciado", %{module: __MODULE__})
    {:ok, %{}}
  end

  @impl true
  def handle_cast({:add, token, expiry}, state) do
    # Calcula o hash do token para economizar espaço
    token_hash = :crypto.hash(:sha256, token) |> Base.encode16()

    # Adiciona o hash do token e sua expiração à tabela
    :ets.insert(@table_name, {token_hash, expiry})

    Logger.debug("Token adicionado à blacklist", %{module: __MODULE__, expiry: expiry})
    {:noreply, state}
  end

  @impl true
  def handle_cast(:cleanup, state) do
    # Obtém o timestamp atual
    now = DateTime.utc_now() |> DateTime.to_unix()

    # Remove tokens expirados
    count = :ets.select_delete(@table_name, [{{:_, :"$1"}, [{:<, :"$1", now}], [true]}])

    Logger.info("Limpeza de tokens expirados concluída", %{module: __MODULE__, count: count})

    # Agenda a próxima limpeza
    schedule_cleanup()

    {:noreply, state}
  end

  @impl true
  def handle_call({:is_blacklisted, token}, _from, state) do
    # Calcula o hash do token
    token_hash = :crypto.hash(:sha256, token) |> Base.encode16()

    # Verifica se o token está na blacklist
    result = :ets.member(@table_name, token_hash)

    {:reply, result, state}
  end

  # Funções privadas

  defp schedule_cleanup do
    Process.send_after(self(), {:cast, :cleanup}, @cleanup_interval)
  end
end
