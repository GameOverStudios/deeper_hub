defmodule DeeperHub.Schema.SysStdPage do
  @moduledoc """
  Schema para representação de sys_std_pages no sistema

  Este schema armazena as informações de um sys_std_page.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_std_pages" do
    field :index, :integer, default: 0  # int(11) unsigned
    field :name, :string, default: ""  # varchar(64)
    field :header, :string, default: ""  # varchar(255)
    field :caption, :string, default: ""  # varchar(255)
    field :icon, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_std_page no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    index: integer() | nil,
    name: String.t() | nil,
    header: String.t() | nil,
    caption: String.t() | nil,
    icon: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_std_page.

  ## Parâmetros 
    - `sys_std_page`: Struct do sys_std_page (pode ser %SysStdPage{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_std_page \ %__MODULE__{}, attrs) do
    sys_std_page
    |> cast(attrs, [:index, :name, :header, :caption, :icon])
    |> validate_required([:name, :header, :caption, :icon])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_std_page existente.

  ## Parâmetros 
    - `sys_std_page`: Struct do sys_std_page (%SysStdPage{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_std_page \ %__MODULE__{}, attrs) do
    sys_std_page
    |> cast(attrs, [:index, :name, :header, :caption, :icon])
    |> unique_constraint(:name)
  end
end
