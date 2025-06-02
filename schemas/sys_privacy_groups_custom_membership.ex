defmodule DeeperHub.Schema.SysPrivacyGroupsCustomMembership do
  @moduledoc """
  Schema para representação de sys_privacy_groups_custom_memberships no sistema

  Este schema armazena as informações de um sys_privacy_groups_custom_membership.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_privacy_groups_custom_memberships" do
    field :group_id, :integer, default: 0  # int(11)
    field :membership_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_privacy_groups_custom_membership no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    group_id: integer() | nil,
    membership_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_privacy_groups_custom_membership.

  ## Parâmetros 
    - `sys_privacy_groups_custom_membership`: Struct do sys_privacy_groups_custom_membership (pode ser %SysPrivacyGroupsCustomMembership{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_privacy_groups_custom_membership \ %__MODULE__{}, attrs) do
    sys_privacy_groups_custom_membership
    |> cast(attrs, [:group_id, :membership_id])
  end

  @doc """
  Changeset para atualização de um sys_privacy_groups_custom_membership existente.

  ## Parâmetros 
    - `sys_privacy_groups_custom_membership`: Struct do sys_privacy_groups_custom_membership (%SysPrivacyGroupsCustomMembership{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_privacy_groups_custom_membership \ %__MODULE__{}, attrs) do
    sys_privacy_groups_custom_membership
    |> cast(attrs, [:group_id, :membership_id])
  end
end
