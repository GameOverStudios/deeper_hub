defmodule DeeperHub.Schema.SysOptionsCategorie do
  @moduledoc """
  Schema para representação de sys_options_categories no sistema

  Este schema armazena as informações de um sys_options_categorie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_options_categories" do
    field :type_id, :integer, default: 0  # int(11) unsigned
    field :name, :string, default: ""  # varchar(64)
    field :caption, :string, default: ""  # varchar(64)
    field :hidden, :boolean, default: false  # tinyint(1)
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_options_categorie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    type_id: integer() | nil,
    name: String.t() | nil,
    caption: String.t() | nil,
    hidden: boolean() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_options_categorie.

  ## Parâmetros 
    - `sys_options_categorie`: Struct do sys_options_categorie (pode ser %SysOptionsCategorie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_options_categorie \ %__MODULE__{}, attrs) do
    sys_options_categorie
    |> cast(attrs, [:type_id, :name, :caption, :hidden, :order])
    |> validate_required([:name, :caption])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um sys_options_categorie existente.

  ## Parâmetros 
    - `sys_options_categorie`: Struct do sys_options_categorie (%SysOptionsCategorie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_options_categorie \ %__MODULE__{}, attrs) do
    sys_options_categorie
    |> cast(attrs, [:type_id, :name, :caption, :hidden, :order])
    |> unique_constraint(:name)
  end
end
