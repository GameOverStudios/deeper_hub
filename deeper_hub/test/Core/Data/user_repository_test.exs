defmodule Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepositoryTest do
  @moduledoc """
  Testes de integração para o UserRepository.
  
  Este módulo testa as operações de banco de dados relacionadas a usuários,
  utilizando ExMachina para geração de dados de teste.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.DBConnection.Schemas.User
  alias Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepository
  alias Deeper_Hub.Factory
  
  # Configuração para testes
  setup_all do
    # Executa a migração para criar a tabela de usuários
    migration_module = Deeper_Hub.Core.Data.DBConnection.Migrations.Migration20250517000001_create_users_table
    migration_module.up()
    :ok
  end
  
  setup do
    # Limpa a tabela de usuários antes de cada teste
    cleanup_users()
    :ok
  end
  
  describe "insert/1" do
    test "insere um novo usuário no banco de dados" do
      # Cria um usuário usando o factory
      user_attrs = %{
        username: "testuser",
        email: "test@example.com",
        password: "senha123"
      }
      
      # Cria a struct de usuário
      {:ok, user} = User.new(user_attrs)
      
      # Insere no banco
      assert {:ok, inserted_user} = UserRepository.insert(user)
      assert inserted_user.id == user.id
      assert inserted_user.username == "testuser"
      assert inserted_user.email == "test@example.com"
      
      # Verifica se o usuário foi realmente inserido
      assert {:ok, true} = UserRepository.exists?(user.id)
    end
    
    test "retorna erro ao tentar inserir usuário com username duplicado" do
      # Cria e insere um primeiro usuário
      {:ok, user1} = User.new(%{
        username: "sameuser",
        email: "user1@example.com",
        password: "senha123"
      })
      
      {:ok, _} = UserRepository.insert(user1)
      
      # Tenta inserir outro usuário com o mesmo username
      {:ok, user2} = User.new(%{
        username: "sameuser",
        email: "user2@example.com",
        password: "senha123"
      })
      
      # Deve falhar devido à restrição de unicidade
      assert {:error, _} = UserRepository.insert(user2)
    end
    
    test "retorna erro ao tentar inserir usuário com email duplicado" do
      # Cria e insere um primeiro usuário
      {:ok, user1} = User.new(%{
        username: "user1",
        email: "same@example.com",
        password: "senha123"
      })
      
      {:ok, _} = UserRepository.insert(user1)
      
      # Tenta inserir outro usuário com o mesmo email
      {:ok, user2} = User.new(%{
        username: "user2",
        email: "same@example.com",
        password: "senha123"
      })
      
      # Deve falhar devido à restrição de unicidade
      assert {:error, _} = UserRepository.insert(user2)
    end
  end
  
  describe "update/1" do
    test "atualiza um usuário existente" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "original",
        email: "original@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      
      # Atualiza o usuário
      {:ok, updated_user} = User.update(inserted_user, %{
        username: "updated",
        email: "updated@example.com"
      })
      
      # Salva a atualização no banco
      assert {:ok, saved_user} = UserRepository.update(updated_user)
      assert saved_user.username == "updated"
      assert saved_user.email == "updated@example.com"
      
      # Verifica se a atualização foi persistida
      {:ok, fetched_user} = UserRepository.get_by_id(user.id)
      assert fetched_user.username == "updated"
      assert fetched_user.email == "updated@example.com"
    end
    
    test "retorna erro ao tentar atualizar usuário inexistente" do
      # Cria um usuário que não está no banco
      {:ok, user} = User.new(%{
        username: "nonexistent",
        email: "nonexistent@example.com",
        password: "senha123"
      })
      
      # Tenta atualizar
      assert {:error, :not_found} = UserRepository.update(user)
    end
  end
  
  describe "get_by_id/1" do
    test "retorna um usuário existente pelo ID" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "iduser",
        email: "id@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      
      # Busca pelo ID
      assert {:ok, fetched_user} = UserRepository.get_by_id(inserted_user.id)
      assert fetched_user.id == inserted_user.id
      assert fetched_user.username == "iduser"
      assert fetched_user.email == "id@example.com"
    end
    
    test "retorna erro ao buscar usuário inexistente pelo ID" do
      assert {:error, :not_found} = UserRepository.get_by_id("nonexistent_id")
    end
  end
  
  describe "get_by_username/1" do
    test "retorna um usuário existente pelo username" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "usernameuser",
        email: "username@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      
      # Busca pelo username
      assert {:ok, fetched_user} = UserRepository.get_by_username("usernameuser")
      assert fetched_user.id == inserted_user.id
      assert fetched_user.username == "usernameuser"
      assert fetched_user.email == "username@example.com"
    end
    
    test "retorna erro ao buscar usuário inexistente pelo username" do
      assert {:error, :not_found} = UserRepository.get_by_username("nonexistent_username")
    end
  end
  
  describe "get_by_email/1" do
    test "retorna um usuário existente pelo email" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "emailuser",
        email: "specific@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      
      # Busca pelo email
      assert {:ok, fetched_user} = UserRepository.get_by_email("specific@example.com")
      assert fetched_user.id == inserted_user.id
      assert fetched_user.username == "emailuser"
      assert fetched_user.email == "specific@example.com"
    end
    
    test "retorna erro ao buscar usuário inexistente pelo email" do
      assert {:error, :not_found} = UserRepository.get_by_email("nonexistent@example.com")
    end
  end
  
  describe "list_users/1" do
    test "lista todos os usuários" do
      # Insere vários usuários
      users = insert_multiple_users(3)
      
      # Lista todos
      assert {:ok, listed_users} = UserRepository.list_users()
      assert length(listed_users) == 3
      
      # Verifica se todos os usuários inseridos estão na lista
      user_ids = Enum.map(listed_users, & &1.id)
      for user <- users do
        assert user.id in user_ids
      end
    end
    
    test "lista apenas usuários ativos" do
      # Insere usuários ativos e inativos
      _active_users = insert_multiple_users(2)
      
      # Insere um usuário inativo
      {:ok, inactive_user} = User.new(%{
        username: "inactive",
        email: "inactive@example.com",
        password: "senha123"
      })
      
      {:ok, inactive_user} = User.update(inactive_user, %{is_active: false})
      {:ok, _} = UserRepository.insert(inactive_user)
      
      # Lista apenas ativos
      assert {:ok, listed_users} = UserRepository.list_users(active_only: true)
      assert length(listed_users) == 2
      
      # Verifica que todos os listados são ativos
      for user <- listed_users do
        assert user.is_active == true
      end
      
      # Verifica que o inativo não está na lista
      inactive_ids = Enum.map(listed_users, & &1.id)
      assert inactive_user.id not in inactive_ids
    end
  end
  
  describe "deactivate/1" do
    test "desativa um usuário existente" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "activeuser",
        email: "active@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      assert inserted_user.is_active == true
      
      # Desativa o usuário
      assert {:ok, deactivated_user} = UserRepository.deactivate(inserted_user.id)
      assert deactivated_user.is_active == false
      
      # Verifica se a desativação foi persistida
      {:ok, fetched_user} = UserRepository.get_by_id(inserted_user.id)
      assert fetched_user.is_active == false
    end
    
    test "retorna erro ao tentar desativar usuário inexistente" do
      assert {:error, :not_found} = UserRepository.deactivate("nonexistent_id")
    end
  end
  
  describe "reactivate/1" do
    test "reativa um usuário desativado" do
      # Cria e insere um usuário desativado
      {:ok, user} = User.new(%{
        username: "inactiveuser",
        email: "inactive@example.com",
        password: "senha123"
      })
      
      {:ok, user} = User.update(user, %{is_active: false})
      {:ok, inserted_user} = UserRepository.insert(user)
      assert inserted_user.is_active == false
      
      # Reativa o usuário
      assert {:ok, reactivated_user} = UserRepository.reactivate(inserted_user.id)
      assert reactivated_user.is_active == true
      
      # Verifica se a reativação foi persistida
      {:ok, fetched_user} = UserRepository.get_by_id(inserted_user.id)
      assert fetched_user.is_active == true
    end
    
    test "retorna erro ao tentar reativar usuário inexistente" do
      assert {:error, :not_found} = UserRepository.reactivate("nonexistent_id")
    end
  end
  
  describe "delete/1" do
    test "exclui um usuário existente" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "deleteuser",
        email: "delete@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      
      # Verifica que o usuário existe
      assert {:ok, true} = UserRepository.exists?(inserted_user.id)
      
      # Exclui o usuário
      assert {:ok, deleted_id} = UserRepository.delete(inserted_user.id)
      assert deleted_id == inserted_user.id
      
      # Verifica que o usuário não existe mais
      assert {:ok, false} = UserRepository.exists?(inserted_user.id)
    end
    
    test "retorna erro ao tentar excluir usuário inexistente" do
      assert {:error, :not_found} = UserRepository.delete("nonexistent_id")
    end
  end
  
  describe "exists?/1" do
    test "retorna true para usuário existente" do
      # Cria e insere um usuário
      {:ok, user} = User.new(%{
        username: "existsuser",
        email: "exists@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      
      # Verifica existência
      assert {:ok, true} = UserRepository.exists?(inserted_user.id)
    end
    
    test "retorna false para usuário inexistente" do
      assert {:ok, false} = UserRepository.exists?("nonexistent_id")
    end
  end
  
  describe "integração com ExMachina" do
    test "insere usuário criado com factory" do
      # Cria um usuário usando o factory
      factory_user = Factory.build(:user)
      
      # Converte para o formato do esquema User
      {:ok, user} = User.new(%{
        username: factory_user.username,
        email: factory_user.email,
        password: "senha123"
      })
      
      # Insere no banco
      assert {:ok, inserted_user} = UserRepository.insert(user)
      assert inserted_user.username == factory_user.username
      assert inserted_user.email == factory_user.email
      
      # Verifica se foi inserido corretamente
      assert {:ok, fetched_user} = UserRepository.get_by_id(inserted_user.id)
      assert fetched_user.username == factory_user.username
    end
    
    test "insere múltiplos usuários com factory" do
      # Cria múltiplos usuários com o factory
      factory_users = Factory.build_list(3, :user)
      
      # Insere cada um no banco
      inserted_users = Enum.map(factory_users, fn factory_user ->
        {:ok, user} = User.new(%{
          username: factory_user.username,
          email: factory_user.email,
          password: "senha123"
        })
        
        {:ok, inserted} = UserRepository.insert(user)
        inserted
      end)
      
      # Verifica se todos foram inseridos
      assert length(inserted_users) == 3
      
      # Lista todos os usuários do banco
      {:ok, all_users} = UserRepository.list_users()
      assert length(all_users) >= 3
    end
  end
  
  # Funções auxiliares para os testes
  
  defp cleanup_users do
    # Limpa a tabela de usuários
    query = "DELETE FROM #{User.table_name()}"
    
    # Executa a query
    Deeper_Hub.Core.Data.DBConnection.Facade.query(query, [])
    :ok
  end
  
  defp insert_multiple_users(count) do
    Enum.map(1..count, fn i ->
      {:ok, user} = User.new(%{
        username: "user#{i}",
        email: "user#{i}@example.com",
        password: "senha123"
      })
      
      {:ok, inserted_user} = UserRepository.insert(user)
      inserted_user
    end)
  end
end
