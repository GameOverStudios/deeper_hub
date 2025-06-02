defmodule DeeperHub.Schema.BxPostsLinks2content do
  @moduledoc """
  Schema para representação de bx_posts_links2contents no sistema

  Este schema armazena as informações de um bx_posts_links2content.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_posts_links2content" do
    field :content_id, :integer, default: 0  # int(11)
    field :link_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_posts_links2content no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    content_id: integer() | nil,
    link_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_posts_links2content.

  ## Parâmetros 
    - `bx_posts_links2content`: Struct do bx_posts_links2content (pode ser %BxPostsLinks2content{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_posts_links2content \ %__MODULE__{}, attrs) do
    bx_posts_links2content
    |> cast(attrs, [:content_id, :link_id])
  end

  @doc """
  Changeset para atualização de um bx_posts_links2content existente.

  ## Parâmetros 
    - `bx_posts_links2content`: Struct do bx_posts_links2content (%BxPostsLinks2content{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_posts_links2content \ %__MODULE__{}, attrs) do
    bx_posts_links2content
    |> cast(attrs, [:content_id, :link_id])
  end
end
