defmodule DeeperHub.Schema.BxWorkspacesReport do
  @moduledoc """
  Schema para representação de bx_workspaces_reports no sistema

  Este schema armazena as informações de um bx_workspaces_report.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_workspaces_reports" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_workspaces_report no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_workspaces_report.

  ## Parâmetros 
    - `bx_workspaces_report`: Struct do bx_workspaces_report (pode ser %BxWorkspacesReport{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_workspaces_report \ %__MODULE__{}, attrs) do
    bx_workspaces_report
    |> cast(attrs, [:object_id, :count])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um bx_workspaces_report existente.

  ## Parâmetros 
    - `bx_workspaces_report`: Struct do bx_workspaces_report (%BxWorkspacesReport{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_workspaces_report \ %__MODULE__{}, attrs) do
    bx_workspaces_report
    |> cast(attrs, [:object_id, :count])
    |> unique_constraint(:object_id)
  end
end
