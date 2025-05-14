defmodule Deeper_Hub.Core.Data.RepositoryTest do
  @moduledoc """
  Testes para o módulo Repository.
  
  Este módulo testa todas as operações CRUD básicas do repositório,
  garantindo que o banco de dados funcione corretamente.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Schemas.User
  
  # Configuração para cada teste
  setup do
    # Inicia uma transação para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    
    # Permite o uso de transações aninhadas
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Dados de teste
    valid_user = %{
      username: "testuser",
      email: "test@example.com",
      password: "password123"
    }
    
    # Retorna os dados para uso nos testes
    {:ok, %{valid_user: valid_user}}
  end
  
  describe "insert/2" do
    test "insere um registro válido", %{valid_user: valid_user} do
      assert {:ok, user} = Repository.insert(User, valid_user)
      assert user.username == valid_user.username
      assert user.email == valid_user.email
      assert user.password_hash != nil
    end
    
    test "retorna erro para dados inválidos" do
      invalid_user = %{username: "", email: "invalid"}
      assert {:error, changeset} = Repository.insert(User, invalid_user)
      assert changeset.valid? == false
    end
  end
  
  describe "get/2" do
    test "busca um registro existente", %{valid_user: valid_user} do
      # Insere um usuário para testar a busca
      {:ok, inserted_user} = Repository.insert(User, valid_user)
      
      # Busca o usuário inserido
      assert {:ok, found_user} = Repository.get(User, inserted_user.id)
      assert found_user.id == inserted_user.id
      assert found_user.username == valid_user.username
    end
    
    test "retorna erro para registro inexistente" do
      assert {:error, :not_found} = Repository.get(User, "00000000-0000-0000-0000-000000000000")
    end
  end
  
  describe "update/2" do
    test "atualiza um registro existente", %{valid_user: valid_user} do
      # Insere um usuário para testar a atualização
      {:ok, user} = Repository.insert(User, valid_user)
      
      # Atualiza o usuário
      update_attrs = %{username: "updated_user"}
      assert {:ok, updated_user} = Repository.update(user, update_attrs)
      assert updated_user.username == "updated_user"
      assert updated_user.email == user.email
    end
    
    test "retorna erro para atualização inválida", %{valid_user: valid_user} do
      # Insere um usuário para testar a atualização
      {:ok, user} = Repository.insert(User, valid_user)
      
      # Tenta atualizar com dados inválidos
      invalid_attrs = %{username: "", email: "invalid"}
      assert {:error, changeset} = Repository.update(user, invalid_attrs)
      assert changeset.valid? == false
    end
  end
  
  describe "delete/1" do
    test "remove um registro existente", %{valid_user: valid_user} do
      # Insere um usuário para testar a remoção
      {:ok, user} = Repository.insert(User, valid_user)
      
      # Remove o usuário
      assert {:ok, :deleted} = Repository.delete(user)
      
      # Verifica se o usuário foi removido
      assert {:error, :not_found} = Repository.get(User, user.id)
    end
  end
  
  describe "list/2" do
    test "lista todos os registros" do
      # Limpa a tabela para garantir um estado conhecido
      Repo.delete_all(User)
      
      # Insere alguns usuários para testar a listagem
      {:ok, _} = Repository.insert(User, %{username: "user1", email: "user1@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user2", email: "user2@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user3", email: "user3@example.com", password: "password"})
      
      # Lista todos os usuários
      assert {:ok, users} = Repository.list(User)
      assert length(users) == 3
    end
    
    test "lista registros com limite" do
      # Limpa a tabela para garantir um estado conhecido
      Repo.delete_all(User)
      
      # Insere alguns usuários para testar a listagem
      {:ok, _} = Repository.insert(User, %{username: "user1", email: "user1@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user2", email: "user2@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user3", email: "user3@example.com", password: "password"})
      
      # Lista usuários com limite
      assert {:ok, users} = Repository.list(User, limit: 2)
      assert length(users) == 2
    end
    
    test "lista registros com offset" do
      # Limpa a tabela para garantir um estado conhecido
      Repo.delete_all(User)
      
      # Insere alguns usuários para testar a listagem
      {:ok, _} = Repository.insert(User, %{username: "user1", email: "user1@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user2", email: "user2@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user3", email: "user3@example.com", password: "password"})
      
      # Lista usuários com offset
      assert {:ok, users} = Repository.list(User, offset: 1)
      assert length(users) == 2
    end
  end
  
  describe "find/3" do
    test "busca registros por condições" do
      # Limpa a tabela para garantir um estado conhecido
      Repo.delete_all(User)
      
      # Insere alguns usuários para testar a busca
      {:ok, _} = Repository.insert(User, %{username: "user1", email: "user1@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user2", email: "user2@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "admin", email: "admin@example.com", password: "password"})
      
      # Busca usuários por username
      assert {:ok, users} = Repository.find(User, %{username: "admin"})
      assert length(users) == 1
      assert hd(users).username == "admin"
    end
    
    test "retorna lista vazia quando não encontra registros" do
      # Busca usuários com condição que não existe
      assert {:ok, users} = Repository.find(User, %{username: "nonexistent"})
      assert users == []
    end
    
    test "busca registros com limite e offset" do
      # Limpa a tabela para garantir um estado conhecido
      Repo.delete_all(User)
      
      # Insere alguns usuários para testar a busca
      {:ok, _} = Repository.insert(User, %{username: "user1", email: "user1@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user2", email: "user2@example.com", password: "password"})
      {:ok, _} = Repository.insert(User, %{username: "user3", email: "user3@example.com", password: "password"})
      
      # Busca usuários com limite
      assert {:ok, users} = Repository.find(User, %{}, limit: 2)
      assert length(users) == 2
      
      # Busca usuários com offset
      assert {:ok, users} = Repository.find(User, %{}, offset: 1)
      assert length(users) == 2
    end
  end
end
