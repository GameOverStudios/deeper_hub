defmodule DeeperHub.Schema.SysCmtsMetaMention do
  @moduledoc """
  Schema para representação de sys_cmts_meta_mentions no sistema

  Este schema armazena as informações de um sys_cmts_meta_mention.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_meta_mentions" do
    field :object_id, :integer  # int(10) unsigned
    field :profile_id, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_meta_mention no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    profile_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_meta_mention.

  ## Parâmetros 
    - `sys_cmts_meta_mention`: Struct do sys_cmts_meta_mention (pode ser %SysCmtsMetaMention{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_meta_mention \ %__MODULE__{}, attrs) do
    sys_cmts_meta_mention
    |> cast(attrs, [:object_id, :profile_id])
    |> validate_required([:object_id, :profile_id])
  end

  @doc """
  Changeset para atualização de um sys_cmts_meta_mention existente.

  ## Parâmetros 
    - `sys_cmts_meta_mention`: Struct do sys_cmts_meta_mention (%SysCmtsMetaMention{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_meta_mention \ %__MODULE__{}, attrs) do
    sys_cmts_meta_mention
    |> cast(attrs, [:object_id, :profile_id])
  end
end
