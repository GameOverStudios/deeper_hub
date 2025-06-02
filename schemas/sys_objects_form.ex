defmodule DeeperHub.Schema.SysObjectsForm do
  @moduledoc """
  Schema para representação de sys_objects_forms no sistema

  Este schema armazena as informações de um sys_objects_form.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_form" do
    field :object, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :action, :string  # varchar(255)
    field :form_attrs, :string  # text
    field :submit_name, :string  # varchar(255)
    field :table, :string  # varchar(255)
    field :key, :string  # varchar(255)
    field :uri, :string  # varchar(255)
    field :uri_title, :string  # varchar(255)
    field :params, :string  # text
    field :deletable, :integer, default: 1  # tinyint(4)
    field :active, :integer, default: 0  # tinyint(4)
    field :parent_form, :string, default: ""  # varchar(64)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_form no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    module: String.t() | nil,
    title: String.t() | nil,
    action: String.t() | nil,
    form_attrs: String.t() | nil,
    submit_name: String.t() | nil,
    table: String.t() | nil,
    key: String.t() | nil,
    uri: String.t() | nil,
    uri_title: String.t() | nil,
    params: String.t() | nil,
    deletable: integer() | nil,
    active: integer() | nil,
    parent_form: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_form.

  ## Parâmetros 
    - `sys_objects_form`: Struct do sys_objects_form (pode ser %SysObjectsForm{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_form \ %__MODULE__{}, attrs) do
    sys_objects_form
    |> cast(attrs, [:object, :module, :title, :action, :form_attrs, :submit_name, :table, :key, :uri, :uri_title, :params, :deletable, :active, :parent_form, :override_class_name, :override_class_file])
    |> validate_required([:object, :module, :title, :action, :form_attrs, :submit_name, :table, :key, :uri, :uri_title, :params, :parent_form, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_form existente.

  ## Parâmetros 
    - `sys_objects_form`: Struct do sys_objects_form (%SysObjectsForm{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_form \ %__MODULE__{}, attrs) do
    sys_objects_form
    |> cast(attrs, [:object, :module, :title, :action, :form_attrs, :submit_name, :table, :key, :uri, :uri_title, :params, :deletable, :active, :parent_form, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
