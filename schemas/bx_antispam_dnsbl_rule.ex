defmodule DeeperHub.Schema.BxAntispamDnsblRule do
  @moduledoc """
  Schema para representação de bx_antispam_dnsbl_rules no sistema

  Este schema armazena as informações de um bx_antispam_dnsbl_rule.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_antispam_dnsbl_rules" do
    field :chain, Ecto.Enum, values: [:spammers, :whitelist, :uridns]  # enum('spammers','whitelist','uridns')
    field :zonedomain, :string  # varchar(255)
    field :postvresp, :string  # varchar(32)
    field :url, :string  # varchar(255)
    field :recheck, :string  # varchar(255)
    field :comment, :string  # varchar(255)
    field :added, :integer  # int(11)
    field :active, :integer  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_antispam_dnsbl_rule no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    chain: :spammers | :whitelist | :uridns | nil,
    zonedomain: String.t() | nil,
    postvresp: String.t() | nil,
    url: String.t() | nil,
    recheck: String.t() | nil,
    comment: String.t() | nil,
    added: integer() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_antispam_dnsbl_rule.

  ## Parâmetros 
    - `bx_antispam_dnsbl_rule`: Struct do bx_antispam_dnsbl_rule (pode ser %BxAntispamDnsblRule{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_antispam_dnsbl_rule \ %__MODULE__{}, attrs) do
    bx_antispam_dnsbl_rule
    |> cast(attrs, [:chain, :zonedomain, :postvresp, :url, :recheck, :comment, :added, :active])
    |> validate_required([:chain, :zonedomain, :postvresp, :url, :recheck, :comment, :added, :active])
  end

  @doc """
  Changeset para atualização de um bx_antispam_dnsbl_rule existente.

  ## Parâmetros 
    - `bx_antispam_dnsbl_rule`: Struct do bx_antispam_dnsbl_rule (%BxAntispamDnsblRule{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_antispam_dnsbl_rule \ %__MODULE__{}, attrs) do
    bx_antispam_dnsbl_rule
    |> cast(attrs, [:chain, :zonedomain, :postvresp, :url, :recheck, :comment, :added, :active])
  end
end
