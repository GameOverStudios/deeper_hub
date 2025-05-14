defmodule Deeper_Hub.Core.Data.RepositoryJoinsTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Data.Repo

  # Em vez de usar uma tabela profiles que não existe, vamos usar a tabela users existente
  # com um schema diferente para simular joins
  defmodule UserExtended do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "users" do
      field :username, :string
      field :email, :string
      field :password_hash, :string
      field :is_active, :boolean, default: true
      field :last_login, :utc_datetime
      
      # Campo virtual para senha (não armazenado no banco)
      field :password, :string, virtual: true
      
      # Campos adicionais para simular um perfil (apenas para testes)
      # Estes campos não existem na tabela, mas são usados apenas para joins
      field :bio, :string, virtual: true
      field :avatar_url, :string, virtual: true
      field :user_id, :binary_id, virtual: true

      timestamps()
    end

    def changeset(user_extended, attrs) do
      user_extended
      |> cast(attrs, [:username, :email, :password, :is_active, :last_login])
      |> validate_required([:username, :email])
      |> maybe_hash_password()
    end
    
    # Função privada para hash de senha (copiada do User schema)
    defp maybe_hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
      password_hash = :crypto.hash(:sha256, password) |> Base.encode64()
      
      changeset
      |> put_change(:password_hash, password_hash)
    end
    
    defp maybe_hash_password(changeset), do: changeset
  end

  # Configuração para testes
  setup do
    # Configurar o sandbox para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Limpar o cache antes de cada teste
    :ets.delete_all_objects(:repository_cache)
    
    # Criar um usuário para testes
    user_attrs = %{
      username: "join_test_user",
      email: "join_test@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user} = Repository.insert(User, user_attrs)
    
    # Criar um usuário estendido associado ao primeiro usuário
    user_extended_attrs = %{
      username: "extended_user",
      email: "extended@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user_extended} = Repository.insert(UserExtended, user_extended_attrs)
    
    # Criar um usuário sem relacionamento
    user_no_relation_attrs = %{
      username: "no_relation_user",
      email: "no_relation@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user_no_relation} = Repository.insert(User, user_no_relation_attrs)
    
    # Criar um usuário estendido sem relacionamento (para testar right join)
    extended_no_relation_attrs = %{
      username: "orphan_extended",
      email: "orphan@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, extended_no_relation} = Repository.insert(UserExtended, extended_no_relation_attrs)
    
    %{
      user: user,
      user_extended: user_extended,
      user_no_relation: user_no_relation,
      extended_no_relation: extended_no_relation
    }
  end

  describe "join operations" do
    test "join_inner/5 returns records from both tables with matching conditions", %{user: user, user_extended: user_extended} do
      assert {:ok, results} = Repository.join_inner(
        User,
        UserExtended,
        [:id, :username, :email],
        %{is_active: true},
        join_on: {:is_active, :is_active}
      )
      
      assert length(results) > 0
      
      # Verificar se o resultado contém os dados corretos
      result = Enum.find(results, fn r -> r.id == user.id end)
      assert result != nil
      assert result.username == user.username
      assert result.email == user.email
      assert result.userextended_id == user_extended.id
    end
    
    test "join_left/5 includes all records from left table", %{user: user, user_no_relation: user_no_relation} do
      assert {:ok, results} = Repository.join_left(
        User,
        UserExtended,
        [:id, :username],
        %{},
        join_on: {:is_active, :is_active}
      )
      
      # Deve incluir todos os usuários, mesmo os sem relacionamento
      assert length(results) >= 2
      
      # Verificar se o usuário sem relacionamento está incluído
      user_no_relation_result = Enum.find(results, fn r -> r.id == user_no_relation.id end)
      assert user_no_relation_result != nil
      assert user_no_relation_result.userextended_id == nil
    end
    
    test "join_right/5 includes all records from right table", %{extended_no_relation: extended_no_relation} do
      assert {:ok, results} = Repository.join_right(
        User,
        UserExtended,
        [:id, :username],
        %{},
        join_on: {:is_active, :is_active}
      )
      
      # Deve incluir todos os usuários estendidos, mesmo os sem relacionamento
      extended_no_relation_result = Enum.find(results, fn r -> r.userextended_id == extended_no_relation.id end)
      assert extended_no_relation_result != nil
      assert extended_no_relation_result.id == nil
    end
  end
end
