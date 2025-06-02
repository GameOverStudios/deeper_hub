defmodule DeeperHub.Schema.SysObjectsSearchExtended do
  @moduledoc """
  Schema para representação de sys_objects_search_extendeds no sistema

  Este schema armazena as informações de um sys_objects_search_extended.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_search_extended" do
    field :object, :string, default: ""  # varchar(64)
    field :object_content_info, :string, default: ""  # varchar(64)
    field :module, :string, default: ""  # varchar(32)
    field :title, :string, default: ""  # varchar(255)
    field :filter, :integer, default: 0  # tinyint(4)
    field :active, :integer, default: 0  # tinyint(4)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_search_extended no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    object_content_info: String.t() | nil,
    module: String.t() | nil,
    title: String.t() | nil,
    filter: integer() | nil,
    active: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_search_extended.

  ## Parâmetros 
    - `sys_objects_search_extended`: Struct do sys_objects_search_extended (pode ser %SysObjectsSearchExtended{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_search_extended \ %__MODULE__{}, attrs) do
    sys_objects_search_extended
    |> cast(attrs, [:object, :object_content_info, :module, :title, :filter, :active, :class_name, :class_file])
    |> validate_required([:object, :object_content_info, :module, :title, :class_name, :class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_search_extended existente.

  ## Parâmetros 
    - `sys_objects_search_extended`: Struct do sys_objects_search_extended (%SysObjectsSearchExtended{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_search_extended \ %__MODULE__{}, attrs) do
    sys_objects_search_extended
    |> cast(attrs, [:object, :object_content_info, :module, :title, :filter, :active, :class_name, :class_file])
    |> unique_constraint(:object)
  end
end
