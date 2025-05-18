defmodule Deeper_Hub.Core.WebSockets.Security.SqlInjectionProtectionTest do
  use ExUnit.Case
  
  alias Deeper_Hub.Core.WebSockets.Security.SqlInjectionProtection
  
  describe "check_for_sql_injection/1" do
    test "detecta strings com potencial SQL Injection" do
      # Teste com SELECT
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("SELECT * FROM users")
      
      # Teste com DROP
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("DROP TABLE users")
      
      # Teste com comentário SQL
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("username' --")
      
      # Teste com UNION
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("1' UNION SELECT username, password FROM users")
      
      # Teste com ponto e vírgula
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("1'; DROP TABLE users; --")
      
      # Teste com INFORMATION_SCHEMA
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("SELECT * FROM INFORMATION_SCHEMA.tables")
      
      # Teste com SLEEP
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection("1' AND SLEEP(5) --")
    end
    
    test "permite strings sem SQL Injection" do
      # Teste com texto normal
      assert {:ok, _} = SqlInjectionProtection.check_for_sql_injection("Hello, world!")
      
      # Teste com texto contendo palavras parciais que não devem ser detectadas
      assert {:ok, _} = SqlInjectionProtection.check_for_sql_injection("My selection of items")
      
      # Teste com números
      assert {:ok, _} = SqlInjectionProtection.check_for_sql_injection("12345")
      
      # Teste com JSON
      assert {:ok, _} = SqlInjectionProtection.check_for_sql_injection("{\"name\":\"John\", \"age\":30}")
    end
    
    test "detecta SQL Injection em mapas" do
      # Teste com mapa contendo SQL Injection
      input = %{
        "name" => "John",
        "query" => "SELECT * FROM users WHERE id = 1"
      }
      
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection(input)
    end
    
    test "detecta SQL Injection em listas" do
      # Teste com lista contendo SQL Injection
      input = [
        "John",
        "DROP TABLE users"
      ]
      
      assert {:error, _} = SqlInjectionProtection.check_for_sql_injection(input)
    end
    
    test "permite mapas sem SQL Injection" do
      # Teste com mapa sem SQL Injection
      input = %{
        "name" => "John",
        "age" => 30
      }
      
      assert {:ok, _} = SqlInjectionProtection.check_for_sql_injection(input)
    end
    
    test "permite listas sem SQL Injection" do
      # Teste com lista sem SQL Injection
      input = [
        "John",
        "30"
      ]
      
      assert {:ok, _} = SqlInjectionProtection.check_for_sql_injection(input)
    end
  end
  
  describe "sanitize_sql_value/1" do
    test "sanitiza strings com potencial SQL Injection" do
      # Teste com aspas simples
      input = "O'Reilly"
      {:ok, sanitized} = SqlInjectionProtection.sanitize_sql_value(input)
      
      assert sanitized == "O''Reilly"
      
      # Teste com ponto e vírgula
      input = "value; DROP TABLE users"
      {:ok, sanitized} = SqlInjectionProtection.sanitize_sql_value(input)
      
      refute String.contains?(sanitized, ";")
      
      # Teste com comentário SQL
      input = "value -- comment"
      {:ok, sanitized} = SqlInjectionProtection.sanitize_sql_value(input)
      
      refute String.contains?(sanitized, "--")
    end
    
    test "sanitiza mapas com valores contendo SQL Injection" do
      # Teste com mapa contendo valores com potencial SQL Injection
      input = %{
        "name" => "O'Reilly",
        "query" => "SELECT * FROM users; DROP TABLE users"
      }
      
      {:ok, sanitized} = SqlInjectionProtection.sanitize_sql_value(input)
      
      assert sanitized["name"] == "O''Reilly"
      refute String.contains?(sanitized["query"], ";")
    end
    
    test "sanitiza listas com valores contendo SQL Injection" do
      # Teste com lista contendo valores com potencial SQL Injection
      input = [
        "O'Reilly",
        "SELECT * FROM users; DROP TABLE users"
      ]
      
      {:ok, sanitized} = SqlInjectionProtection.sanitize_sql_value(input)
      
      assert Enum.at(sanitized, 0) == "O''Reilly"
      refute Enum.at(sanitized, 1) |> String.contains?(";")
    end
  end
  
  describe "prepare_query_params/2" do
    test "prepara consultas parametrizadas válidas" do
      # Teste com consulta e parâmetros válidos
      query = "SELECT * FROM users WHERE name = ? AND age > ?"
      params = ["John", 30]
      
      assert {:ok, {^query, ^params}} = SqlInjectionProtection.prepare_query_params(query, params)
    end
    
    test "rejeita consultas com número incorreto de parâmetros" do
      # Teste com menos parâmetros que placeholders
      query = "SELECT * FROM users WHERE name = ? AND age > ?"
      params = ["John"]
      
      assert {:error, _} = SqlInjectionProtection.prepare_query_params(query, params)
      
      # Teste com mais parâmetros que placeholders
      query = "SELECT * FROM users WHERE name = ?"
      params = ["John", 30]
      
      assert {:error, _} = SqlInjectionProtection.prepare_query_params(query, params)
    end
    
    test "rejeita parâmetros com SQL Injection" do
      # Teste com parâmetro contendo SQL Injection
      query = "SELECT * FROM users WHERE name = ?"
      params = ["John'; DROP TABLE users; --"]
      
      assert {:error, _} = SqlInjectionProtection.prepare_query_params(query, params)
    end
  end
end
