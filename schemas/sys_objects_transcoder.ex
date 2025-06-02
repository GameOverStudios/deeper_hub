defmodule DeeperHub.Schema.SysObjectsTranscoder do
  @moduledoc """
  Schema para representação de sys_objects_transcoders no sistema

  Este schema armazena as informações de um sys_objects_transcoder.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_transcoder" do
    field :object, :string  # varchar(64)
    field :storage_object, :string  # varchar(64)
    field :source_type, Ecto.Enum, values: [:Folder, :Storage, :Proxy]  # enum('Folder','Storage','Proxy')
    field :source_params, :string  # text
    field :private, Ecto.Enum, values: [:auto, :yes, :no]  # enum('auto','yes','no')
    field :atime_tracking, :integer  # int(11)
    field :atime_pruning, :integer  # int(11)
    field :ts, :integer, default: 0  # int(11)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_transcoder no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    storage_object: String.t() | nil,
    source_type: :Folder | :Storage | :Proxy | nil,
    source_params: String.t() | nil,
    private: :auto | :yes | :no | nil,
    atime_tracking: integer() | nil,
    atime_pruning: integer() | nil,
    ts: integer() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_transcoder.

  ## Parâmetros 
    - `sys_objects_transcoder`: Struct do sys_objects_transcoder (pode ser %SysObjectsTranscoder{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_transcoder \ %__MODULE__{}, attrs) do
    sys_objects_transcoder
    |> cast(attrs, [:object, :storage_object, :source_type, :source_params, :private, :atime_tracking, :atime_pruning, :ts, :override_class_name, :override_class_file])
    |> validate_required([:object, :storage_object, :source_type, :source_params, :private, :atime_tracking, :atime_pruning, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_transcoder existente.

  ## Parâmetros 
    - `sys_objects_transcoder`: Struct do sys_objects_transcoder (%SysObjectsTranscoder{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_transcoder \ %__MODULE__{}, attrs) do
    sys_objects_transcoder
    |> cast(attrs, [:object, :storage_object, :source_type, :source_params, :private, :atime_tracking, :atime_pruning, :ts, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
