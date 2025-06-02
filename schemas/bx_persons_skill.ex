defmodule DeeperHub.Schema.BxPersonsSkill do
  @moduledoc """
  Schema para representação de bx_persons_skills no sistema

  Este schema armazena as informações de um bx_persons_skill.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "bx_persons_skills" do
    field :skill_id, :integer  # int(11)
    field :skill_name, :string  # varchar(500)
    field :content_id, :integer  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um bx_persons_skill no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    skill_id: integer() | nil,
    skill_name: String.t() | nil,
    content_id: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo bx_persons_skill.

  ## Parâmetros 
    - `bx_persons_skill`: Struct do bx_persons_skill (pode ser %BxPersonsSkill{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(bx_persons_skill \ %__MODULE__{}, attrs) do
    bx_persons_skill
    |> cast(attrs, [:skill_id, :skill_name, :content_id])
    |> validate_required([:skill_id, :content_id])
  end

  @doc """
  Changeset para atualização de um bx_persons_skill existente.

  ## Parâmetros 
    - `bx_persons_skill`: Struct do bx_persons_skill (%BxPersonsSkill{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(bx_persons_skill \ %__MODULE__{}, attrs) do
    bx_persons_skill
    |> cast(attrs, [:skill_id, :skill_name, :content_id])
  end
end
