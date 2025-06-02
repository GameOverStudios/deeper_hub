defmodule DeeperHub.Schema.BxSpacesFavoritesList do
  @moduledoc """
  Schema para representação de bx_spaces_favorites_lists no sistema

  Este schema armazena as informações de um bx_spaces_favorites_list.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_spaces_favorites_lists" do
    field :title, :string  # varchar(255)
    field :author_id, :integer, default: 0  # int(11)
    field :date, :integer, default: 0  # int(11)
    field :allow_view_favorite_list_to, :string, default: "3"  # varchar(16)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_spaces_favorites_list no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    author_id: integer() | nil,
    date: integer() | nil,
    allow_view_favorite_list_to: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_spaces_favorites_list.

  ## Parâmetros 
    - `bx_spaces_favorites_list`: Struct do bx_spaces_favorites_list (pode ser %BxSpacesFavoritesList{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_spaces_favorites_list \ %__MODULE__{}, attrs) do
    bx_spaces_favorites_list
    |> cast(attrs, [:title, :author_id, :date, :allow_view_favorite_list_to])
    |> validate_required([:title])
  end

  @doc """
  Changeset para atualização de um bx_spaces_favorites_list existente.

  ## Parâmetros 
    - `bx_spaces_favorites_list`: Struct do bx_spaces_favorites_list (%BxSpacesFavoritesList{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_spaces_favorites_list \ %__MODULE__{}, attrs) do
    bx_spaces_favorites_list
    |> cast(attrs, [:title, :author_id, :date, :allow_view_favorite_list_to])
  end
end
