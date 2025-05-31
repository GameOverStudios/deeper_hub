defmodule DeeperHub.Scripts.DbReset do
  @moduledoc """
  Script para reiniciar o banco de dados.
  
  Uso: mix run priv/scripts/db_reset.exs
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Repo
  
  def run do
    Logger.info("Iniciando reset do banco de dados...")
    
    # Obtém configurações de ambiente
    env = Mix.env()
    db_path = Application.get_env(:deeper_hub, :database, [])[:database_path] || "databases"
    db_name = Application.get_env(:deeper_hub, :database, [])[:database_name] || "deeper_hub_#{env}.db"
    db_file = Path.join(db_path, db_name)
    
    # Verifica se o banco existe
    if File.exists?(db_file) do
      # Tenta fechar o pool de conexões se estiver ativo
      try do
        if Process.whereis(DeeperHub.DBConnectionPool) do
          Logger.info("Desligando pool de conexões...")
          Supervisor.stop(DeeperHub.DBConnectionPool)
          Logger.info("Pool de conexões desligado.")
          Process.sleep(500)  # Aguarda um momento para garantir o fechamento
        end
      rescue
        _ -> :ok  # Ignora erros caso o pool não esteja ativo
      end
      
      # Remove o arquivo do banco de dados
      Logger.info("Removendo arquivo de banco de dados: #{db_file}")
      case File.rm(db_file) do
        :ok -> 
          Logger.info("Arquivo de banco de dados removido com sucesso.")
          
          # Remove também o arquivo WAL se existir
          wal_file = "#{db_file}-wal"
          if File.exists?(wal_file) do
            File.rm(wal_file)
            Logger.info("Arquivo WAL removido.")
          end
          
          # Remove também o arquivo SHM se existir
          shm_file = "#{db_file}-shm"
          if File.exists?(shm_file) do
            File.rm(shm_file)
            Logger.info("Arquivo SHM removido.")
          end
          
        {:error, reason} ->
          Logger.error("Erro ao remover arquivo de banco de dados: #{inspect(reason)}")
      end
    else
      Logger.info("Arquivo de banco de dados não encontrado: #{db_file}")
    end
    
    # Garante que o diretório de banco de dados exista
    case File.mkdir_p(db_path) do
      :ok -> Logger.info("Diretório de banco de dados verificado/criado: #{db_path}")
      {:error, reason} -> Logger.error("Erro ao criar diretório de banco de dados: #{inspect(reason)}")
    end
    
    # Reinicia o sistema para aplicar as migrações automaticamente
    Logger.info("Reset de banco de dados concluído. Reinicie o aplicativo para aplicar as migrações.")
  end
end

# Executa o script
DeeperHub.Scripts.DbReset.run()
