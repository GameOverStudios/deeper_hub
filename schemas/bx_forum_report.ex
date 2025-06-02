defmodule DeeperHub.Schema.BxForumReport do
  @moduledoc """
  Schema para representação de bx_forum_reports no sistema

  Este schema armazena as informações de um bx_forum_report.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_forum_reports" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_forum_report no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_forum_report.

  ## Parâmetros 
    - `bx_forum_report`: Struct do bx_forum_report (pode ser %BxForumReport{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_forum_report \ %__MODULE__{}, attrs) do
    bx_forum_report
    |> cast(attrs, [:object_id, :count])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_forum_report existente.

  ## Parâmetros 
    - `bx_forum_report`: Struct do bx_forum_report (%BxForumReport{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_forum_report \ %__MODULE__{}, attrs) do
    bx_forum_report
    |> cast(attrs, [:object_id, :count])
    |> unique_constraint(:object_id)
  end
end
