defmodule Deeper_Hub.Core.Schemas.User do
  @moduledoc """
  Schema para usuários do sistema.
  
  Este schema define a estrutura de dados para usuários no banco de dados,
  incluindo validações e relacionamentos.
  """
  
  # Adiciona suporte à serialização JSON, excluindo campos sensíveis
  @derive {Jason.Encoder, except: [:password, :password_hash]}
  
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
    
    timestamps()
  end
  
  @doc """
  Changeset para criação de usuário.
  
  ## Parâmetros
  
    - `user`: A struct de usuário
    - `attrs`: Os atributos para criar/atualizar o usuário
    
  ## Retorno
  
    - Um changeset válido ou inválido
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(user, attrs) do
    user
    |> cast(attrs, [:username, :email, :password, :is_active, :last_login])
    |> validate_required([:username, :email])
    |> validate_length(:username, min: 3, max: 50)
    |> validate_format(:email, ~r/@/)
    |> unique_constraint(:username)
    |> unique_constraint(:email)
    |> maybe_hash_password()
  end
  
  @doc """
  Changeset para atualização de senha.
  
  ## Parâmetros
  
    - `user`: A struct de usuário
    - `attrs`: Os atributos para atualizar a senha
    
  ## Retorno
  
    - Um changeset válido ou inválido
  """
  @spec password_changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def password_changeset(user, attrs) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_length(:password, min: 6)
    |> maybe_hash_password()
  end
  
  # Função privada para hash de senha
  defp maybe_hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = changeset) do
    # Em um ambiente real, usaríamos uma biblioteca como Bcrypt
    # Para simplificar, usamos :crypto.hash
    password_hash = :crypto.hash(:sha256, password) |> Base.encode64()
    
    changeset
    |> put_change(:password_hash, password_hash)
    |> delete_change(:password)
  end
  
  defp maybe_hash_password(changeset), do: changeset
end
