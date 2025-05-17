defmodule Deeper_Hub.Core.Schemas.UserTest do
  @moduledoc """
  Testes para o esquema User.
  
  Este módulo testa todas as funcionalidades do esquema User que interagem com o banco de dados,
  utilizando ExMachina para geração de dados de teste.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Factory
  
  # Configuração para testes
  setup do
    # Aqui poderíamos adicionar configurações específicas para os testes
    # como limpar o banco de dados antes de cada teste
    :ok
  end
  
  describe "new/1" do
    test "cria um novo usuário com atributos válidos" do
      attrs = %{
        username: "testuser",
        email: "test@example.com",
        password: "senha123"
      }
      
      assert {:ok, user} = User.new(attrs)
      assert user.username == "testuser"
      assert user.email == "test@example.com"
      assert user.is_active == true
      assert is_binary(user.id)
      assert %DateTime{} = user.inserted_at
      assert %DateTime{} = user.updated_at
    end
    
    test "retorna erro quando faltam campos obrigatórios" do
      # Faltando username
      attrs1 = %{email: "test@example.com"}
      assert {:error, %{missing_fields: missing_fields1}} = User.new(attrs1)
      assert :username in missing_fields1
      
      # Faltando email
      attrs2 = %{username: "testuser"}
      assert {:error, %{missing_fields: missing_fields2}} = User.new(attrs2)
      assert :email in missing_fields2
      
      # Faltando ambos
      attrs3 = %{}
      assert {:error, %{missing_fields: missing_fields3}} = User.new(attrs3)
      assert :username in missing_fields3
      assert :email in missing_fields3
    end
    
    test "retorna erro quando username é inválido" do
      # Username muito curto
      attrs1 = %{username: "ab", email: "test@example.com"}
      assert {:error, %{username: "deve ter pelo menos 3 caracteres"}} = User.new(attrs1)
      
      # Username muito longo
      long_username = String.duplicate("a", 51)
      attrs2 = %{username: long_username, email: "test@example.com"}
      assert {:error, %{username: "deve ter no máximo 50 caracteres"}} = User.new(attrs2)
    end
    
    test "retorna erro quando email é inválido" do
      attrs = %{username: "testuser", email: "invalid_email"}
      assert {:error, %{email: "formato inválido"}} = User.new(attrs)
    end
  end
  
  describe "update/2" do
    test "atualiza um usuário com atributos válidos" do
      # Primeiro criamos um usuário
      {:ok, user} = User.new(%{
        username: "original",
        email: "original@example.com"
      })
      
      # Adicionamos um pequeno delay para garantir que o timestamp será diferente
      Process.sleep(10)
      
      # Depois atualizamos
      update_attrs = %{
        username: "updated",
        email: "updated@example.com",
        is_active: false
      }
      
      assert {:ok, updated_user} = User.update(user, update_attrs)
      assert updated_user.username == "updated"
      assert updated_user.email == "updated@example.com"
      assert updated_user.is_active == false
      assert updated_user.id == user.id
      # Verificamos apenas que os timestamps são diferentes
      assert DateTime.compare(updated_user.updated_at, user.updated_at) == :gt
    end
    
    test "atualiza a senha de um usuário" do
      # Primeiro criamos um usuário
      {:ok, user} = User.new(%{
        username: "testuser",
        email: "test@example.com",
        password: "senha_original"
      })
      
      # Depois atualizamos a senha
      update_attrs = %{password: "nova_senha"}
      
      assert {:ok, updated_user} = User.update(user, update_attrs)
      assert updated_user.password_hash != user.password_hash
      assert User.verify_password(updated_user, "nova_senha")
    end
    
    test "ignora campos desconhecidos" do
      # Primeiro criamos um usuário
      {:ok, user} = User.new(%{
        username: "testuser",
        email: "test@example.com"
      })
      
      # Adicionamos um pequeno delay para garantir que o timestamp será diferente
      Process.sleep(10)
      
      # Tentamos atualizar com campos desconhecidos
      update_attrs = %{
        unknown_field: "valor",
        another_field: 123
      }
      
      assert {:ok, updated_user} = User.update(user, update_attrs)
      assert updated_user.username == user.username
      assert updated_user.email == user.email
      assert updated_user.id == user.id
      # Verificamos apenas que os timestamps são diferentes
      assert DateTime.compare(updated_user.updated_at, user.updated_at) == :gt
    end
  end
  
  describe "from_db/1" do
    test "converte um mapa do banco de dados em struct de usuário" do
      # Simulando um resultado do banco de dados com chaves string
      db_row = %{
        "id" => "user_123",
        "username" => "dbuser",
        "email" => "db@example.com",
        "password_hash" => "hash123",
        "is_active" => 1,
        "last_login" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
      
      user = User.from_db(db_row)
      assert %User{} = user
      assert user.id == "user_123"
      assert user.username == "dbuser"
      assert user.email == "db@example.com"
      assert user.password_hash == "hash123"
      assert user.is_active == true
      assert %DateTime{} = user.last_login
      assert %DateTime{} = user.inserted_at
      assert %DateTime{} = user.updated_at
    end
    
    test "converte um mapa do banco de dados com chaves atom" do
      # Simulando um resultado do banco de dados com chaves atom
      db_row = %{
        id: "user_456",
        username: "atomuser",
        email: "atom@example.com",
        password_hash: "hash456",
        is_active: true,
        last_login: DateTime.utc_now(),
        inserted_at: DateTime.utc_now(),
        updated_at: DateTime.utc_now()
      }
      
      user = User.from_db(db_row)
      assert %User{} = user
      assert user.id == "user_456"
      assert user.username == "atomuser"
      assert user.email == "atom@example.com"
      assert user.is_active == true
    end
    
    test "lida com valores nulos" do
      db_row = %{
        "id" => "user_789",
        "username" => "nulluser",
        "email" => "null@example.com",
        "password_hash" => nil,
        "is_active" => 0,
        "last_login" => nil,
        "inserted_at" => DateTime.utc_now() |> DateTime.to_iso8601(),
        "updated_at" => DateTime.utc_now() |> DateTime.to_iso8601()
      }
      
      user = User.from_db(db_row)
      assert %User{} = user
      assert user.password_hash == nil
      assert user.is_active == false
      assert user.last_login == nil
    end
  end
  
  describe "to_db/1" do
    test "converte uma struct de usuário em um mapa para o banco de dados" do
      # Criamos um usuário
      {:ok, user} = User.new(%{
        username: "dbuser",
        email: "db@example.com",
        password: "senha123"
      })
      
      db_map = User.to_db(user)
      assert is_map(db_map)
      assert db_map.id == user.id
      assert db_map.username == "dbuser"
      assert db_map.email == "db@example.com"
      assert db_map.is_active == 1
      assert is_binary(db_map.inserted_at)
      assert is_binary(db_map.updated_at)
    end
    
    test "converte valores booleanos para inteiros" do
      # Usuário ativo
      {:ok, active_user} = User.new(%{
        username: "active",
        email: "active@example.com",
        is_active: true
      })
      
      active_db = User.to_db(active_user)
      assert active_db.is_active == 1
      
      # Usuário inativo
      {:ok, inactive_user} = User.new(%{
        username: "inactive",
        email: "inactive@example.com"
      })
      
      # Atualizamos para inativo após a criação
      {:ok, inactive_user} = User.update(inactive_user, %{is_active: false})
      
      inactive_db = User.to_db(inactive_user)
      assert inactive_db.is_active == 0
    end
  end
  
  describe "verify_password/2" do
    test "retorna true para senha correta" do
      password = "senha_secreta"
      
      # Criamos um usuário com a senha
      {:ok, user} = User.new(%{
        username: "passworduser",
        email: "password@example.com"
      })
      
      # Atualizamos para definir a senha corretamente
      # O método new não processa o campo password diretamente
      {:ok, user} = User.update(user, %{password: password})
      
      assert User.verify_password(user, password) == true
    end
    
    test "retorna false para senha incorreta" do
      # Criamos um usuário com uma senha
      {:ok, user} = User.new(%{
        username: "passworduser",
        email: "password@example.com",
        password: "senha_correta"
      })
      
      assert User.verify_password(user, "senha_errada") == false
    end
  end
  
  describe "table_name/0" do
    test "retorna o nome da tabela no banco de dados" do
      assert User.table_name() == "users"
    end
  end
  
  describe "integração com ExMachina" do
    test "cria um usuário usando factory" do
      user = Factory.build(:user)
      
      # Convertemos para o formato esperado pelo User.new
      attrs = %{
        username: user.username,
        email: user.email
      }
      
      assert {:ok, created_user} = User.new(attrs)
      assert created_user.username == user.username
      assert created_user.email == user.email
    end
    
    test "insere um usuário no banco usando insert_user" do
      # Este teste simula a inserção no banco usando a função do factory
      result = Factory.insert_user(username: "factoryuser", email: "factory@example.com")
      
      assert {:ok, user} = result
      assert user.username == "factoryuser"
      assert user.email == "factory@example.com"
    end
    
    test "cria múltiplos usuários com atributos diferentes" do
      users = Factory.build_list(3, :user, role: "member")
      
      assert length(users) == 3
      Enum.each(users, fn user ->
        assert user.role == "member"
        assert String.contains?(user.email, "@example.com")
      end)
    end
  end
end
