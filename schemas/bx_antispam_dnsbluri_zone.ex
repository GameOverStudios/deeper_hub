defmodule DeeperHub.Schema.BxAntispamDnsbluriZone do
  @moduledoc """
  Schema para representação de bx_antispam_dnsbluri_zones no sistema

  Este schema armazena as informações de um bx_antispam_dnsbluri_zone.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_antispam_dnsbluri_zones" do
    field :level, :integer  # tinyint(4)
    field :zone, :string  # varchar(64)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_antispam_dnsbluri_zone no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    level: integer() | nil,
    zone: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_antispam_dnsbluri_zone.

  ## Parâmetros 
    - `bx_antispam_dnsbluri_zone`: Struct do bx_antispam_dnsbluri_zone (pode ser %BxAntispamDnsbluriZone{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_antispam_dnsbluri_zone \ %__MODULE__{}, attrs) do
    bx_antispam_dnsbluri_zone
    |> cast(attrs, [:level, :zone])
    |> validate_required([:level, :zone])
  end

  @doc """
  Changeset para atualização de um bx_antispam_dnsbluri_zone existente.

  ## Parâmetros 
    - `bx_antispam_dnsbluri_zone`: Struct do bx_antispam_dnsbluri_zone (%BxAntispamDnsbluriZone{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_antispam_dnsbluri_zone \ %__MODULE__{}, attrs) do
    bx_antispam_dnsbluri_zone
    |> cast(attrs, [:level, :zone])
  end
end
