defmodule DeeperHub.Schema.SysPrivacyDefault do
  @moduledoc """
  Schema para representação de sys_privacy_defaults no sistema

  Este schema armazena as informações de um sys_privacy_default.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_privacy_defaults" do
    field :owner_id, :integer, default: 0  # int(11)
    field :action_id, :integer, default: 0  # int(11)
    field :group_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_privacy_default no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    owner_id: integer() | nil,
    action_id: integer() | nil,
    group_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_privacy_default.

  ## Parâmetros 
    - `sys_privacy_default`: Struct do sys_privacy_default (pode ser %SysPrivacyDefault{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_privacy_default \ %__MODULE__{}, attrs) do
    sys_privacy_default
    |> cast(attrs, [:owner_id, :action_id, :group_id])
  end

  @doc """
  Changeset para atualização de um sys_privacy_default existente.

  ## Parâmetros 
    - `sys_privacy_default`: Struct do sys_privacy_default (%SysPrivacyDefault{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_privacy_default \ %__MODULE__{}, attrs) do
    sys_privacy_default
    |> cast(attrs, [:owner_id, :action_id, :group_id])
  end
end
