defmodule DeeperHub.Schema.SysRecommendationCriteria do
  @moduledoc """
  Schema para representação de sys_recommendation_criterias no sistema

  Este schema armazena as informações de um sys_recommendation_criteria.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_recommendation_criteria" do
    field :object_id, :integer, default: 0  # int(11)
    field :name, :string, default: ""  # varchar(64)
    field :source_type, Ecto.Enum, values: [:sql, :service]  # enum('sql','service')
    field :source, :string  # text
    field :params, :string  # text
    field :weight, :float, default: 0  # float
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_recommendation_criteria no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    name: String.t() | nil,
    source_type: :sql | :service | nil,
    source: String.t() | nil,
    params: String.t() | nil,
    weight: float() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_recommendation_criteria.

  ## Parâmetros 
    - `sys_recommendation_criteria`: Struct do sys_recommendation_criteria (pode ser %SysRecommendationCriteria{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_recommendation_criteria \ %__MODULE__{}, attrs) do
    sys_recommendation_criteria
    |> cast(attrs, [:object_id, :name, :source_type, :source, :params, :weight, :active])
    |> validate_required([:name, :source_type, :source, :params])
  end

  @doc """
  Changeset para atualização de um sys_recommendation_criteria existente.

  ## Parâmetros 
    - `sys_recommendation_criteria`: Struct do sys_recommendation_criteria (%SysRecommendationCriteria{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_recommendation_criteria \ %__MODULE__{}, attrs) do
    sys_recommendation_criteria
    |> cast(attrs, [:object_id, :name, :source_type, :source, :params, :weight, :active])
  end
end
