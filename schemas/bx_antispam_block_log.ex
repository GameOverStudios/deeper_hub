defmodule DeeperHub.Schema.BxAntispamBlockLog do
  @moduledoc """
  Schema para representação de bx_antispam_block_logs no sistema

  Este schema armazena as informações de um bx_antispam_block_log.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_antispam_block_log" do
    field :ip, :integer  # int(10) unsigned
    field :profile_id, :integer  # int(10) unsigned
    field :type, :string  # varchar(32)
    field :extra, :string  # text
    field :added, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_antispam_block_log no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    ip: integer() | nil,
    profile_id: integer() | nil,
    type: String.t() | nil,
    extra: String.t() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_antispam_block_log.

  ## Parâmetros 
    - `bx_antispam_block_log`: Struct do bx_antispam_block_log (pode ser %BxAntispamBlockLog{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_antispam_block_log \ %__MODULE__{}, attrs) do
    bx_antispam_block_log
    |> cast(attrs, [:ip, :profile_id, :type, :extra, :added])
    |> validate_required([:ip, :profile_id, :type, :extra, :added])
  end

  @doc """
  Changeset para atualização de um bx_antispam_block_log existente.

  ## Parâmetros 
    - `bx_antispam_block_log`: Struct do bx_antispam_block_log (%BxAntispamBlockLog{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_antispam_block_log \ %__MODULE__{}, attrs) do
    bx_antispam_block_log
    |> cast(attrs, [:ip, :profile_id, :type, :extra, :added])
  end
end
