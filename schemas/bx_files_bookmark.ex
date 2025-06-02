defmodule DeeperHub.Schema.BxFilesBookmark do
  @moduledoc """
  Schema para representação de bx_files_bookmarks no sistema

  Este schema armazena as informações de um bx_files_bookmark.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_files_bookmarks" do
    field :object_id, :integer, default: 0  # int(11)
    field :profile_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_files_bookmark no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    profile_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_files_bookmark.

  ## Parâmetros 
    - `bx_files_bookmark`: Struct do bx_files_bookmark (pode ser %BxFilesBookmark{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_files_bookmark \ %__MODULE__{}, attrs) do
    bx_files_bookmark
    |> cast(attrs, [:object_id, :profile_id])
  end

  @doc """
  Changeset para atualização de um bx_files_bookmark existente.

  ## Parâmetros 
    - `bx_files_bookmark`: Struct do bx_files_bookmark (%BxFilesBookmark{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_files_bookmark \ %__MODULE__{}, attrs) do
    bx_files_bookmark
    |> cast(attrs, [:object_id, :profile_id])
  end
end
