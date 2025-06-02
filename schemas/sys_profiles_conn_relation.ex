defmodule DeeperHub.Schema.SysProfilesConnRelation do
  @moduledoc """
  Schema para representação de sys_profiles_conn_relations no sistema

  Este schema armazena as informações de um sys_profiles_conn_relation.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_profiles_conn_relations" do
    field :initiator, :integer, default: 0  # int(11)
    field :content, :integer, default: 0  # int(11)
    field :relation, :integer, default: 0  # int(11)
    field :mutual, :integer, default: 0  # tinyint(4)
    field :added, :integer, default: 0  # int(11) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_profiles_conn_relation no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    initiator: integer() | nil,
    content: integer() | nil,
    relation: integer() | nil,
    mutual: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_profiles_conn_relation.

  ## Parâmetros 
    - `sys_profiles_conn_relation`: Struct do sys_profiles_conn_relation (pode ser %SysProfilesConnRelation{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_profiles_conn_relation \ %__MODULE__{}, attrs) do
    sys_profiles_conn_relation
    |> cast(attrs, [:initiator, :content, :relation, :mutual, :added])
  end

  @doc """
  Changeset para atualização de um sys_profiles_conn_relation existente.

  ## Parâmetros 
    - `sys_profiles_conn_relation`: Struct do sys_profiles_conn_relation (%SysProfilesConnRelation{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_profiles_conn_relation \ %__MODULE__{}, attrs) do
    sys_profiles_conn_relation
    |> cast(attrs, [:initiator, :content, :relation, :mutual, :added])
  end
end
