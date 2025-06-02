defmodule DeeperHub.Schema.BxMassmailerSegment do
  @moduledoc """
  Schema para representação de bx_massmailer_segments no sistema

  Este schema armazena as informações de um bx_massmailer_segment.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_massmailer_segments" do
    field :title, :string  # varchar(255)
    field :info, :string  # text
    field :email_list, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_massmailer_segment no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    title: String.t() | nil,
    info: String.t() | nil,
    email_list: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_massmailer_segment.

  ## Parâmetros 
    - `bx_massmailer_segment`: Struct do bx_massmailer_segment (pode ser %BxMassmailerSegment{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_massmailer_segment \ %__MODULE__{}, attrs) do
    bx_massmailer_segment
    |> cast(attrs, [:title, :info, :email_list])
  end

  @doc """
  Changeset para atualização de um bx_massmailer_segment existente.

  ## Parâmetros 
    - `bx_massmailer_segment`: Struct do bx_massmailer_segment (%BxMassmailerSegment{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_massmailer_segment \ %__MODULE__{}, attrs) do
    bx_massmailer_segment
    |> cast(attrs, [:title, :info, :email_list])
  end
end
