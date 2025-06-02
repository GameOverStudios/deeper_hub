defmodule DeeperHub.Schema.SysCmtsScore do
  @moduledoc """
  Schema para representação de sys_cmts_scores no sistema

  Este schema armazena as informações de um sys_cmts_score.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_scores" do
    field :object_id, :integer, default: 0  # int(11)
    field :count_up, :integer, default: 0  # int(11)
    field :count_down, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_score no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count_up: integer() | nil,
    count_down: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_score.

  ## Parâmetros 
    - `sys_cmts_score`: Struct do sys_cmts_score (pode ser %SysCmtsScore{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_score \ %__MODULE__{}, attrs) do
    sys_cmts_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um sys_cmts_score existente.

  ## Parâmetros 
    - `sys_cmts_score`: Struct do sys_cmts_score (%SysCmtsScore{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_score \ %__MODULE__{}, attrs) do
    sys_cmts_score
    |> cast(attrs, [:object_id, :count_up, :count_down])
    |> unique_constraint(:object_id)
  end
end
