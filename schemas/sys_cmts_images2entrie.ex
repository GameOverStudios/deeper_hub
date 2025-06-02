defmodule DeeperHub.Schema.SysCmtsImages2entrie do
  @moduledoc """
  Schema para representação de sys_cmts_images2entries no sistema

  Este schema armazena as informações de um sys_cmts_images2entrie.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_cmts_images2entries" do
    field :system_id, :integer, default: 0  # int(11)
    field :cmt_id, :integer, default: 0  # int(11)
    field :image_id, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_cmts_images2entrie no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    system_id: integer() | nil,
    cmt_id: integer() | nil,
    image_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_cmts_images2entrie.

  ## Parâmetros 
    - `sys_cmts_images2entrie`: Struct do sys_cmts_images2entrie (pode ser %SysCmtsImages2entrie{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_cmts_images2entrie \ %__MODULE__{}, attrs) do
    sys_cmts_images2entrie
    |> cast(attrs, [:system_id, :cmt_id, :image_id])
  end

  @doc """
  Changeset para atualização de um sys_cmts_images2entrie existente.

  ## Parâmetros 
    - `sys_cmts_images2entrie`: Struct do sys_cmts_images2entrie (%SysCmtsImages2entrie{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_cmts_images2entrie \ %__MODULE__{}, attrs) do
    sys_cmts_images2entrie
    |> cast(attrs, [:system_id, :cmt_id, :image_id])
  end
end
