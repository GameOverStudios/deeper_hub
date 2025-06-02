defmodule DeeperHub.Schema.SysStdRole do
  @moduledoc """
  Schema para representação de sys_std_roles no sistema

  Este schema armazena as informações de um sys_std_role.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_roles" do
    field :name, :string, default: ""  # varchar(64)
    field :title, :string  # varchar(255)
    field :description, :string, default: ""  # varchar(255)
    field :active, :integer, default: 1  # tinyint(4)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_role no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    description: String.t() | nil,
    active: integer() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_role.

  ## Parâmetros 
    - `sys_std_role`: Struct do sys_std_role (pode ser %SysStdRole{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_role \ %__MODULE__{}, attrs) do
    sys_std_role
    |> cast(attrs, [:name, :title, :description, :active, :order])
    |> validate_required([:name, :title, :description])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_std_role existente.

  ## Parâmetros 
    - `sys_std_role`: Struct do sys_std_role (%SysStdRole{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_role \ %__MODULE__{}, attrs) do
    sys_std_role
    |> cast(attrs, [:name, :title, :description, :active, :order])
    |> unique_constraint(:name)
  end
end
