defmodule DeeperHub.Schema.BxSpacesInvite do
  @moduledoc """
  Schema para representação de bx_spaces_invites no sistema

  Este schema armazena as informações de um bx_spaces_invite.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_spaces_invites" do
    field :key, :string, default: "0"  # varchar(128)
    field :group_profile_id, :integer, default: 0  # int(11)
    field :author_profile_id, :integer, default: 0  # int(11)
    field :invited_profile_id, :integer, default: 0  # int(11)
    field :added, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_spaces_invite no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    key: String.t() | nil,
    group_profile_id: integer() | nil,
    author_profile_id: integer() | nil,
    invited_profile_id: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_spaces_invite.

  ## Parâmetros 
    - `bx_spaces_invite`: Struct do bx_spaces_invite (pode ser %BxSpacesInvite{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_spaces_invite \ %__MODULE__{}, attrs) do
    bx_spaces_invite
    |> cast(attrs, [:key, :group_profile_id, :author_profile_id, :invited_profile_id, :added])
  end

  @doc """
  Changeset para atualização de um bx_spaces_invite existente.

  ## Parâmetros 
    - `bx_spaces_invite`: Struct do bx_spaces_invite (%BxSpacesInvite{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_spaces_invite \ %__MODULE__{}, attrs) do
    bx_spaces_invite
    |> cast(attrs, [:key, :group_profile_id, :author_profile_id, :invited_profile_id, :added])
  end
end
