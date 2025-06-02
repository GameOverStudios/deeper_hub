defmodule DeeperHub.Schema.SysAclActionsTrack do
  @moduledoc """
  Schema para representação de sys_acl_actions_tracks no sistema

  Este schema armazena as informações de um sys_acl_actions_track.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_acl_actions_track" do
    field :IDAction, :integer, default: 0  # int(10) unsigned
    field :IDMember, :integer, default: 0  # int(10) unsigned
    field :ActionsLeft, :integer, default: 0  # int(10) unsigned
    field :ValidSince, :naive_datetime  # datetime

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_acl_actions_track no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    IDAction: integer() | nil,
    IDMember: integer() | nil,
    ActionsLeft: integer() | nil,
    ValidSince: NaiveDateTime.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_acl_actions_track.

  ## Parâmetros 
    - `sys_acl_actions_track`: Struct do sys_acl_actions_track (pode ser %SysAclActionsTrack{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_acl_actions_track \ %__MODULE__{}, attrs) do
    sys_acl_actions_track
    |> cast(attrs, [:IDAction, :IDMember, :ActionsLeft, :ValidSince])
  end

  @doc """
  Changeset para atualização de um sys_acl_actions_track existente.

  ## Parâmetros 
    - `sys_acl_actions_track`: Struct do sys_acl_actions_track (%SysAclActionsTrack{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_acl_actions_track \ %__MODULE__{}, attrs) do
    sys_acl_actions_track
    |> cast(attrs, [:IDAction, :IDMember, :ActionsLeft, :ValidSince])
  end
end
