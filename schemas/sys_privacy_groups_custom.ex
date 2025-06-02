defmodule DeeperHub.Schema.SysPrivacyGroupsCustom do
  @moduledoc """
  Schema para representação de sys_privacy_groups_customs no sistema

  Este schema armazena as informações de um sys_privacy_groups_custom.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_privacy_groups_custom" do
    field :profile_id, :integer, default: 0  # int(11)
    field :content_id, :integer, default: 0  # int(11)
    field :object, :string, default: ""  # varchar(64)
    field :group_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_privacy_groups_custom no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    content_id: integer() | nil,
    object: String.t() | nil,
    group_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_privacy_groups_custom.

  ## Parâmetros 
    - `sys_privacy_groups_custom`: Struct do sys_privacy_groups_custom (pode ser %SysPrivacyGroupsCustom{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_privacy_groups_custom \ %__MODULE__{}, attrs) do
    sys_privacy_groups_custom
    |> cast(attrs, [:profile_id, :content_id, :object, :group_id])
    |> validate_required([:object])
  end

  @doc """
  Changeset para atualização de um sys_privacy_groups_custom existente.

  ## Parâmetros 
    - `sys_privacy_groups_custom`: Struct do sys_privacy_groups_custom (%SysPrivacyGroupsCustom{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_privacy_groups_custom \ %__MODULE__{}, attrs) do
    sys_privacy_groups_custom
    |> cast(attrs, [:profile_id, :content_id, :object, :group_id])
  end
end
