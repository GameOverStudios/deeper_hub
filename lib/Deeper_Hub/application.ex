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
      
      # Inicia o supervisor do subsistema de autenticação
      {DeeperHub.Accounts.Auth.Supervisor, []},
      
      # Inicia o supervisor do subsistema de rede (WebSockets, PubSub, etc.)
      {DeeperHub.Core.Network.Supervisor, []},
      
      # Inicia o supervisor do subsistema HTTP
      {DeeperHub.Core.HTTP.Supervisor, []},
      
      # Inicia o supervisor do subsistema de email
      {DeeperHub.Core.Mail.Supervisor, []}
      
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
        
        # Configuração para inicialização do banco de dados
        max_attempts = 5
        wait_time_ms = 500
        
        # Aguarda a inicialização do pool de conexões e verifica a saúde do banco de dados
        DeeperHub.Core.Logger.info("Verificando disponibilidade do banco de dados...")
        
        # Verifica a saúde do banco de dados usando o novo módulo
        case DeeperHub.Core.Data.Repo.HealthCheck.wait_for_database(max_attempts, wait_time_ms) do
          :ok ->
            DeeperHub.Core.Logger.info("Banco de dados disponível. Executando migrações...")
            
            # Tenta inicializar o sistema de migrações
            case DeeperHub.Core.Data.Migrations.initialize() do
              :ok -> 
                DeeperHub.Core.Logger.info("Migrações inicializadas com sucesso.")
                DeeperHub.Core.Logger.info("Sistema DeeperHub completamente inicializado.")
              {:error, reason} ->
                DeeperHub.Core.Logger.error("Falha ao inicializar migrações: #{inspect(reason)}")
            end
            
          {:error, :max_attempts_reached} ->
            DeeperHub.Core.Logger.error("Banco de dados não está disponível após #{max_attempts} tentativas.")
        end
        
        {:ok, pid}
        
      {:error, reason} ->
        DeeperHub.Core.Logger.error("Falha ao iniciar o sistema DeeperHub: #{inspect(reason)}")
        {:error, reason}
    end
  end
end
