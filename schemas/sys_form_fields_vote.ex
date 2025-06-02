defmodule DeeperHub.Schema.SysFormFieldsVote do
  @moduledoc """
  Schema para representação de sys_form_fields_votes no sistema

  Este schema armazena as informações de um sys_form_fields_vote.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_fields_votes" do
    field :object_id, :integer, default: 0  # int(11)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_fields_vote no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    count: integer() | nil,
    sum: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_fields_vote.

  ## Parâmetros 
    - `sys_form_fields_vote`: Struct do sys_form_fields_vote (pode ser %SysFormFieldsVote{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_fields_vote \ %__MODULE__{}, attrs) do
    sys_form_fields_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end

  @doc """
  Changeset para atualização de um sys_form_fields_vote existente.

  ## Parâmetros 
    - `sys_form_fields_vote`: Struct do sys_form_fields_vote (%SysFormFieldsVote{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_fields_vote \ %__MODULE__{}, attrs) do
    sys_form_fields_vote
    |> cast(attrs, [:object_id, :count, :sum])
    |> unique_constraint(:object_id)
  end
end
