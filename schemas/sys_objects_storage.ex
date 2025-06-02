defmodule DeeperHub.Schema.SysObjectsStorage do
  @moduledoc """
  Schema para representação de sys_objects_storages no sistema

  Este schema armazena as informações de um sys_objects_storage.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_storage" do
    field :object, :string  # varchar(64)
    field :engine, :string  # varchar(32)
    field :params, :string  # text
    field :token_life, :integer  # int(11)
    field :cache_control, :integer  # int(11)
    field :levels, :integer  # tinyint(4)
    field :table_files, :string  # varchar(64)
    field :ext_mode, Ecto.Enum, values: [:allow-deny, :deny-allow]  # enum('allow-deny','deny-allow')
    field :ext_allow, :string  # text
    field :ext_deny, :string  # text
    field :quota_size, :integer  # int(11)
    field :current_size, :integer  # int(11)
    field :quota_number, :integer  # int(11)
    field :current_number, :integer  # int(11)
    field :max_file_size, :integer  # int(11)
    field :ts, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_storage no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    engine: String.t() | nil,
    params: String.t() | nil,
    token_life: integer() | nil,
    cache_control: integer() | nil,
    levels: integer() | nil,
    table_files: String.t() | nil,
    ext_mode: :allow-deny | :deny-allow | nil,
    ext_allow: String.t() | nil,
    ext_deny: String.t() | nil,
    quota_size: integer() | nil,
    current_size: integer() | nil,
    quota_number: integer() | nil,
    current_number: integer() | nil,
    max_file_size: integer() | nil,
    ts: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_storage.

  ## Parâmetros 
    - `sys_objects_storage`: Struct do sys_objects_storage (pode ser %SysObjectsStorage{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_storage \ %__MODULE__{}, attrs) do
    sys_objects_storage
    |> cast(attrs, [:object, :engine, :params, :token_life, :cache_control, :levels, :table_files, :ext_mode, :ext_allow, :ext_deny, :quota_size, :current_size, :quota_number, :current_number, :max_file_size, :ts])
    |> validate_required([:object, :engine, :params, :token_life, :cache_control, :levels, :table_files, :ext_mode, :ext_allow, :ext_deny, :quota_size, :current_size, :quota_number, :current_number, :max_file_size, :ts])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_storage existente.

  ## Parâmetros 
    - `sys_objects_storage`: Struct do sys_objects_storage (%SysObjectsStorage{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_storage \ %__MODULE__{}, attrs) do
    sys_objects_storage
    |> cast(attrs, [:object, :engine, :params, :token_life, :cache_control, :levels, :table_files, :ext_mode, :ext_allow, :ext_deny, :quota_size, :current_size, :quota_number, :current_number, :max_file_size, :ts])
    |> unique_constraint(:object)
  end
end
