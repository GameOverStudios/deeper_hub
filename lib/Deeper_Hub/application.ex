defmodule DeeperHub.Application do
  @moduledoc """
  Módulo de aplicação principal para o DeeperHub.
  Responsável por gerenciar a inicialização e supervisão dos processos da aplicação.
  """
  use Application
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DatabaseConfig
  alias Deeper_Hub.Core.Data.Migrations
  alias Deeper_Hub.Core.Data.Repo

  @impl true
  def start(_type, _args) do
    # Inicializa o banco de dados
    Logger.info("Inicializando aplicação DeeperHub", %{module: __MODULE__})
    
    # Sistema de métricas foi removido
    
    # Configura o banco de dados e verifica se ele existe
    case DatabaseConfig.configure() do
      :ok ->
        # Banco de dados configurado com sucesso, verificamos se existe
        config = DatabaseConfig.get_config()
        db_exists = DatabaseConfig.database_exists?(config)
        
        if db_exists do
          # Banco de dados já existe, verificamos se há migrações pendentes
          Logger.info("Banco de dados existente, verificando migrações pendentes", %{module: __MODULE__})
        else
          # Banco de dados acabou de ser criado, executamos as migrações iniciais
          Logger.info("Banco de dados criado, executando migrações iniciais", %{module: __MODULE__})
        end
        
        # Em ambos os casos, executamos as migrações para garantir que o banco está atualizado
        case Migrations.run_migrations() do
          :ok -> Logger.info("Migrações executadas com sucesso", %{module: __MODULE__})
          {:error, reason} -> Logger.error("Falha ao executar migrações", %{module: __MODULE__, error: reason})
        end
      
      {:error, reason} ->
        # Erro ao configurar o banco de dados
        Logger.error("Falha ao configurar o banco de dados", %{module: __MODULE__, error: reason})
    end
    
    children = [
      # Adiciona o repositório Ecto à árvore de supervisão
      Repo,
      
      # Adiciona o gerenciador de cache do repositório
      {Deeper_Hub.Core.Data.Repository, []}
    ]

    opts = [strategy: :one_for_one, name: DeeperHub.Supervisor]
    
    # Inicia a árvore de supervisão
    Supervisor.start_link(children, opts)
  end
end
