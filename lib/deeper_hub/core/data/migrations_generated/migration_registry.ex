defmodule DeeperHub.Core.Data.Migrations.MigrationRegistry do
  @moduledoc """
  Registro centralizado de migrações e seeds disponíveis no sistema.
  Este módulo é gerado e atualizado automaticamente pelo gerador.
  """

  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Retorna a lista de migrações disponíveis no sistema.
  Cada migração é representada por uma tupla {versão, módulo}.
  """
  def available_migrations do
    [
      {"20250603015706", DeeperHub.Core.Data.Migrations.BxAdsCategoriesTypes},
    ]
  end

  @doc """
  Retorna a lista de seeds disponíveis no sistema.
  """
  def available_seeds do
    [
      DeeperHub.Core.Data.Migrations.Seeds.SeedBxAdsCategoriesTypes,
    ]
  end

  @doc """
  Executa todos os seeds disponíveis.
  """
  def run_seeds do
    Logger.info("Iniciando execução de seeds...", module: __MODULE__)
    
    results = Enum.map(available_seeds(), fn seed_module ->
      Logger.info("Executando seed: #{inspect(seed_module)}", module: __MODULE__)
      
      try do
        case apply(seed_module, :run, []) do
          :ok -> 
            Logger.info("Seed #{inspect(seed_module)} executado com sucesso.", module: __MODULE__)
            {:ok, seed_module}
          
          {:error, reason} ->
            Logger.error("Falha ao executar seed #{inspect(seed_module)}: #{inspect(reason)}", module: __MODULE__)
            {:error, seed_module, reason}
        end
      rescue
        e ->
          Logger.error("Exceção ao executar seed #{inspect(seed_module)}: #{inspect(e)}", module: __MODULE__)
          {:error, seed_module, e}
      end
    end)
    
    # Verifica se todos os seeds foram executados com sucesso
    case Enum.filter(results, fn
      {:ok, _} -> false
      {:error, _, _} -> true
    end) do
      [] -> 
        Logger.info("Todos os seeds foram executados com sucesso!", module: __MODULE__)
        :ok
        
      errors ->
        error_count = length(errors)
        Logger.error("#{error_count} seeds falharam durante a execução.", module: __MODULE__)
        {:error, errors}
    end
  end
end
