defmodule DeeperHub.Schema.SysCmtsId do
  @moduledoc """
  Schema para representação de sys_cmts_ids no sistema

  Este schema armazena as informações de um sys_cmts_id.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_ids" do
    field :system_id, :integer, default: 0  # int(11)
    field :cmt_id, :integer, default: 0  # int(11)
    field :author_id, :integer, default: 0  # int(11)
    field :rate, :float, default: 0  # float
    field :votes, :integer, default: 0  # int(11)
    field :rrate, :float, default: 0  # float
    field :rvotes, :integer, default: 0  # int(11)
    field :score, :integer, default: 0  # int(11)
    field :sc_up, :integer, default: 0  # int(11)
    field :sc_down, :integer, default: 0  # int(11)
    field :reports, :integer, default: 0  # int(11)
    field :status_admin, Ecto.Enum, values: [:active, :hidden, :pending], default: "active"  # enum('active','hidden','pending')

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_id no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    system_id: integer() | nil,
    cmt_id: integer() | nil,
    author_id: integer() | nil,
    rate: float() | nil,
    votes: integer() | nil,
    rrate: float() | nil,
    rvotes: integer() | nil,
    score: integer() | nil,
    sc_up: integer() | nil,
    sc_down: integer() | nil,
    reports: integer() | nil,
    status_admin: :active | :hidden | :pending | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_id.

  ## Parâmetros 
    - `sys_cmts_id`: Struct do sys_cmts_id (pode ser %SysCmtsId{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_id \ %__MODULE__{}, attrs) do
    sys_cmts_id
    |> cast(attrs, [:system_id, :cmt_id, :author_id, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :reports, :status_admin])
  end

  @doc """
  Changeset para atualização de um sys_cmts_id existente.

  ## Parâmetros 
    - `sys_cmts_id`: Struct do sys_cmts_id (%SysCmtsId{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_id \ %__MODULE__{}, attrs) do
    sys_cmts_id
    |> cast(attrs, [:system_id, :cmt_id, :author_id, :rate, :votes, :rrate, :rvotes, :score, :sc_up, :sc_down, :reports, :status_admin])
  end
end
