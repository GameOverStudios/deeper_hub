# Script para executar migrações do banco de dados
IO.puts("Iniciando execução das migrações...")

# Executa as migrações
case DeeperHub.Core.Data.RunMigrations.run() do
  :ok -> 
    IO.puts("Migrações executadas com sucesso!")
  
  {:error, errors} ->
    IO.puts("Falha ao executar algumas migrações:")
    
    Enum.each(errors, fn {:error, migration, reason} ->
      IO.puts("  - #{inspect(migration)}: #{inspect(reason)}")
    end)
    
    exit({:shutdown, 1})
end
