defmodule DeeperHub.Schema.BxAntispamIpTable do
  @moduledoc """
  Schema para representação de bx_antispam_ip_tables no sistema

  Este schema armazena as informações de um bx_antispam_ip_table.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_antispam_ip_table" do
    field :ID, :integer  # int(11)
    field :From, :integer  # int(10) unsigned
    field :To, :integer  # int(10) unsigned
    field :Type, Ecto.Enum, values: [:allow, :deny], default: "deny"  # enum('allow','deny')
    field :LastDT, :integer  # int(11) unsigned
    field :Desc, :string  # varchar(128)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_antispam_ip_table no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ID: integer() | nil,
    From: integer() | nil,
    To: integer() | nil,
    Type: :allow | :deny | nil,
    LastDT: integer() | nil,
    Desc: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_antispam_ip_table.

  ## Parâmetros 
    - `bx_antispam_ip_table`: Struct do bx_antispam_ip_table (pode ser %BxAntispamIpTable{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_antispam_ip_table \ %__MODULE__{}, attrs) do
    bx_antispam_ip_table
    |> cast(attrs, [:ID, :From, :To, :Type, :LastDT, :Desc])
    |> validate_required([:ID, :From, :To, :LastDT, :Desc])
  end

  @doc """
  Changeset para atualização de um bx_antispam_ip_table existente.

  ## Parâmetros 
    - `bx_antispam_ip_table`: Struct do bx_antispam_ip_table (%BxAntispamIpTable{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_antispam_ip_table \ %__MODULE__{}, attrs) do
    bx_antispam_ip_table
    |> cast(attrs, [:ID, :From, :To, :Type, :LastDT, :Desc])
  end
end
