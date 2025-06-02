defmodule DeeperHub.Schema.SysObjectsSearch do
  @moduledoc """
  Schema para representação de sys_objects_searchs no sistema

  Este schema armazena as informações de um sys_objects_search.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_objects_search" do
    field :ID, :integer  # int(10) unsigned
    field :ObjectName, :string, default: ""  # varchar(64)
    field :Title, :string, default: ""  # varchar(50)
    field :Order, :integer  # int(11)
    field :GlobalSearch, :integer, default: 1  # tinyint(4)
    field :ClassName, :string, default: ""  # varchar(50)
    field :ClassPath, :string, default: ""  # varchar(100)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_objects_search no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    ObjectName: String.t() | nil,
    Title: String.t() | nil,
    Order: integer() | nil,
    GlobalSearch: integer() | nil,
    ClassName: String.t() | nil,
    ClassPath: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_objects_search.

  ## Parâmetros 
    - `sys_objects_search`: Struct do sys_objects_search (pode ser %SysObjectsSearch{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_objects_search \ %__MODULE__{}, attrs) do
    sys_objects_search
    |> cast(attrs, [:ID, :ObjectName, :Title, :Order, :GlobalSearch, :ClassName, :ClassPath])
    |> validate_required([:ID, :ObjectName, :Title, :Order, :ClassName, :ClassPath])
  end

  @doc """
  Changeset para atualização de um sys_objects_search existente.

  ## Parâmetros 
    - `sys_objects_search`: Struct do sys_objects_search (%SysObjectsSearch{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_objects_search \ %__MODULE__{}, attrs) do
    sys_objects_search
    |> cast(attrs, [:ID, :ObjectName, :Title, :Order, :GlobalSearch, :ClassName, :ClassPath])
  end
end
