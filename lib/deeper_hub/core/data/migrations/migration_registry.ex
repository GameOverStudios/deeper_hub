defmodule DeeperHub.Core.Data.Migrations.MigrationRegistry do
  @moduledoc """
  Registro centralizado de migrações disponíveis no sistema.
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
      {"20250603064832340", DeeperHub.Core.Data.Migrations.BxAdsCategoriesTypes},
    ]
  end

  @doc """
  Retorna a lista de seeds disponíveis no sistema.
  """
  def available_seeds do
    [
    ]
  end


  @doc """
  Executa todos os seeds disponíveis.
  """
  def run_seeds do
    Logger.info("Executando seeds...", module: __MODULE__)
    
    Enum.each(available_seeds(), fn seed_module ->
      Logger.info("Executando seed: #{inspect(seed_module)}", module: __MODULE__)
      seed_module.run()
    end)
    
    Logger.info("Seeds executados com sucesso.", module: __MODULE__)
    :ok
  end
end
