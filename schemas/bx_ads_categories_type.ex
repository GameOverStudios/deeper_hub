defmodule DeeperHub.Schema.BxAdsCategoriesType do
  @moduledoc """
  Schema para representação de bx_ads_categories_types no sistema

  Este schema armazena as informações de um bx_ads_categories_type.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_ads_categories_types" do
    field :name, :string, default: ""  # varchar(64)
    field :title, :string, default: ""  # varchar(255)
    field :display_add, :string, default: ""  # varchar(255)
    field :display_edit, :string, default: ""  # varchar(255)
    field :display_view, :string, default: ""  # varchar(255)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_ads_categories_type no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    name: String.t() | nil,
    title: String.t() | nil,
    display_add: String.t() | nil,
    display_edit: String.t() | nil,
    display_view: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_ads_categories_type.

  ## Parâmetros 
    - `bx_ads_categories_type`: Struct do bx_ads_categories_type (pode ser %BxAdsCategoriesType{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_ads_categories_type \ %__MODULE__{}, attrs) do
    bx_ads_categories_type
    |> cast(attrs, [:name, :title, :display_add, :display_edit, :display_view])
    |> validate_required([:name, :title, :display_add, :display_edit, :display_view])
    |> unique_constraint(:name)
  end

  @doc """
  Changeset para atualização de um bx_ads_categories_type existente.

  ## Parâmetros 
    - `bx_ads_categories_type`: Struct do bx_ads_categories_type (%BxAdsCategoriesType{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_ads_categories_type \ %__MODULE__{}, attrs) do
    bx_ads_categories_type
    |> cast(attrs, [:name, :title, :display_add, :display_edit, :display_view])
    |> unique_constraint(:name)
  end
end
