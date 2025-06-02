defmodule DeeperHub.Schema.SysEmbededData do
  @moduledoc """
  Schema para representação de sys_embeded_datas no sistema

  Este schema armazena as informações de um sys_embeded_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_embeded_data" do
    field :url, :string  # varchar(255)
    field :data, :string  # text
    field :added, :integer  # int(11)
    field :theme, :string  # varchar(10)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_embeded_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    url: String.t() | nil,
    data: String.t() | nil,
    added: integer() | nil,
    theme: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_embeded_data.

  ## Parâmetros 
    - `sys_embeded_data`: Struct do sys_embeded_data (pode ser %SysEmbededData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_embeded_data \ %__MODULE__{}, attrs) do
    sys_embeded_data
    |> cast(attrs, [:url, :data, :added, :theme])
  end

  @doc """
  Changeset para atualização de um sys_embeded_data existente.

  ## Parâmetros 
    - `sys_embeded_data`: Struct do sys_embeded_data (%SysEmbededData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_embeded_data \ %__MODULE__{}, attrs) do
    sys_embeded_data
    |> cast(attrs, [:url, :data, :added, :theme])
  end
end
