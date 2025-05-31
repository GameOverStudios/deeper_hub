defmodule DeeperHub.DataAccess.Schemas.User do
  @moduledoc """
  Schema Ecto para representação de usuários no sistema DeeperHub.
  
  Este schema define a estrutura de dados para usuários, incluindo
  informações básicas, autenticação e timestamps.
  """
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "users" do
    field :name, :string
    field :email, :string
    field :username, :string
    field :password_hash, :string
    field :password, :string, virtual: true
    field :active, :boolean, default: true
    field :last_login, :utc_datetime

    timestamps()
  end

  @doc """
  Cria um changeset para validação e inserção/atualização de usuários.
  
  ## Parâmetros
    - user: struct atual do usuário (ou struct vazia para nova inserção)
    - attrs: atributos a serem aplicados/validados
    
  ## Retorno
    - Um changeset com validações aplicadas
  """
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:name, :email, :username, :password, :active, :last_login])
    |> validate_required([:name, :email, :username])
    |> validate_length(:name, min: 3, max: 100)
    |> validate_length(:username, min: 3, max: 30)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
    |> maybe_hash_password()
  end

  @doc """
  Changeset específico para autenticação.
  
  Valida apenas email/username e senha.
  """
  def login_changeset(user, attrs) do
    user
    |> cast(attrs, [:email, :username, :password])
    |> validate_required([:password])
    |> validate_required_inclusion([:email, :username])
  end

  # Aplica hash na senha se presente
  defp maybe_hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) 
       when not is_nil(password) do
    # Aqui seria implementado o hash real da senha, como com Argon2 ou Bcrypt
    # Para simplificar, usamos uma implementação básica
    hashed_password = :crypto.hash(:sha256, password) |> Base.encode16()
    put_change(changeset, :password_hash, hashed_password)
  end
  defp maybe_hash_password(changeset), do: changeset
  
  # Valida que pelo menos um dos campos da lista está presente
  defp validate_required_inclusion(changeset, fields) do
    if Enum.any?(fields, &get_field(changeset, &1)) do
      changeset
    else
      fields_string = Enum.map_join(fields, ", ", &to_string/1)
      add_error(changeset, hd(fields), "pelo menos um destes campos deve estar presente: #{fields_string}")
    end
  end
end
