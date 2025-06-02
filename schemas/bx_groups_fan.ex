defmodule DeeperHub.Schema.BxGroupsFan do
  @moduledoc """
  Schema para representação de bx_groups_fans no sistema

  Este schema armazena as informações de um bx_groups_fan.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_groups_fans" do
    field :initiator, :integer  # int(11)
    field :content, :integer  # int(11)
    field :mutual, :integer  # tinyint(4)
    field :added, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_groups_fan no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    initiator: integer() | nil,
    content: integer() | nil,
    mutual: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_groups_fan.

  ## Parâmetros 
    - `bx_groups_fan`: Struct do bx_groups_fan (pode ser %BxGroupsFan{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_groups_fan \ %__MODULE__{}, attrs) do
    bx_groups_fan
    |> cast(attrs, [:initiator, :content, :mutual, :added])
    |> validate_required([:initiator, :content, :mutual, :added])
  end

  @doc """
  Changeset para atualização de um bx_groups_fan existente.

  ## Parâmetros 
    - `bx_groups_fan`: Struct do bx_groups_fan (%BxGroupsFan{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_groups_fan \ %__MODULE__{}, attrs) do
    bx_groups_fan
    |> cast(attrs, [:initiator, :content, :mutual, :added])
  end
end
