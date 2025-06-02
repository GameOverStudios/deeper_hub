defmodule DeeperHub.Schema.SysCmtsReport do
  @moduledoc """
  Schema para representação de sys_cmts_reports no sistema

  Este schema armazena as informações de um sys_cmts_report.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_reports" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_report no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_report.

  ## Parâmetros 
    - `sys_cmts_report`: Struct do sys_cmts_report (pode ser %SysCmtsReport{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_report \ %__MODULE__{}, attrs) do
    sys_cmts_report
    |> cast(attrs, [:object_id, :count])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um sys_cmts_report existente.

  ## Parâmetros 
    - `sys_cmts_report`: Struct do sys_cmts_report (%SysCmtsReport{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_report \ %__MODULE__{}, attrs) do
    sys_cmts_report
    |> cast(attrs, [:object_id, :count])
    |> unique_constraint(:object_id)
  end
end
