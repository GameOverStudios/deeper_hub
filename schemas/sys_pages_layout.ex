defmodule DeeperHub.Schema.SysPagesLayout do
  @moduledoc """
  Schema para representação de sys_pages_layouts no sistema

  Este schema armazena as informações de um sys_pages_layout.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_layouts" do
    field :name, :string  # varchar(64)
    field :icon, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :template, :string  # varchar(255)
    field :cells_number, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_layout no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    icon: String.t() | nil,
    title: String.t() | nil,
    template: String.t() | nil,
    cells_number: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_layout.

  ## Parâmetros 
    - `sys_pages_layout`: Struct do sys_pages_layout (pode ser %SysPagesLayout{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_layout \ %__MODULE__{}, attrs) do
    sys_pages_layout
    |> cast(attrs, [:name, :icon, :title, :template, :cells_number])
    |> validate_required([:name, :icon, :title, :template, :cells_number])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_pages_layout existente.

  ## Parâmetros 
    - `sys_pages_layout`: Struct do sys_pages_layout (%SysPagesLayout{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_layout \ %__MODULE__{}, attrs) do
    sys_pages_layout
    |> cast(attrs, [:name, :icon, :title, :template, :cells_number])
    |> unique_constraint(:name)
  end
end
