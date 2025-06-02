defmodule DeeperHub.Core.Data.Migrations.Seeds.SeedManager do
  @moduledoc """
  Gerenciador de seeds para o banco de dados.
  Executa todos os seeds em sequência.
  """

  @doc """
  Executa todos os seeds.
  """
  def run do
    IO.puts("Iniciando execução de todos os seeds...")
    
    # Lista de todos os seeds
    seeds = [
      {{SEED_MODULES}}
    ]
    
    # Executar cada seed
    Enum.each(seeds, fn seed ->
      IO.puts("\nExecutando seed: #{seed}")
      seed.run()
    end)
    
    IO.puts("\nTodos os seeds foram executados com sucesso!")
  end
end
