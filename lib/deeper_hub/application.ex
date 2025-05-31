# lib/deeper_hub/application.ex
defmodule DeeperHub.Application do
  @moduledoc """
  O callback da aplicação para o DeeperHub.

  Este módulo é responsável por iniciar e supervisionar os processos
  principais da aplicação, estabelecendo a árvore de supervisão e
  garantindo a reinicialização adequada dos componentes em caso de falha.
  
  Além disso, realiza tarefas de inicialização como verificação do banco de dados
  e execução de migrações pendentes de forma automática.
  """
  use Application
  require DeeperHub.Logger
  alias DeeperHub.DataAccess.Repo
  
  @impl true
  def start(_type, _args) do
    DeeperHub.Logger.info("Iniciando o sistema DeeperHub...")
    
    # Configura o processo para receber notificações de supervisão
    Process.flag(:trap_exit, true)

    # Verifica e prepara o banco de dados antes de iniciar o supervisor
    prepare_database()

    children = [
      # Lista de processos filhos supervisionados
      # Repositório Ecto para acesso ao banco de dados
      {DeeperHub.DataAccess.Repo, [log_events: true]},
      
      # Outros serviços podem ser adicionados abaixo
      # {DeeperHub.Core.Cache, []},
      # {DeeperHub.Services.Scheduler, []},
    ]

    # Define a estratégia de supervisão
    opts = [
      strategy: :one_for_one, 
      name: DeeperHub.Supervisor,
      # Adiciona funções de callback para eventos de supervisão
      max_restarts: 3,
      max_seconds: 5
    ]

    DeeperHub.Logger.debug("Iniciando a árvore de supervisão...")
    
    # Inicia o supervisor com os processos filhos e opções
    supervisor = Supervisor.start_link(children, opts)
    
    # Registra o resultado da inicialização
    case supervisor do
      {:ok, pid} ->
        DeeperHub.Logger.info("Supervisor iniciado com sucesso. PID: #{inspect(pid)}")
        log_child_processes(pid)
        supervisor
      {:error, reason} ->
        DeeperHub.Logger.error("Falha ao iniciar o supervisor: #{inspect(reason)}")
        supervisor
    end
  end
  
  @doc """
  Verifica e prepara o banco de dados, incluindo verificação de existência e migrações.
  
  Esta função é executada durante a inicialização da aplicação e realiza:
  1. Verificação se o banco de dados existe, criando-o se necessário
  2. Verificação e execução de migrações pendentes
  """
  def prepare_database do
    # Obtém as configurações do repositório
    repo_config = Application.get_env(:deeper_hub, DeeperHub.DataAccess.Repo)
    database_path = Keyword.get(repo_config, :database)
    
    DeeperHub.Logger.debug("Verificando banco de dados em: #{database_path}")
    
    # Garante que o diretório do banco de dados existe
    database_dir = Path.dirname(database_path)
    unless File.exists?(database_dir) do
      DeeperHub.Logger.debug("Criando diretório para o banco de dados: #{database_dir}")
      File.mkdir_p!(database_dir)
    end
    
    # Verifica se o banco de dados existe
    db_exists = File.exists?(database_path)
    DeeperHub.Logger.debug("Status do banco de dados: #{if db_exists, do: "Existe", else: "Não existe"}")
    
    # Tenta criar o banco de dados se não existir
    unless db_exists do
      DeeperHub.Logger.info("Criando banco de dados em: #{database_path}")
      create_database()
    end
    
    # Verifica e executa migrações pendentes
    check_and_run_migrations()
  end
  
  # Cria o banco de dados SQLite utilizando Ecto.
  defp create_database do
    try do
      case Ecto.Migrator.with_repo(Repo, fn _repo -> :ok end) do
        {:ok, :ok, _} -> 
          DeeperHub.Logger.info("Banco de dados criado com sucesso")
        {:ok, result, _} -> 
          DeeperHub.Logger.info("Banco de dados criado com sucesso: #{inspect(result)}")
        {:error, error} -> 
          DeeperHub.Logger.error("Falha ao criar banco de dados: #{inspect(error)}")
      end
    rescue
      e -> DeeperHub.Logger.error("Erro ao criar banco de dados: #{inspect(e)}")
    end
  end
  
  # Verifica se existem migrações pendentes e as executa automaticamente.
  defp check_and_run_migrations do
    DeeperHub.Logger.debug("Verificando migrações pendentes...")
    
    try do
      # Inicia o repositório para operações de migração
      {:ok, _} = Repo.start_link(pool_size: 2, log: false)
      
      # Verifica e executa migrações pendentes
      priv_dir = Application.app_dir(:deeper_hub, "priv/repo/migrations")
      DeeperHub.Logger.debug("Diretório de migrações: #{priv_dir}")
      
      migrations = Ecto.Migrator.migrations(Repo, priv_dir)
      
      case migrations do
        [] -> 
          DeeperHub.Logger.info("Nenhuma migração pendente encontrada")
        migrations -> 
          pending_count = Enum.count(migrations, fn {status, _version, _migration} -> status == :down end)
          if pending_count > 0 do
            DeeperHub.Logger.info("Executando #{pending_count} migrações pendentes...")
            Ecto.Migrator.run(Repo, priv_dir, :up, all: true, log: true)
            DeeperHub.Logger.info("Migrações concluídas com sucesso")
          else
            DeeperHub.Logger.info("Banco de dados está atualizado. Total de migrações: #{length(migrations)}")
          end
      end
    rescue
      e -> 
        stacktrace = __STACKTRACE__
        DeeperHub.Logger.error("Erro ao verificar/executar migrações: #{inspect(e)}")
        DeeperHub.Logger.error("Stack trace: #{inspect(stacktrace)}")
    after
      # Garante que o repositório seja parado, pois será iniciado novamente pela árvore de supervisão
      try do
        Repo.stop()
      rescue
        _ -> :ok
      end
    end
  end
  
  # Registra informações detalhadas sobre os processos filhos do supervisor.
  defp log_child_processes(supervisor_pid) do
    try do
      children = Supervisor.which_children(supervisor_pid)
      DeeperHub.Logger.debug("Processos supervisionados iniciados: #{length(children)}")
      
      Enum.each(children, fn {id, child_pid, type, modules} ->
        DeeperHub.Logger.debug("Processo filho - ID: #{inspect(id)}, PID: #{inspect(child_pid)}, Tipo: #{inspect(type)}, Módulos: #{inspect(modules)}")
      end)
    rescue
      e -> DeeperHub.Logger.error("Erro ao logar processos filhos: #{inspect(e)}")
    end
  end
end
