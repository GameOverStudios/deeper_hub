defmodule DeeperHub.Schema.SysModule do
  @moduledoc """
  Schema para representação de sys_modules no sistema

  Este schema armazena as informações de um sys_module.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_modules" do
    field :type, :string, default: "module"  # varchar(16)
    field :subtypes, :integer, default: 0  # int(11) unsigned
    field :name, :string, default: ""  # varchar(32)
    field :title, :string, default: ""  # varchar(255)
    field :vendor, :string, default: ""  # varchar(64)
    field :version, :string, default: ""  # varchar(32)
    field :help_url, :string, default: ""  # varchar(128)
    field :path, :string, default: ""  # varchar(255)
    field :uri, :string, default: ""  # varchar(32)
    field :class_prefix, :string, default: ""  # varchar(32)
    field :db_prefix, :string, default: ""  # varchar(32)
    field :lang_category, :string, default: ""  # varchar(64)
    field :dependencies, :string, default: ""  # varchar(255)
    field :date, :integer, default: 0  # int(11) unsigned
    field :enabled, :boolean, default: false  # tinyint(1)
    field :pending_uninstall, :integer  # tinyint(4)
    field :hash, :string, default: ""  # varchar(32)
    field :updated, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_module no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    type: String.t() | nil,
    subtypes: integer() | nil,
    name: String.t() | nil,
    title: String.t() | nil,
    vendor: String.t() | nil,
    version: String.t() | nil,
    help_url: String.t() | nil,
    path: String.t() | nil,
    uri: String.t() | nil,
    class_prefix: String.t() | nil,
    db_prefix: String.t() | nil,
    lang_category: String.t() | nil,
    dependencies: String.t() | nil,
    date: integer() | nil,
    enabled: boolean() | nil,
    pending_uninstall: integer() | nil,
    hash: String.t() | nil,
    updated: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_module.

  ## Parâmetros 
    - `sys_module`: Struct do sys_module (pode ser %SysModule{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_module \ %__MODULE__{}, attrs) do
    sys_module
    |> cast(attrs, [:type, :subtypes, :name, :title, :vendor, :version, :help_url, :path, :uri, :class_prefix, :db_prefix, :lang_category, :dependencies, :date, :enabled, :pending_uninstall, :hash, :updated])
    |> validate_required([:name, :title, :vendor, :version, :help_url, :path, :uri, :class_prefix, :db_prefix, :lang_category, :dependencies, :pending_uninstall, :hash])
    |> unique_constraint(:name)
    |> unique_constraint(:path)
    |> unique_constraint(:uri)
    |> unique_constraint(:class_prefix)
    |> unique_constraint(:db_prefix)
  end

  @doc """
  Changeset para atualização de um sys_module existente.

  ## Parâmetros 
    - `sys_module`: Struct do sys_module (%SysModule{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_module \ %__MODULE__{}, attrs) do
    sys_module
    |> cast(attrs, [:type, :subtypes, :name, :title, :vendor, :version, :help_url, :path, :uri, :class_prefix, :db_prefix, :lang_category, :dependencies, :date, :enabled, :pending_uninstall, :hash, :updated])
    |> unique_constraint(:name)
    |> unique_constraint(:path)
    |> unique_constraint(:uri)
    |> unique_constraint(:class_prefix)
    |> unique_constraint(:db_prefix)
  end
end
