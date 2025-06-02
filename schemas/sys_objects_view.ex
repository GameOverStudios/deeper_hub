defmodule DeeperHub.Schema.SysObjectsView do
  @moduledoc """
  Schema para representação de sys_objects_views no sistema

  Este schema armazena as informações de um sys_objects_view.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_view" do
    field :name, :string  # varchar(64)
    field :module, :string, default: ""  # varchar(32)
    field :table_track, :string  # varchar(32)
    field :period, :integer, default: 86400  # int(11)
    field :pruning, :integer, default: 31536000  # int(11)
    field :is_on, :integer, default: 1  # tinyint(4)
    field :trigger_table, :string  # varchar(32)
    field :trigger_field_id, :string  # varchar(32)
    field :trigger_field_author, :string  # varchar(32)
    field :trigger_field_count, :string  # varchar(32)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_view no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    module: String.t() | nil,
    table_track: String.t() | nil,
    period: integer() | nil,
    pruning: integer() | nil,
    is_on: integer() | nil,
    trigger_table: String.t() | nil,
    trigger_field_id: String.t() | nil,
    trigger_field_author: String.t() | nil,
    trigger_field_count: String.t() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_view.

  ## Parâmetros 
    - `sys_objects_view`: Struct do sys_objects_view (pode ser %SysObjectsView{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_view \ %__MODULE__{}, attrs) do
    sys_objects_view
    |> cast(attrs, [:name, :module, :table_track, :period, :pruning, :is_on, :trigger_table, :trigger_field_id, :trigger_field_author, :trigger_field_count, :class_name, :class_file])
    |> validate_required([:name, :module, :table_track, :trigger_table, :trigger_field_id, :trigger_field_author, :trigger_field_count, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um sys_objects_view existente.

  ## Parâmetros 
    - `sys_objects_view`: Struct do sys_objects_view (%SysObjectsView{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_view \ %__MODULE__{}, attrs) do
    sys_objects_view
    |> cast(attrs, [:name, :module, :table_track, :period, :pruning, :is_on, :trigger_table, :trigger_field_id, :trigger_field_author, :trigger_field_count, :class_name, :class_file])
  end
end
