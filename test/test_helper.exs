<<<<<<< HEAD
# Configura o ambiente de teste
ExUnit.start()

# Configuração do banco de dados para testes
Application.put_env(:deeper_hub, Deeper_Hub.Core.Data.Repo, 
  database: "database/test.db",
  pool: Ecto.Adapters.SQL.Sandbox
)

# Inicia o repositório se ainda não estiver iniciado
try do
  {:ok, _} = Deeper_Hub.Core.Data.Repo.start_link()
rescue
  _ -> :ok
end

# Executa as migrações para garantir que o banco de dados está atualizado
# Usando o modo compartilhado para evitar erros de ownership
Ecto.Adapters.SQL.Sandbox.mode(Deeper_Hub.Core.Data.Repo, {:shared, self()})

try do
  Deeper_Hub.Core.Data.Migrations.run_migrations()
rescue
  e -> 
    IO.puts("Aviso: Falha ao executar migrações em test_helper.exs: #{inspect(e)}")
    :ok
end

# Configura o sandbox do Ecto para testes em modo manual
Ecto.Adapters.SQL.Sandbox.mode(Deeper_Hub.Core.Data.Repo, :manual)

# Limpa as métricas antes de cada teste, sem inicializar novamente
try do
  Deeper_Hub.Core.Metrics.clear_all_metrics()
rescue
  _ -> :ok
end
=======
ExUnit.start()
>>>>>>> a7eaa30fe0070442f8e291be40ec02441ff2483a
