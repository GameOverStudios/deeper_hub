defmodule DeeperHub.Schema.SysObjectsContentInfo do
  @moduledoc """
  Schema para representação de sys_objects_content_infos no sistema

  Este schema armazena as informações de um sys_objects_content_info.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_content_info" do
    field :name, :string  # varchar(64)
    field :title, :string  # varchar(128)
    field :alert_unit, :string  # varchar(32)
    field :alert_action_add, :string  # varchar(32)
    field :alert_action_update, :string  # varchar(32)
    field :alert_action_delete, :string  # varchar(32)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_content_info no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    alert_unit: String.t() | nil,
    alert_action_add: String.t() | nil,
    alert_action_update: String.t() | nil,
    alert_action_delete: String.t() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_content_info.

  ## Parâmetros 
    - `sys_objects_content_info`: Struct do sys_objects_content_info (pode ser %SysObjectsContentInfo{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_content_info \ %__MODULE__{}, attrs) do
    sys_objects_content_info
    |> cast(attrs, [:name, :title, :alert_unit, :alert_action_add, :alert_action_update, :alert_action_delete, :class_name, :class_file])
    |> validate_required([:name, :title, :alert_unit, :alert_action_add, :alert_action_update, :alert_action_delete, :class_name, :class_file])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_objects_content_info existente.

  ## Parâmetros 
    - `sys_objects_content_info`: Struct do sys_objects_content_info (%SysObjectsContentInfo{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_content_info \ %__MODULE__{}, attrs) do
    sys_objects_content_info
    |> cast(attrs, [:name, :title, :alert_unit, :alert_action_add, :alert_action_update, :alert_action_delete, :class_name, :class_file])
    |> unique_constraint(:name)
  end
end
