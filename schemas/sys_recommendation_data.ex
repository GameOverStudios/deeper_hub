defmodule DeeperHub.Schema.SysRecommendationData do
  @moduledoc """
  Schema para representação de sys_recommendation_datas no sistema

  Este schema armazena as informações de um sys_recommendation_data.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_recommendation_data" do
    field :profile_id, :integer, default: 0  # int(11)
    field :object_id, :integer, default: 0  # int(11)
    field :item_id, :integer, default: 0  # int(11)
    field :item_type, :string, default: ""  # varchar(64)
    field :item_value, :integer, default: 0  # int(11)
    field :item_reducer, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_recommendation_data no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    profile_id: integer() | nil,
    object_id: integer() | nil,
    item_id: integer() | nil,
    item_type: String.t() | nil,
    item_value: integer() | nil,
    item_reducer: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_recommendation_data.

  ## Parâmetros 
    - `sys_recommendation_data`: Struct do sys_recommendation_data (pode ser %SysRecommendationData{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_recommendation_data \ %__MODULE__{}, attrs) do
    sys_recommendation_data
    |> cast(attrs, [:profile_id, :object_id, :item_id, :item_type, :item_value, :item_reducer])
    |> validate_required([:item_type])
  end

  @doc """
  Changeset para atualização de um sys_recommendation_data existente.

  ## Parâmetros 
    - `sys_recommendation_data`: Struct do sys_recommendation_data (%SysRecommendationData{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_recommendation_data \ %__MODULE__{}, attrs) do
    sys_recommendation_data
    |> cast(attrs, [:profile_id, :object_id, :item_id, :item_type, :item_value, :item_reducer])
  end
end
