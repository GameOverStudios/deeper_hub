defmodule DeeperHub.Schema.SysAclLevelsMember do
  @moduledoc """
  Schema para representação de sys_acl_levels_members no sistema

  Este schema armazena as informações de um sys_acl_levels_member.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_acl_levels_members" do
    field :IDMember, :integer, default: 0  # int(10) unsigned
    field :IDLevel, :integer, default: 0  # int(10) unsigned
    field :DateStarts, :naive_datetime, default: "0000-00-00 00:00:00"  # datetime
    field :DateExpires, :naive_datetime  # datetime
    field :State, :string, default: ""  # varchar(16)
    field :TransactionID, :string, default: ""  # varchar(16)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_acl_levels_member no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    IDMember: integer() | nil,
    IDLevel: integer() | nil,
    DateStarts: NaiveDateTime.t() | nil,
    DateExpires: NaiveDateTime.t() | nil,
    State: String.t() | nil,
    TransactionID: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_acl_levels_member.

  ## Parâmetros 
    - `sys_acl_levels_member`: Struct do sys_acl_levels_member (pode ser %SysAclLevelsMember{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_acl_levels_member \ %__MODULE__{}, attrs) do
    sys_acl_levels_member
    |> cast(attrs, [:IDMember, :IDLevel, :DateStarts, :DateExpires, :State, :TransactionID])
    |> validate_required([:State, :TransactionID])
  end

  @doc """
  Changeset para atualização de um sys_acl_levels_member existente.

  ## Parâmetros 
    - `sys_acl_levels_member`: Struct do sys_acl_levels_member (%SysAclLevelsMember{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_acl_levels_member \ %__MODULE__{}, attrs) do
    sys_acl_levels_member
    |> cast(attrs, [:IDMember, :IDLevel, :DateStarts, :DateExpires, :State, :TransactionID])
  end
end
