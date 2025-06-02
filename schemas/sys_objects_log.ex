defmodule DeeperHub.Schema.SysObjectsLog do
  @moduledoc """
  Schema para representação de sys_objects_logs no sistema

  Este schema armazena as informações de um sys_objects_log.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_logs" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :logs_storage, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :active, :integer, default: 1  # tinyint(4)
    field :class_name, :string  # varchar(255)
    field :class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_log no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    logs_storage: String.t() | nil,
    title: String.t() | nil,
    active: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_log.

  ## Parâmetros 
    - `sys_objects_log`: Struct do sys_objects_log (pode ser %SysObjectsLog{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_log \ %__MODULE__{}, attrs) do
    sys_objects_log
    |> cast(attrs, [:object, :module, :logs_storage, :title, :active, :class_name, :class_file])
    |> validate_required([:object, :module, :logs_storage, :title, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um sys_objects_log existente.

  ## Parâmetros 
    - `sys_objects_log`: Struct do sys_objects_log (%SysObjectsLog{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_log \ %__MODULE__{}, attrs) do
    sys_objects_log
    |> cast(attrs, [:object, :module, :logs_storage, :title, :active, :class_name, :class_file])
  end
end
