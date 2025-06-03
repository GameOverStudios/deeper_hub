defmodule DeeperHub.Core.Data.RunMigrations do
  @moduledoc """
  Módulo para executar as migrações e seeds do banco de dados.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Migrations.MigrationRegistry

  @doc """
  Executa todas as migrações disponíveis e depois os seeds.
  """
  def run do
    Logger.info("Iniciando execução de migrações...", module: __MODULE__)
    
    # Lista de migrações a serem executadas na ordem correta
    migrations = [
      DeeperHub.Core.Data.Migrations.BxAdsCategoriesTypes
    ]
    
    # Executa cada migração
    results = Enum.map(migrations, fn migration ->
      Logger.info("Executando migração: #{inspect(migration)}", module: __MODULE__)
      
      case migration.up() do
        :ok -> 
          Logger.info("Migração #{inspect(migration)} executada com sucesso.", module: __MODULE__)
          {:ok, migration}
        
        {:error, reason} ->
          Logger.error("Falha ao executar migração #{inspect(migration)}: #{inspect(reason)}", module: __MODULE__)
          {:error, migration, reason}
      end
    end)
    
    # Verifica se todas as migrações foram executadas com sucesso
    case Enum.filter(results, fn
      {:ok, _} -> false
      {:error, _, _} -> true
    end) do
      [] -> 
        Logger.info("Todas as migrações foram executadas com sucesso!", module: __MODULE__)
        # Executa os seeds após as migrações bem-sucedidas
        run_seeds()
        
      errors ->
        error_count = length(errors)
        Logger.error("#{error_count} migrações falharam durante a execução.", module: __MODULE__)
        {:error, errors}
    end
  end
  
  @doc """
  Executa todos os seeds disponíveis.
  """
  def run_seeds do
    Logger.info("Iniciando execução de seeds...", module: __MODULE__)
    
    try do
      # Executa os seeds usando o registro de migrações
      MigrationRegistry.run_seeds()
      Logger.info("Todos os seeds foram executados com sucesso!", module: __MODULE__)
      :ok
    rescue
      e ->
        Logger.error("Falha ao executar seeds: #{inspect(e)}", module: __MODULE__)
        {:error, e}
    end
  end
end
