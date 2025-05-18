defmodule Deeper_Hub.Core.WebSockets.Auth.TokenBlacklist do
  @moduledoc """
  Serviço para gerenciamento da blacklist de tokens.
  
  Este módulo implementa uma blacklist de tokens usando ETS (Erlang Term Storage)
  para armazenamento em memória de tokens revogados e um processo GenServer
  para realizar a limpeza periódica de tokens expirados.
  """
  
  use GenServer
  alias Deeper_Hub.Core.Logger
  
  @table_name :token_blacklist
  @cleanup_interval 60 * 60 * 1000 # 1 hora em milissegundos
  
  # API Pública

  @doc """
  Inicia o serviço de blacklist de tokens.
  
  ## Parâmetros
  
    - `opts`: Opções para o serviço (opcional)
  
  ## Retorno
  
    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link(opts \\ []) do
    GenServer.start_link(__MODULE__, opts, name: __MODULE__)
  end
  
  @doc """
  Inicializa a blacklist.
  
  ## Retorno
  
    - `:ok`
  """
  def init do
    # Cria a tabela ETS se não existir
    if :ets.whereis(@table_name) == :undefined do
      :ets.new(@table_name, [:set, :public, :named_table])
      Logger.info("Blacklist de tokens inicializada", %{module: __MODULE__})
    end
    
    :ok
  end

  @doc """
  Limpa tokens expirados da blacklist.
  
  ## Retorno
  
    - Número de tokens removidos
  """
  def cleanup_expired_tokens do
    GenServer.cast(__MODULE__, :cleanup)
  end
  
  # Callbacks do GenServer
  
  @impl true
  def init(_opts) do
    # Cria a tabela ETS se não existir
    if :ets.whereis(@table_name) == :undefined do
      :ets.new(@table_name, [:set, :public, :named_table])
    end
    
    # Agenda a primeira limpeza
    schedule_cleanup()
    
    Logger.info("Serviço de blacklist de tokens iniciado", %{module: __MODULE__})
    {:ok, %{}}
  end
  
  @impl true
  def handle_cast({:add, token, expiry}, state) do
    :ets.insert(@table_name, {token, expiry})
    
    Logger.info("Token adicionado à blacklist", %{
      module: __MODULE__,
      token_hash: hash_token(token),
      expiry: expiry
    })
    
    {:noreply, state}
  end
  
  @impl true
  def handle_cast({:remove, token}, state) do
    :ets.delete(@table_name, token)
    {:noreply, state}
  end
  
  @impl true
  def handle_cast(:cleanup, state) do
    # Obtém o timestamp atual
    now = DateTime.utc_now() |> DateTime.to_unix()
    
    # Obtém todos os tokens da blacklist
    tokens = :ets.tab2list(@table_name)
    
    # Filtra tokens expirados
    expired_tokens = Enum.filter(tokens, fn {_token, expiry} ->
      expiry < now
    end)
    
    # Remove tokens expirados
    Enum.each(expired_tokens, fn {token, _expiry} ->
      :ets.delete(@table_name, token)
    end)
    
    # Registra a limpeza
    count = length(expired_tokens)
    
    if count > 0 do
      Logger.info("Tokens expirados removidos da blacklist", %{
        module: __MODULE__,
        count: count
      })
    end
    
    # Agenda a próxima limpeza
    schedule_cleanup()
    
    {:noreply, state}
  end
  
  @impl true
  def handle_call({:contains, token}, _from, state) do
    result = case :ets.lookup(@table_name, token) do
      [{^token, _expiry}] -> true
      [] -> false
    end
    
    {:reply, result, state}
  end
  
  @impl true
  def handle_call({:list}, _from, state) do
    tokens = :ets.tab2list(@table_name)
    {:reply, tokens, state}
  end
  

  
  # Funções privadas
  
  defp schedule_cleanup do
    Process.send_after(self(), {:cast, :cleanup}, @cleanup_interval)
  end
  
  # Gera um hash do token para fins de log
  defp hash_token(token) do
    :crypto.hash(:sha256, token)
    |> Base.encode16(case: :lower)
    |> String.slice(0, 8)
  end
  
  # API Pública para operações na blacklist
  
  @doc """
  Adiciona um token à blacklist.
  
  ## Parâmetros
  
    - `token`: Token a ser adicionado
    - `expiry`: Timestamp de expiração do token
    
  ## Retorno
  
    - `:ok`
  """
  def add(token, expiry) do
    GenServer.cast(__MODULE__, {:add, token, expiry})
  end
  
  @doc """
  Verifica se um token está na blacklist.
  
  ## Parâmetros
  
    - `token`: Token a ser verificado
    
  ## Retorno
  
    - `true` se o token estiver na blacklist
    - `false` caso contrário
  """
  def contains?(token) do
    GenServer.call(__MODULE__, {:contains, token})
  end
  
  @doc """
  Remove um token da blacklist.
  
  ## Parâmetros
  
    - `token`: Token a ser removido
    
  ## Retorno
  
    - `:ok`
  """
  def remove(token) do
    GenServer.cast(__MODULE__, {:remove, token})
  end
  
  @doc """
  Lista todos os tokens na blacklist.
  
  ## Retorno
  
    - Lista de tuplas `{token, expiry}`
  """
  def list do
    GenServer.call(__MODULE__, {:list})
  end
end
