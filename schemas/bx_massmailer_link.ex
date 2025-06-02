defmodule DeeperHub.Schema.BxMassmailerLink do
  @moduledoc """
  Schema para representação de bx_massmailer_links no sistema

  Este schema armazena as informações de um bx_massmailer_link.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_massmailer_links" do
    field :letter_hash, :string  # varchar(35)
    field :hash, :string  # varchar(35)
    field :link, :string  # varchar(255)
    field :title, :string  # varchar(255)
    field :campaign_id, :integer  # int(11)
    field :date_click, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_massmailer_link no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    letter_hash: String.t() | nil,
    hash: String.t() | nil,
    link: String.t() | nil,
    title: String.t() | nil,
    campaign_id: integer() | nil,
    date_click: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_massmailer_link.

  ## Parâmetros 
    - `bx_massmailer_link`: Struct do bx_massmailer_link (pode ser %BxMassmailerLink{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_massmailer_link \ %__MODULE__{}, attrs) do
    bx_massmailer_link
    |> cast(attrs, [:letter_hash, :hash, :link, :title, :campaign_id, :date_click])
  end

  @doc """
  Changeset para atualização de um bx_massmailer_link existente.

  ## Parâmetros 
    - `bx_massmailer_link`: Struct do bx_massmailer_link (%BxMassmailerLink{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_massmailer_link \ %__MODULE__{}, attrs) do
    bx_massmailer_link
    |> cast(attrs, [:letter_hash, :hash, :link, :title, :campaign_id, :date_click])
  end
end
