defmodule DeeperHub.Schema.SysCategories2object do
  @moduledoc """
  Schema para representação de sys_categories2objects no sistema

  Este schema armazena as informações de um sys_categories2object.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_categories2objects" do
    field :module, :string  # varchar(32)
    field :object_id, :integer  # int(11)
    field :category_id, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_categories2object no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    module: String.t() | nil,
    object_id: integer() | nil,
    category_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_categories2object.

  ## Parâmetros 
    - `sys_categories2object`: Struct do sys_categories2object (pode ser %SysCategories2object{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_categories2object \ %__MODULE__{}, attrs) do
    sys_categories2object
    |> cast(attrs, [:module, :object_id, :category_id])
    |> validate_required([:module, :object_id, :category_id])
  end

  @doc """
  Changeset para atualização de um sys_categories2object existente.

  ## Parâmetros 
    - `sys_categories2object`: Struct do sys_categories2object (%SysCategories2object{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_categories2object \ %__MODULE__{}, attrs) do
    sys_categories2object
    |> cast(attrs, [:module, :object_id, :category_id])
  end
end
