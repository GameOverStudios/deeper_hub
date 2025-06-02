defmodule DeeperHub.Schema.SysObjectsCategory do
  @moduledoc """
  Schema para representação de sys_objects_categorys no sistema

  Este schema armazena as informações de um sys_objects_category.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_category" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :search_object, :string  # varchar(64)
    field :form_object, :string  # varchar(64)
    field :list_name, :string  # varchar(255)
    field :table, :string  # varchar(255)
    field :field, :string  # varchar(255)
    field :join, :string  # varchar(255)
    field :where, :string  # varchar(255)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_category no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    search_object: String.t() | nil,
    form_object: String.t() | nil,
    list_name: String.t() | nil,
    table: String.t() | nil,
    field: String.t() | nil,
    join: String.t() | nil,
    where: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_category.

  ## Parâmetros 
    - `sys_objects_category`: Struct do sys_objects_category (pode ser %SysObjectsCategory{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_category \ %__MODULE__{}, attrs) do
    sys_objects_category
    |> cast(attrs, [:object, :module, :search_object, :form_object, :list_name, :table, :field, :join, :where, :override_class_name, :override_class_file])
    |> validate_required([:object, :module, :search_object, :form_object, :list_name, :table, :field, :join, :where, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_category existente.

  ## Parâmetros 
    - `sys_objects_category`: Struct do sys_objects_category (%SysObjectsCategory{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_category \ %__MODULE__{}, attrs) do
    sys_objects_category
    |> cast(attrs, [:object, :module, :search_object, :form_object, :list_name, :table, :field, :join, :where, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
