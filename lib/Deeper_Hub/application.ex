# lib/deeper_hub/application.ex
defmodule DeeperHub.Application do
  @moduledoc """
  O callback da aplicação para o DeeperHub.
  Este módulo é responsável por iniciar e supervisionar os processos
  principais da aplicação.
  """
  use Application

  # alias DeeperHub.Core.Logger # Removido para depuração
  require DeeperHub.Core.Logger

  @impl true
  def start(_type, _args) do
    DeeperHub.Core.Logger.info("Iniciando o sistema DeeperHub...")

    # Define a árvore de supervisão principal da aplicação
    children = [
      # Inicia o supervisor do repositório para gerenciar o pool de conexões do banco de dados
      {DeeperHub.Core.Data.Repo.Supervisor, []},
      
      # Inicia o supervisor do subsistema de segurança
      {DeeperHub.Core.Security.Supervisor, []},
      
      # Inicia o supervisor do subsistema de rede (WebSockets, PubSub, etc.)
      {DeeperHub.Core.Network.Supervisor, []},
      
      # Inicia o supervisor do subsistema HTTP
      {DeeperHub.Core.HTTP.Supervisor, []}
      
      # Outros supervisores podem ser adicionados aqui conforme necessário
    ]
    
    # Configuração do supervisor principal
    # Obtém configurações de resiliência do ambiente
    supervisor_config = Application.get_env(:deeper_hub, :supervisor, [])
    
    # Define opções do supervisor com valores padrão caso não estejam configurados
    opts = [
      strategy: Keyword.get(supervisor_config, :strategy, :one_for_one),
      name: DeeperHub.Supervisor,
      max_restarts: Keyword.get(supervisor_config, :max_restarts, 3),
      max_seconds: Keyword.get(supervisor_config, :max_seconds, 5)
    ]
    
    # Inicia o supervisor principal
    result = Supervisor.start_link(children, opts)
    
    # Processa o resultado da inicialização do supervisor
    case result do
      {:ok, pid} ->
        DeeperHub.Core.Logger.info("Supervisor principal iniciado com sucesso.")
        
        # Tenta inicializar o sistema de migrações diretamente, sem usar um supervisor
        # Isso garante que as migrações só serão executadas após o repositório estar completamente inicializado
        migrate_result = DeeperHub.Core.Data.Migrations.initialize()
        
        case migrate_result do
          :ok -> 
            DeeperHub.Core.Logger.info("Migrações inicializadas com sucesso.")
            DeeperHub.Core.Logger.info("Sistema DeeperHub completamente inicializado.")
          {:error, reason} ->
            DeeperHub.Core.Logger.error("Falha ao inicializar migrações: #{inspect(reason)}")
        end
        
        {:ok, pid}
        
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao iniciar o sistema DeeperHub: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
