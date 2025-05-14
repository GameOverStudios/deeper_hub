defmodule Deeper_Hub.Core.Data.MigrationsTest do
  @moduledoc """
  Testes para o módulo Migrations.
  
  Este módulo testa as funcionalidades de migração do banco de dados,
  garantindo que as migrações sejam executadas corretamente durante
  a inicialização da aplicação.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Migrations
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Data.DatabaseConfig
  
  # Configuração para cada teste
  setup do
    # Configura o banco de dados de teste
    db_config = DatabaseConfig.get_config(:test)
    
    # Garante que o banco de dados de teste existe
    DatabaseConfig.configure(db_config)
    
    # Inicia uma transação para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    
    # Permite o uso de transações aninhadas
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Retorna a configuração do banco de dados para uso nos testes
    {:ok, %{db_config: db_config}}
  end
  
  describe "run_migrations/0" do
    test "executa migrações pendentes com sucesso" do
      # Executa as migrações
      result = Migrations.run_migrations()
      
      # Verifica se as migrações foram executadas com sucesso
      assert result == :ok
    end
    
    test "não falha ao executar migrações já aplicadas" do
      # Executa as migrações uma vez
      Migrations.run_migrations()
      
      # Executa as migrações novamente
      result = Migrations.run_migrations()
      
      # Verifica que não houve erro ao executar migrações já aplicadas
      assert result == :ok
    end
  end
  
  describe "verify_migrations/0" do
    test "verifica se todas as migrações foram aplicadas" do
      # Executa as migrações
      Migrations.run_migrations()
      
      # Verifica se todas as migrações foram aplicadas
      result = Migrations.verify_migrations()
      
      # Verifica que todas as migrações foram aplicadas
      assert result == :ok
    end
  end
  
  describe "get_migration_status/0" do
    test "retorna o status de todas as migrações" do
      # Executa as migrações
      Migrations.run_migrations()
      
      # Obtém o status das migrações
      status = Migrations.get_migration_status()
      
      # Verifica que o status é uma lista não vazia
      assert is_list(status)
      assert length(status) > 0
      
      # Verifica que todas as migrações estão marcadas como aplicadas
      assert Enum.all?(status, fn {_version, state} -> state == :up end)
    end
  end
  
  describe "integração com DatabaseConfig" do
    test "migrações são executadas quando o banco de dados é criado", %{db_config: db_config} do
      # Simula a criação de um novo banco de dados
      # Primeiro, remove o banco de dados existente
      File.rm(db_config.database)
      
      # Configura o banco de dados novamente (isso deve criar um novo banco de dados)
      DatabaseConfig.configure(db_config)
      
      # Verifica se o banco de dados existe
      assert File.exists?(db_config.database)
      
      # Verifica se as migrações foram aplicadas verificando se a tabela de esquema existe
      query = "SELECT count(*) FROM sqlite_master WHERE type='table' AND name='schema_migrations'"
      result = Ecto.Adapters.SQL.query!(Repo, query, [])
      
      # Extrai o resultado da consulta
      [[count]] = result.rows
      
      # Verifica que a tabela schema_migrations existe
      assert count > 0
    end
  end
  
  describe "rollback_migrations/1" do
    test "reverte migrações corretamente" do
      # Executa todas as migrações
      Migrations.run_migrations()
      
      # Obtém o status das migrações antes do rollback
      status_before = Migrations.get_migration_status()
      
      # Reverte a última migração
      Migrations.rollback_migrations(1)
      
      # Obtém o status das migrações após o rollback
      status_after = Migrations.get_migration_status()
      
      # Verifica que há uma migração a menos aplicada
      applied_before = Enum.count(status_before, fn {_version, state} -> state == :up end)
      applied_after = Enum.count(status_after, fn {_version, state} -> state == :up end)
      
      assert applied_after == applied_before - 1
    end
  end
  
  describe "reset_migrations/0" do
    test "reverte e reaplicada todas as migrações" do
      # Executa todas as migrações
      Migrations.run_migrations()
      
      # Obtém o status das migrações antes do reset
      status_before = Migrations.get_migration_status()
      
      # Reseta todas as migrações
      Migrations.reset_migrations()
      
      # Obtém o status das migrações após o reset
      status_after = Migrations.get_migration_status()
      
      # Verifica que o número de migrações aplicadas é o mesmo
      applied_before = Enum.count(status_before, fn {_version, state} -> state == :up end)
      applied_after = Enum.count(status_after, fn {_version, state} -> state == :up end)
      
      assert applied_after == applied_before
    end
  end
end
