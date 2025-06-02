defmodule DeeperHub.Schema.SysObjectsLocationField do
  @moduledoc """
  Schema para representação de sys_objects_location_fields no sistema

  Este schema armazena as informações de um sys_objects_location_field.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_location_field" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :class_name, :string  # varchar(255)
    field :class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_location_field no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    title: String.t() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_location_field.

  ## Parâmetros 
    - `sys_objects_location_field`: Struct do sys_objects_location_field (pode ser %SysObjectsLocationField{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_location_field \ %__MODULE__{}, attrs) do
    sys_objects_location_field
    |> cast(attrs, [:object, :module, :title, :class_name, :class_file])
    |> validate_required([:object, :module, :title, :class_name, :class_file])
  end

  @doc """
  Changeset para atualização de um sys_objects_location_field existente.

  ## Parâmetros 
    - `sys_objects_location_field`: Struct do sys_objects_location_field (%SysObjectsLocationField{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_location_field \ %__MODULE__{}, attrs) do
    sys_objects_location_field
    |> cast(attrs, [:object, :module, :title, :class_name, :class_file])
  end
end
