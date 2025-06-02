defmodule DeeperHub.Schema.SysPrivacyGroupsCustomMember do
  @moduledoc """
  Schema para representação de sys_privacy_groups_custom_members no sistema

  Este schema armazena as informações de um sys_privacy_groups_custom_member.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_privacy_groups_custom_members" do
    field :group_id, :integer, default: 0  # int(11)
    field :member_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_privacy_groups_custom_member no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group_id: integer() | nil,
    member_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_privacy_groups_custom_member.

  ## Parâmetros 
    - `sys_privacy_groups_custom_member`: Struct do sys_privacy_groups_custom_member (pode ser %SysPrivacyGroupsCustomMember{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_privacy_groups_custom_member \ %__MODULE__{}, attrs) do
    sys_privacy_groups_custom_member
    |> cast(attrs, [:group_id, :member_id])
  end

  @doc """
  Changeset para atualização de um sys_privacy_groups_custom_member existente.

  ## Parâmetros 
    - `sys_privacy_groups_custom_member`: Struct do sys_privacy_groups_custom_member (%SysPrivacyGroupsCustomMember{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_privacy_groups_custom_member \ %__MODULE__{}, attrs) do
    sys_privacy_groups_custom_member
    |> cast(attrs, [:group_id, :member_id])
  end
end
