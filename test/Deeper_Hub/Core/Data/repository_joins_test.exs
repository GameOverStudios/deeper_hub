defmodule Deeper_Hub.Core.Data.RepositoryJoinsTest do
  use ExUnit.Case
  alias Deeper_Hub.Core.Data.Repository
  alias Deeper_Hub.Core.Schemas.User
  alias Deeper_Hub.Core.Data.Repo

  # Vamos assumir que temos um schema Profile para testar os joins
  # Definindo um módulo de teste para Profile
  defmodule Profile do
    use Ecto.Schema
    import Ecto.Changeset

    @primary_key {:id, :binary_id, autogenerate: true}
    @foreign_key_type :binary_id
    schema "profiles" do
      field :bio, :string
      field :avatar_url, :string
      belongs_to :user, User

      timestamps()
    end

    def changeset(profile, attrs) do
      profile
      |> cast(attrs, [:bio, :avatar_url, :user_id])
      |> validate_required([:user_id])
    end
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
    
    # Criar um perfil associado ao usuário
    profile_attrs = %{
      bio: "Test bio",
      avatar_url: "http://example.com/avatar.jpg",
      user_id: user.id
    }
    
    {:ok, profile} = Repository.insert(Profile, profile_attrs)
    
    # Criar um usuário sem perfil
    user_no_profile_attrs = %{
      username: "no_profile_user",
      email: "no_profile@example.com",
      password: "password123",
      is_active: true
    }
    
    {:ok, user_no_profile} = Repository.insert(User, user_no_profile_attrs)
    
    # Criar um perfil sem usuário (para testar right join)
    profile_no_user_attrs = %{
      bio: "Orphan profile",
      avatar_url: "http://example.com/orphan.jpg",
      user_id: nil
    }
    
    {:ok, profile_no_user} = Repository.insert(Profile, profile_no_user_attrs)
    
    %{
      user: user,
      profile: profile,
      user_no_profile: user_no_profile,
      profile_no_user: profile_no_user
    }
  end

  describe "join operations" do
    test "join_inner/5 returns records from both tables with matching conditions", %{user: user, profile: profile} do
      assert {:ok, results} = Repository.join_inner(
        User,
        Profile,
        [:id, :username, :email],
        %{is_active: true},
        join_on: {:id, :user_id}
      )
      
      assert length(results) > 0
      
      # Verificar se o resultado contém os dados corretos
      result = hd(results)
      assert result.id == user.id
      assert result.username == user.username
      assert result.email == user.email
      assert result.profile_id == profile.id
      assert result.profile_bio == profile.bio
    end
    
    test "join_left/5 includes all records from left table", %{user: user, user_no_profile: user_no_profile} do
      assert {:ok, results} = Repository.join_left(
        User,
        Profile,
        [:id, :username],
        %{},
        join_on: {:id, :user_id}
      )
      
      # Deve incluir todos os usuários, mesmo os sem perfil
      assert length(results) >= 2
      
      # Verificar se o usuário sem perfil está incluído
      user_no_profile_result = Enum.find(results, fn r -> r.id == user_no_profile.id end)
      assert user_no_profile_result != nil
      assert user_no_profile_result.profile_id == nil
    end
    
    test "join_right/5 includes all records from right table", %{profile_no_user: profile_no_user} do
      assert {:ok, results} = Repository.join_right(
        User,
        Profile,
        [:id, :username],
        %{},
        join_on: {:id, :user_id}
      )
      
      # Deve incluir todos os perfis, mesmo os sem usuário
      profile_no_user_result = Enum.find(results, fn r -> r.profile_id == profile_no_user.id end)
      assert profile_no_user_result != nil
      assert profile_no_user_result.id == nil
    end
  end
end
