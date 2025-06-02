defmodule DeeperHub.Schema.BxForumCategorie do
  @moduledoc """
  Schema para representação de bx_forum_categories no sistema

  Este schema armazena as informações de um bx_forum_categorie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_forum_categories" do
    field :category, :integer, default: 0  # int(11)
    field :visible_for_levels, :integer, default: 2147483647  # int(11)
    field :icon, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_forum_categorie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    category: integer() | nil,
    visible_for_levels: integer() | nil,
    icon: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_forum_categorie.

  ## Parâmetros 
    - `bx_forum_categorie`: Struct do bx_forum_categorie (pode ser %BxForumCategorie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_forum_categorie \ %__MODULE__{}, attrs) do
    bx_forum_categorie
    |> cast(attrs, [:category, :visible_for_levels, :icon])
    |> validate_required([:icon])
  end

  @doc """
  Changeset para atualização de um bx_forum_categorie existente.

  ## Parâmetros 
    - `bx_forum_categorie`: Struct do bx_forum_categorie (%BxForumCategorie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_forum_categorie \ %__MODULE__{}, attrs) do
    bx_forum_categorie
    |> cast(attrs, [:category, :visible_for_levels, :icon])
  end
end
