defmodule DeeperHub.Schema.SysObjectsScore do
  @moduledoc """
  Schema para representação de sys_objects_scores no sistema

  Este schema armazena as informações de um sys_objects_score.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_score" do
    field :name, :string, default: ""  # varchar(50)
    field :module, :string  # varchar(32)
    field :table_main, :string, default: ""  # varchar(50)
    field :table_track, :string, default: ""  # varchar(50)
    field :post_timeout, :integer, default: 0  # int(11)
    field :pruning, :integer, default: 31536000  # int(11)
    field :is_undo, :boolean, default: false  # tinyint(1)
    field :is_on, :boolean, default: true  # tinyint(1)
    field :trigger_table, :string, default: ""  # varchar(32)
    field :trigger_field_id, :string, default: ""  # varchar(32)
    field :trigger_field_author, :string, default: ""  # varchar(32)
    field :trigger_field_score, :string, default: ""  # varchar(32)
    field :trigger_field_cup, :string, default: ""  # varchar(32)
    field :trigger_field_cdown, :string, default: ""  # varchar(32)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_score no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    module: String.t() | nil,
    table_main: String.t() | nil,
    table_track: String.t() | nil,
    post_timeout: integer() | nil,
    pruning: integer() | nil,
    is_undo: boolean() | nil,
    is_on: boolean() | nil,
    trigger_table: String.t() | nil,
    trigger_field_id: String.t() | nil,
    trigger_field_author: String.t() | nil,
    trigger_field_score: String.t() | nil,
    trigger_field_cup: String.t() | nil,
    trigger_field_cdown: String.t() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_score.

  ## Parâmetros 
    - `sys_objects_score`: Struct do sys_objects_score (pode ser %SysObjectsScore{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_score \ %__MODULE__{}, attrs) do
    sys_objects_score
    |> cast(attrs, [:name, :module, :table_main, :table_track, :post_timeout, :pruning, :is_undo, :is_on, :trigger_table, :trigger_field_id, :trigger_field_author, :trigger_field_score, :trigger_field_cup, :trigger_field_cdown, :class_name, :class_file])
    |> validate_required([:name, :module, :table_main, :table_track, :trigger_table, :trigger_field_id, :trigger_field_author, :trigger_field_score, :trigger_field_cup, :trigger_field_cdown, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um sys_objects_score existente.

  ## Parâmetros 
    - `sys_objects_score`: Struct do sys_objects_score (%SysObjectsScore{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_score \ %__MODULE__{}, attrs) do
    sys_objects_score
    |> cast(attrs, [:name, :module, :table_main, :table_track, :post_timeout, :pruning, :is_undo, :is_on, :trigger_table, :trigger_field_id, :trigger_field_author, :trigger_field_score, :trigger_field_cup, :trigger_field_cdown, :class_name, :class_file])
  end
end
