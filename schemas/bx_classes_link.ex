defmodule DeeperHub.Schema.BxClassesLink do
  @moduledoc """
  Schema para representação de bx_classes_links no sistema

  Este schema armazena as informações de um bx_classes_link.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_classes_links" do
    field :profile_id, :integer  # int(10) unsigned
    field :media_id, :integer, default: 0  # int(11)
    field :url, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :text, :string  # text
    field :added, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_classes_link no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    media_id: integer() | nil,
    url: String.t() | nil,
    title: String.t() | nil,
    text: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_classes_link.

  ## Parâmetros 
    - `bx_classes_link`: Struct do bx_classes_link (pode ser %BxClassesLink{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_classes_link \ %__MODULE__{}, attrs) do
    bx_classes_link
    |> cast(attrs, [:profile_id, :media_id, :url, :title, :text, :added])
    |> validate_required([:profile_id, :url, :title, :text, :added])
  end

  @doc """
  Changeset para atualização de um bx_classes_link existente.

  ## Parâmetros 
    - `bx_classes_link`: Struct do bx_classes_link (%BxClassesLink{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_classes_link \ %__MODULE__{}, attrs) do
    bx_classes_link
    |> cast(attrs, [:profile_id, :media_id, :url, :title, :text, :added])
  end
end
