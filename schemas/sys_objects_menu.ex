defmodule DeeperHub.Schema.SysObjectsMenu do
  @moduledoc """
  Schema para representação de sys_objects_menus no sistema

  Este schema armazena as informações de um sys_objects_menu.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_menu" do
    field :object, :string  # varchar(64)
    field :title, :string  # varchar(255)
    field :set_name, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :template_id, :integer  # int(11)
    field :config_api, :string  # text
    field :persistent, :integer, default: 0  # tinyint(4)
    field :deletable, :integer, default: 1  # tinyint(4)
    field :active, :integer, default: 0  # tinyint(4)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_menu no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    title: String.t() | nil,
    set_name: String.t() | nil,
    module: String.t() | nil,
    template_id: integer() | nil,
    config_api: String.t() | nil,
    persistent: integer() | nil,
    deletable: integer() | nil,
    active: integer() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_menu.

  ## Parâmetros 
    - `sys_objects_menu`: Struct do sys_objects_menu (pode ser %SysObjectsMenu{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_menu \ %__MODULE__{}, attrs) do
    sys_objects_menu
    |> cast(attrs, [:object, :title, :set_name, :module, :template_id, :config_api, :persistent, :deletable, :active, :override_class_name, :override_class_file])
    |> validate_required([:object, :title, :set_name, :module, :template_id, :config_api, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_menu existente.

  ## Parâmetros 
    - `sys_objects_menu`: Struct do sys_objects_menu (%SysObjectsMenu{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_menu \ %__MODULE__{}, attrs) do
    sys_objects_menu
    |> cast(attrs, [:object, :title, :set_name, :module, :template_id, :config_api, :persistent, :deletable, :active, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
