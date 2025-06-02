defmodule DeeperHub.Schema.SysObjectsPrivacy do
  @moduledoc """
  Schema para representação de sys_objects_privacys no sistema

  Este schema armazena as informações de um sys_objects_privacy.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_privacy" do
    field :object, :string, default: ""  # varchar(64)
    field :module, :string, default: ""  # varchar(64)
    field :action, :string, default: ""  # varchar(255)
    field :title, :string, default: ""  # varchar(255)
    field :default_group, :string, default: "1"  # varchar(255)
    field :spaces, :string, default: "all"  # varchar(255)
    field :table, :string, default: ""  # varchar(255)
    field :table_field_id, :string, default: ""  # varchar(255)
    field :table_field_author, :string, default: ""  # varchar(255)
    field :override_class_name, :string, default: ""  # varchar(255)
    field :override_class_file, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_privacy no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    action: String.t() | nil,
    title: String.t() | nil,
    default_group: String.t() | nil,
    spaces: String.t() | nil,
    table: String.t() | nil,
    table_field_id: String.t() | nil,
    table_field_author: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_privacy.

  ## Parâmetros 
    - `sys_objects_privacy`: Struct do sys_objects_privacy (pode ser %SysObjectsPrivacy{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_privacy \ %__MODULE__{}, attrs) do
    sys_objects_privacy
    |> cast(attrs, [:object, :module, :action, :title, :default_group, :spaces, :table, :table_field_id, :table_field_author, :override_class_name, :override_class_file])
    |> validate_required([:object, :module, :action, :title, :table, :table_field_id, :table_field_author, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_privacy existente.

  ## Parâmetros 
    - `sys_objects_privacy`: Struct do sys_objects_privacy (%SysObjectsPrivacy{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_privacy \ %__MODULE__{}, attrs) do
    sys_objects_privacy
    |> cast(attrs, [:object, :module, :action, :title, :default_group, :spaces, :table, :table_field_id, :table_field_author, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
