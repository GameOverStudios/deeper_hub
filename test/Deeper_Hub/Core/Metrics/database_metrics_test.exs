defmodule Deeper_Hub.Core.Metrics.DatabaseMetricsTest do
  @moduledoc """
  Testes para o módulo DatabaseMetrics.
  
  Este módulo testa as funcionalidades de coleta e análise de métricas
  relacionadas a operações de banco de dados.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Metrics
  alias Deeper_Hub.Core.Metrics.DatabaseMetrics
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Schemas.User
  
  # Configuração para cada teste
  setup do
    # Limpa todas as métricas antes de cada teste
    Metrics.clear_all_metrics()
    
    # Inicia uma transação para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    
    # Permite o uso de transações aninhadas
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Limpa a tabela para garantir um estado conhecido
    Repo.delete_all(User)
    
    # Dados de teste
    valid_user = %{
      username: "testuser",
      email: "test@example.com",
      password: "password123"
    }
    
    # Retorna os dados para uso nos testes
    {:ok, %{valid_user: valid_user}}
  end
  
  describe "record_operation_time/3" do
    test "registra o tempo de execução de uma operação" do
      # Registra o tempo de uma operação
      DatabaseMetrics.record_operation_time(:insert, User, 1_000_000_000) # 1 segundo em nanossegundos
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o tempo foi registrado corretamente
      assert metrics[:users_insert_time] != nil
      assert metrics[:users_insert_time][:total] > 0
    end
    
    test "atualiza o tempo médio corretamente" do
      # Registra o tempo de várias operações
      DatabaseMetrics.record_operation_time(:insert, User, 1_000_000_000) # 1 segundo
      DatabaseMetrics.record_operation_time(:insert, User, 3_000_000_000) # 3 segundos
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o tempo médio foi calculado corretamente
      assert metrics[:users_insert_avg_time] != nil
      assert metrics[:users_insert_avg_time][:last_value] > 0
    end
  end
  
  describe "record_operation_result/3" do
    test "registra o resultado de uma operação bem-sucedida" do
      # Registra um resultado bem-sucedido
      DatabaseMetrics.record_operation_result(:insert, User, {:ok, %User{}})
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o resultado foi registrado corretamente
      assert metrics[:users_insert_success] != nil
      assert metrics[:users_insert_success][:count] == 1
    end
    
    test "registra o resultado de uma operação com erro" do
      # Registra um resultado com erro
      DatabaseMetrics.record_operation_result(:insert, User, {:error, "error"})
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o resultado foi registrado corretamente
      assert metrics[:users_insert_error] != nil
      assert metrics[:users_insert_error][:count] == 1
    end
    
    test "registra o resultado de uma operação desconhecida" do
      # Registra um resultado desconhecido
      DatabaseMetrics.record_operation_result(:insert, User, :unknown)
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o resultado foi registrado corretamente
      assert metrics[:users_insert_unknown] != nil
      assert metrics[:users_insert_unknown][:count] == 1
    end
  end
  
  describe "record_result_size/3" do
    test "registra o tamanho de um resultado" do
      # Registra o tamanho de um resultado
      DatabaseMetrics.record_result_size(User, :list, 10)
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o tamanho foi registrado corretamente
      assert metrics[:users_list_result_size] != nil
      assert metrics[:users_list_result_size][:last_value] == 10
    end
    
    test "atualiza o tamanho máximo corretamente" do
      # Registra o tamanho de vários resultados
      DatabaseMetrics.record_result_size(User, :list, 10)
      DatabaseMetrics.record_result_size(User, :list, 20)
      DatabaseMetrics.record_result_size(User, :list, 5)
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se o tamanho máximo foi atualizado corretamente
      assert metrics[:users_list_max_result_size] != nil
      assert metrics[:users_list_max_result_size][:last_value] == 20
    end
  end
  
  describe "get_table_report/1" do
    test "retorna um relatório para uma tabela específica" do
      # Registra algumas métricas
      DatabaseMetrics.record_operation_time(:insert, User, 1_000_000_000)
      DatabaseMetrics.record_operation_result(:insert, User, {:ok, %User{}})
      DatabaseMetrics.record_result_size(User, :list, 10)
      
      # Obtém o relatório
      report = DatabaseMetrics.get_table_report(:users)
      
      # Verifica se o relatório contém as métricas esperadas
      assert report[:users_insert_time] != nil
      assert report[:users_insert_success] != nil
      assert report[:users_list_result_size] != nil
    end
  end
  
  describe "get_general_report/0" do
    test "retorna um relatório geral com todas as métricas" do
      # Registra algumas métricas
      DatabaseMetrics.record_operation_time(:insert, User, 1_000_000_000)
      DatabaseMetrics.record_operation_result(:insert, User, {:ok, %User{}})
      DatabaseMetrics.record_result_size(User, :list, 10)
      
      # Obtém o relatório geral
      report = DatabaseMetrics.get_general_report()
      
      # Verifica se o relatório contém as métricas esperadas
      assert report[:users_insert_time] != nil
      assert report[:users_insert_success] != nil
      assert report[:users_list_result_size] != nil
    end
  end
  
  describe "integração com Repository" do
    test "registra métricas para operações do repositório", %{valid_user: valid_user} do
      # Limpa todas as métricas
      Metrics.clear_all_metrics()
      
      # Executa operações do repositório
      {:ok, user} = Repository.insert(User, valid_user)
      {:ok, _} = Repository.get(User, user.id)
      {:ok, _} = Repository.update(user, %{username: "updated"})
      {:ok, _} = Repository.delete(user)
      
      # Obtém as métricas
      metrics = Metrics.get_metrics(:database)
      
      # Verifica se as métricas foram registradas para cada operação
      assert metrics[:users_insert_success] != nil
      assert metrics[:users_get_success] != nil
      assert metrics[:users_update_success] != nil
      assert metrics[:users_delete_success] != nil
    end
  end
  
  describe "clear_metrics/0" do
    test "limpa todas as métricas de banco de dados" do
      # Registra algumas métricas
      DatabaseMetrics.record_operation_time(:insert, User, 1_000_000_000)
      DatabaseMetrics.record_operation_result(:insert, User, {:ok, %User{}})
      
      # Verifica se as métricas foram registradas
      metrics_before = Metrics.get_metrics(:database)
      assert metrics_before != %{}
      
      # Limpa as métricas
      DatabaseMetrics.clear_metrics()
      
      # Verifica se as métricas foram limpas
      metrics_after = Metrics.get_metrics(:database)
      assert metrics_after == %{}
    end
  end
end
