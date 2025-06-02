defmodule DeeperHub.Schema.SysFormInputsPrivacy do
  @moduledoc """
  Schema para representação de sys_form_inputs_privacys no sistema

  Este schema armazena as informações de um sys_form_inputs_privacy.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_form_inputs_privacy" do
    field :input_id, :integer, default: 0  # int(11) unsigned
    field :author_id, :integer, default: 0  # int(11) unsigned
    field :allow_view_to, :string, default: "3"  # varchar(16)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_form_inputs_privacy no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    input_id: integer() | nil,
    author_id: integer() | nil,
    allow_view_to: String.t() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_form_inputs_privacy.

  ## Parâmetros 
    - `sys_form_inputs_privacy`: Struct do sys_form_inputs_privacy (pode ser %SysFormInputsPrivacy{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_form_inputs_privacy \ %__MODULE__{}, attrs) do
    sys_form_inputs_privacy
    |> cast(attrs, [:input_id, :author_id, :allow_view_to])
  end

  @doc """
  Changeset para atualização de um sys_form_inputs_privacy existente.

  ## Parâmetros 
    - `sys_form_inputs_privacy`: Struct do sys_form_inputs_privacy (%SysFormInputsPrivacy{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_form_inputs_privacy \ %__MODULE__{}, attrs) do
    sys_form_inputs_privacy
    |> cast(attrs, [:input_id, :author_id, :allow_view_to])
  end
end
