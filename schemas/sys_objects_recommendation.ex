defmodule DeeperHub.Schema.SysObjectsRecommendation do
  @moduledoc """
  Schema para representação de sys_objects_recommendations no sistema

  Este schema armazena as informações de um sys_objects_recommendation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_recommendation" do
    field :name, :string, default: ""  # varchar(64)
    field :module, :string, default: ""  # varchar(64)
    field :connection, :string, default: ""  # varchar(64)
    field :content_info, :string, default: ""  # varchar(64)
    field :countable, :integer, default: 1  # tinyint(4)
    field :active, :integer, default: 1  # tinyint(4)
    field :class_name, :string, default: ""  # varchar(32)
    field :class_file, :string, default: ""  # varchar(256)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_recommendation no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    module: String.t() | nil,
    connection: String.t() | nil,
    content_info: String.t() | nil,
    countable: integer() | nil,
    active: integer() | nil,
    class_name: String.t() | nil,
    class_file: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_recommendation.

  ## Parâmetros 
    - `sys_objects_recommendation`: Struct do sys_objects_recommendation (pode ser %SysObjectsRecommendation{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_recommendation \ %__MODULE__{}, attrs) do
    sys_objects_recommendation
    |> cast(attrs, [:name, :module, :connection, :content_info, :countable, :active, :class_name, :class_file])
    |> validate_required([:name, :module, :connection, :content_info, :class_name, :class_file])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_objects_recommendation existente.

  ## Parâmetros 
    - `sys_objects_recommendation`: Struct do sys_objects_recommendation (%SysObjectsRecommendation{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_recommendation \ %__MODULE__{}, attrs) do
    sys_objects_recommendation
    |> cast(attrs, [:name, :module, :connection, :content_info, :countable, :active, :class_name, :class_file])
    |> unique_constraint(:name)
  end
end
