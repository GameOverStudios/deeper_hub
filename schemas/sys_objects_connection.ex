defmodule DeeperHub.Schema.SysObjectsConnection do
  @moduledoc """
  Schema para representação de sys_objects_connections no sistema

  Este schema armazena as informações de um sys_objects_connection.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_connection" do
    field :object, :string  # varchar(64)
    field :table, :string  # varchar(255)
    field :profile_initiator, :integer, default: 1  # tinyint(4)
    field :profile_content, :integer, default: 0  # tinyint(4)
    field :type, Ecto.Enum, values: [:one-way, :mutual]  # enum('one-way','mutual')
    field :tt_initiator, :string, default: ""  # varchar(32)
    field :tf_id_initiator, :string, default: ""  # varchar(32)
    field :tf_count_initiator, :string, default: ""  # varchar(32)
    field :tt_content, :string, default: ""  # varchar(32)
    field :tf_id_content, :string, default: ""  # varchar(32)
    field :tf_count_content, :string, default: ""  # varchar(32)
    field :override_class_name, :string  # varchar(255)
    field :override_class_file, :string  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_connection no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object: String.t() | nil,
    table: String.t() | nil,
    profile_initiator: integer() | nil,
    profile_content: integer() | nil,
    type: :one-way | :mutual | nil,
    tt_initiator: String.t() | nil,
    tf_id_initiator: String.t() | nil,
    tf_count_initiator: String.t() | nil,
    tt_content: String.t() | nil,
    tf_id_content: String.t() | nil,
    tf_count_content: String.t() | nil,
    override_class_name: String.t() | nil,
    override_class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_connection.

  ## Parâmetros 
    - `sys_objects_connection`: Struct do sys_objects_connection (pode ser %SysObjectsConnection{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_connection \ %__MODULE__{}, attrs) do
    sys_objects_connection
    |> cast(attrs, [:object, :table, :profile_initiator, :profile_content, :type, :tt_initiator, :tf_id_initiator, :tf_count_initiator, :tt_content, :tf_id_content, :tf_count_content, :override_class_name, :override_class_file])
    |> validate_required([:object, :table, :type, :tt_initiator, :tf_id_initiator, :tf_count_initiator, :tt_content, :tf_id_content, :tf_count_content, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end

  @doc """
  Changeset para atualização de um sys_objects_connection existente.

  ## Parâmetros 
    - `sys_objects_connection`: Struct do sys_objects_connection (%SysObjectsConnection{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_connection \ %__MODULE__{}, attrs) do
    sys_objects_connection
    |> cast(attrs, [:object, :table, :profile_initiator, :profile_content, :type, :tt_initiator, :tf_id_initiator, :tf_count_initiator, :tt_content, :tf_id_content, :tf_count_content, :override_class_name, :override_class_file])
    |> unique_constraint(:object)
  end
end
