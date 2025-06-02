defmodule DeeperHub.Schema.SysRewriteRule do
  @moduledoc """
  Schema para representação de sys_rewrite_rules no sistema

  Este schema armazena as informações de um sys_rewrite_rule.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_rewrite_rules" do
    field :preg, :string  # varchar(255)
    field :service, :string  # varchar(255)
    field :active, :integer, default: 1  # tinyint(4)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_rewrite_rule no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    preg: String.t() | nil,
    service: String.t() | nil,
    active: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_rewrite_rule.

  ## Parâmetros 
    - `sys_rewrite_rule`: Struct do sys_rewrite_rule (pode ser %SysRewriteRule{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_rewrite_rule \ %__MODULE__{}, attrs) do
    sys_rewrite_rule
    |> cast(attrs, [:preg, :service, :active])
    |> validate_required([:preg, :service])
  end

  @doc """
  Changeset para atualização de um sys_rewrite_rule existente.

  ## Parâmetros 
    - `sys_rewrite_rule`: Struct do sys_rewrite_rule (%SysRewriteRule{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_rewrite_rule \ %__MODULE__{}, attrs) do
    sys_rewrite_rule
    |> cast(attrs, [:preg, :service, :active])
  end
end
