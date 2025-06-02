defmodule DeeperHub.Schema.BxClassesPoll do
  @moduledoc """
  Schema para representação de bx_classes_polls no sistema

  Este schema armazena as informações de um bx_classes_poll.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_classes_polls" do
    field :author_id, :integer, default: 0  # int(11)
    field :content_id, :integer, default: 0  # int(11)
    field :text, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_classes_poll no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    author_id: integer() | nil,
    content_id: integer() | nil,
    text: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_classes_poll.

  ## Parâmetros 
    - `bx_classes_poll`: Struct do bx_classes_poll (pode ser %BxClassesPoll{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_classes_poll \ %__MODULE__{}, attrs) do
    bx_classes_poll
    |> cast(attrs, [:author_id, :content_id, :text])
    |> validate_required([:text])
  end

  @doc """
  Changeset para atualização de um bx_classes_poll existente.

  ## Parâmetros 
    - `bx_classes_poll`: Struct do bx_classes_poll (%BxClassesPoll{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_classes_poll \ %__MODULE__{}, attrs) do
    bx_classes_poll
    |> cast(attrs, [:author_id, :content_id, :text])
  end
end
