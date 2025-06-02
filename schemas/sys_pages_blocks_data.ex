defmodule DeeperHub.Schema.SysPagesBlocksData do
  @moduledoc """
  Schema para representação de sys_pages_blocks_datas no sistema

  Este schema armazena as informações de um sys_pages_blocks_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_pages_blocks_data" do
    field :block_id, :integer, default: 0  # int(11)
    field :content_id, :integer, default: 0  # int(11)
    field :content_module, :string  # varchar(32)
    field :data, :string  # text

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_pages_blocks_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    block_id: integer() | nil,
    content_id: integer() | nil,
    content_module: String.t() | nil,
    data: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_pages_blocks_data.

  ## Parâmetros 
    - `sys_pages_blocks_data`: Struct do sys_pages_blocks_data (pode ser %SysPagesBlocksData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_pages_blocks_data \ %__MODULE__{}, attrs) do
    sys_pages_blocks_data
    |> cast(attrs, [:block_id, :content_id, :content_module, :data])
    |> validate_required([:content_module, :data])
  end

  @doc """
  Changeset para atualização de um sys_pages_blocks_data existente.

  ## Parâmetros 
    - `sys_pages_blocks_data`: Struct do sys_pages_blocks_data (%SysPagesBlocksData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_pages_blocks_data \ %__MODULE__{}, attrs) do
    sys_pages_blocks_data
    |> cast(attrs, [:block_id, :content_id, :content_module, :data])
  end
end
