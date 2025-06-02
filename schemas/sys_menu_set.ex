defmodule DeeperHub.Schema.SysMenuSet do
  @moduledoc """
  Schema para representação de sys_menu_sets no sistema

  Este schema armazena as informações de um sys_menu_set.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_menu_sets" do
    field :set_name, :string  # varchar(64)
    field :module, :string  # varchar(32)
    field :title, :string  # varchar(255)
    field :deletable, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_menu_set no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    set_name: String.t() | nil,
    module: String.t() | nil,
    title: String.t() | nil,
    deletable: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_menu_set.

  ## Parâmetros 
    - `sys_menu_set`: Struct do sys_menu_set (pode ser %SysMenuSet{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_menu_set \ %__MODULE__{}, attrs) do
    sys_menu_set
    |> cast(attrs, [:set_name, :module, :title, :deletable])
    |> validate_required([:set_name, :module, :title])
  end

  @doc """
  Changeset para atualização de um sys_menu_set existente.

  ## Parâmetros 
    - `sys_menu_set`: Struct do sys_menu_set (%SysMenuSet{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_menu_set \ %__MODULE__{}, attrs) do
    sys_menu_set
    |> cast(attrs, [:set_name, :module, :title, :deletable])
  end
end
