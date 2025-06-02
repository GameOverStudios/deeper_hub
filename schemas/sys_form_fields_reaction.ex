defmodule DeeperHub.Schema.SysFormFieldsReaction do
  @moduledoc """
  Schema para representação de sys_form_fields_reactions no sistema

  Este schema armazena as informações de um sys_form_fields_reaction.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_fields_reaction" do
    field :object_id, :integer, default: 0  # int(11)
    field :reaction, :string, default: ""  # varchar(32)
    field :count, :integer, default: 0  # int(11)
    field :sum, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_fields_reaction no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    object_id: integer() | nil,
    reaction: String.t() | nil,
    count: integer() | nil,
    sum: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_fields_reaction.

  ## Parâmetros 
    - `sys_form_fields_reaction`: Struct do sys_form_fields_reaction (pode ser %SysFormFieldsReaction{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_fields_reaction \ %__MODULE__{}, attrs) do
    sys_form_fields_reaction
    |> cast(attrs, [:object_id, :reaction, :count, :sum])
    |> validate_required([:reaction])
  end

  @doc """
  Changeset para atualização de um sys_form_fields_reaction existente.

  ## Parâmetros 
    - `sys_form_fields_reaction`: Struct do sys_form_fields_reaction (%SysFormFieldsReaction{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_fields_reaction \ %__MODULE__{}, attrs) do
    sys_form_fields_reaction
    |> cast(attrs, [:object_id, :reaction, :count, :sum])
  end
end
