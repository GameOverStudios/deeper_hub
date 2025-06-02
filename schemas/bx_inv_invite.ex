defmodule DeeperHub.Schema.BxInvInvite do
  @moduledoc """
  Schema para representação de bx_inv_invites no sistema

  Este schema armazena as informações de um bx_inv_invite.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_inv_invites" do
    field :account_id, :integer  # int(11)
    field :profile_id, :integer  # int(11)
    field :key, :string  # varchar(128)
    field :redirect, :string, default: ""  # varchar(255)
    field :email, :string  # varchar(128)
    field :date, :integer, default: 0  # int(11)
    field :date_seen, :integer  # int(11)
    field :date_joined, :integer  # int(11)
    field :joined_account_id, :integer  # int(11)
    field :request_id, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_inv_invite no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    account_id: integer() | nil,
    profile_id: integer() | nil,
    key: String.t() | nil,
    redirect: String.t() | nil,
    email: String.t() | nil,
    date: integer() | nil,
    date_seen: integer() | nil,
    date_joined: integer() | nil,
    joined_account_id: integer() | nil,
    request_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_inv_invite.

  ## Parâmetros 
    - `bx_inv_invite`: Struct do bx_inv_invite (pode ser %BxInvInvite{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_inv_invite \ %__MODULE__{}, attrs) do
    bx_inv_invite
    |> cast(attrs, [:account_id, :profile_id, :key, :redirect, :email, :date, :date_seen, :date_joined, :joined_account_id, :request_id])
    |> validate_required([:account_id, :profile_id, :key, :redirect, :email])
    |> validate_email()
  end

  @doc """
  Changeset para atualização de um bx_inv_invite existente.

  ## Parâmetros 
    - `bx_inv_invite`: Struct do bx_inv_invite (%BxInvInvite{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_inv_invite \ %__MODULE__{}, attrs) do
    bx_inv_invite
    |> cast(attrs, [:account_id, :profile_id, :key, :redirect, :email, :date, :date_seen, :date_joined, :joined_account_id, :request_id])
    |> validate_email()
  end
end
