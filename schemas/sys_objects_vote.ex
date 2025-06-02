defmodule DeeperHub.Schema.SysObjectsVote do
  @moduledoc """
  Schema para representação de sys_objects_votes no sistema

  Este schema armazena as informações de um sys_objects_vote.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_vote" do
    field :ID, :integer  # int(11) unsigned
    field :Name, :string, default: ""  # varchar(50)
    field :Module, :string, default: ""  # varchar(32)
    field :TableMain, :string, default: ""  # varchar(50)
    field :TableTrack, :string, default: ""  # varchar(50)
    field :PostTimeout, :integer, default: 0  # int(11)
    field :MinValue, :integer, default: 1  # tinyint(4)
    field :MaxValue, :integer, default: 5  # tinyint(4)
    field :Pruning, :integer, default: 31536000  # int(11)
    field :IsUndo, :boolean, default: false  # tinyint(1)
    field :IsOn, :boolean, default: true  # tinyint(1)
    field :TriggerTable, :string, default: ""  # varchar(32)
    field :TriggerFieldId, :string, default: ""  # varchar(32)
    field :TriggerFieldAuthor, :string, default: ""  # varchar(32)
    field :TriggerFieldRate, :string, default: ""  # varchar(32)
    field :TriggerFieldRateCount, :string, default: ""  # varchar(32)
    field :ClassName, :string, default: ""  # varchar(32)
    field :ClassFile, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_vote no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    Name: String.t() | nil,
    Module: String.t() | nil,
    TableMain: String.t() | nil,
    TableTrack: String.t() | nil,
    PostTimeout: integer() | nil,
    MinValue: integer() | nil,
    MaxValue: integer() | nil,
    Pruning: integer() | nil,
    IsUndo: boolean() | nil,
    IsOn: boolean() | nil,
    TriggerTable: String.t() | nil,
    TriggerFieldId: String.t() | nil,
    TriggerFieldAuthor: String.t() | nil,
    TriggerFieldRate: String.t() | nil,
    TriggerFieldRateCount: String.t() | nil,
    ClassName: String.t() | nil,
    ClassFile: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_vote.

  ## Parâmetros 
    - `sys_objects_vote`: Struct do sys_objects_vote (pode ser %SysObjectsVote{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_vote \ %__MODULE__{}, attrs) do
    sys_objects_vote
    |> cast(attrs, [:ID, :Name, :Module, :TableMain, :TableTrack, :PostTimeout, :MinValue, :MaxValue, :Pruning, :IsUndo, :IsOn, :TriggerTable, :TriggerFieldId, :TriggerFieldAuthor, :TriggerFieldRate, :TriggerFieldRateCount, :ClassName, :ClassFile])
    |> validate_required([:ID, :Name, :Module, :TableMain, :TableTrack, :TriggerTable, :TriggerFieldId, :TriggerFieldAuthor, :TriggerFieldRate, :TriggerFieldRateCount, :ClassName, :ClassFile])
  end

  @doc """
  Changeset para atualização de um sys_objects_vote existente.

  ## Parâmetros 
    - `sys_objects_vote`: Struct do sys_objects_vote (%SysObjectsVote{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_vote \ %__MODULE__{}, attrs) do
    sys_objects_vote
    |> cast(attrs, [:ID, :Name, :Module, :TableMain, :TableTrack, :PostTimeout, :MinValue, :MaxValue, :Pruning, :IsUndo, :IsOn, :TriggerTable, :TriggerFieldId, :TriggerFieldAuthor, :TriggerFieldRate, :TriggerFieldRateCount, :ClassName, :ClassFile])
  end
end
