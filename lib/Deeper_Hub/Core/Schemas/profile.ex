defmodule Deeper_Hub.Core.Schemas.Profile do
  @moduledoc """
  Schema para perfis de usuários.
  
  Este módulo define a estrutura de dados para perfis de usuários,
  incluindo informações adicionais como foto de perfil, biografia e site.
  """
  
  # Adiciona suporte à serialização JSON
  @derive {Jason.Encoder, only: [:id, :user_id, :profile_picture, :bio, :website, :inserted_at, :updated_at]}
  
  use Ecto.Schema
  import Ecto.Changeset
  
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  
  schema "profiles" do
    field :user_id, :binary_id
    field :profile_picture, :string
    field :bio, :string
    field :website, :string
    
    timestamps()
  end
  
  @doc """
  Changeset para criação de perfil.
  
  ## Parâmetros
  
    - `profile`: A struct de perfil
    - `attrs`: Os atributos para criar/atualizar o perfil
  
  ## Retorno
  
    - Um changeset válido ou inválido
  """
  @spec changeset(Ecto.Schema.t(), map()) :: Ecto.Changeset.t()
  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [:user_id, :profile_picture, :bio, :website])
    |> validate_required([:user_id])
    |> validate_format(:website, ~r/https?:\/\/[\w.-]+(?:\/[\w.-]*)*\/?/, allow_nil: true)
    |> validate_length(:bio, max: 500)
  end
end
