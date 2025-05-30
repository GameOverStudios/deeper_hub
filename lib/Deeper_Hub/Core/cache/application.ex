defmodule DeeperHub.Core.Cache.Application do
  @moduledoc """
  Módulo de integração do sistema de cache com a aplicação principal.
  
  Este módulo fornece funções para inicializar o sistema de cache
  durante a inicialização da aplicação DeeperHub. Centraliza a configuração
  do cache para garantir consistência em toda a aplicação.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Inicializa o sistema de cache durante a inicialização da aplicação.
  
  Esta função deve ser chamada a partir do módulo `DeeperHub.Application`.
  Carrega configurações da aplicação para definir parâmetros ideais do cache.
  
  ## Parâmetros
  
    * `opts` - Opções adicionais que substituem as configurações padrão
  
  ## Retorno
  
    * `:ok` - Sistema de cache inicializado com sucesso
    * `{:error, reason}` - Falha na inicialização
  
  ## Exemplos
  
      # Em DeeperHub.Application:
      def start(_type, _args) do
        # ...
        DeeperHub.Core.Cache.Application.initialize()
        # ...
      end
  """
  @spec initialize(keyword()) :: :ok | {:error, any()}
  def initialize(opts \\ []) do
    Logger.info("Inicializando subsistema de cache...", module: __MODULE__)
    
    # Carrega configurações da aplicação
    app_config = Application.get_env(:deeper_hub, :cache, [])
    
    # Mescla opções fornecidas com configurações da aplicação
    # As opções fornecidas têm prioridade
    merged_opts = Keyword.merge(app_config, opts)
    
    # Inicia o supervisor do cache com as opções mescladas
    case DeeperHub.Core.Cache.Supervisor.start_link(merged_opts) do
      {:ok, _pid} ->
        Logger.info("Subsistema de cache inicializado com sucesso", module: __MODULE__)
        :ok
        
      {:error, {:already_started, _pid}} ->
        Logger.warn("Supervisor do cache já estava iniciado", module: __MODULE__)
        :ok
        
      {:error, reason} = error ->
        Logger.error("Falha ao iniciar supervisor do cache: #{inspect(reason)}", module: __MODULE__)
        error
    end
  end
  
  @doc """
  Desativa o subsistema de cache.
  
  Útil durante testes ou quando é necessário reiniciar o sistema de cache.
  
  ## Retorno
  
    * `:ok` - Sistema de cache desativado com sucesso
    * `{:error, reason}` - Falha ao desativar
  """
  @spec shutdown() :: :ok | {:error, any()}
  def shutdown do
    Logger.info("Desativando subsistema de cache...", module: __MODULE__)
    
    case Supervisor.stop(DeeperHub.Core.Cache.Supervisor) do
      :ok ->
        Logger.info("Subsistema de cache desativado com sucesso", module: __MODULE__)
        :ok
      error ->
        Logger.error("Falha ao desativar subsistema de cache: #{inspect(error)}", module: __MODULE__)
        error
    end
  end
end
