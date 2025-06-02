defmodule DeeperHub.Schema.BxQuoteofdayInternal do
  @moduledoc """
  Schema para representação de bx_quoteofday_internals no sistema

  Este schema armazena as informações de um bx_quoteofday_internal.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_quoteofday_internal" do
    field :text, :string  # text
    field :added, :integer  # int(11)
    field :status, Ecto.Enum, values: [:active, :hidden], default: "active"  # enum('active','hidden')

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_quoteofday_internal no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    text: String.t() | nil,
    added: integer() | nil,
    status: :active | :hidden | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_quoteofday_internal.

  ## Parâmetros 
    - `bx_quoteofday_internal`: Struct do bx_quoteofday_internal (pode ser %BxQuoteofdayInternal{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_quoteofday_internal \ %__MODULE__{}, attrs) do
    bx_quoteofday_internal
    |> cast(attrs, [:text, :added, :status])
    |> validate_required([:text])
  end

  @doc """
  Changeset para atualização de um bx_quoteofday_internal existente.

  ## Parâmetros 
    - `bx_quoteofday_internal`: Struct do bx_quoteofday_internal (%BxQuoteofdayInternal{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_quoteofday_internal \ %__MODULE__{}, attrs) do
    bx_quoteofday_internal
    |> cast(attrs, [:text, :added, :status])
  end
end
