defmodule DeeperHub.Schema.SysProfilesConnSubscription do
  @moduledoc """
  Schema para representação de sys_profiles_conn_subscriptions no sistema

  Este schema armazena as informações de um sys_profiles_conn_subscription.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_profiles_conn_subscriptions" do
    field :initiator, :integer  # int(11)
    field :content, :integer  # int(11)
    field :added, :integer  # int(10) unsigned

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_profiles_conn_subscription no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    initiator: integer() | nil,
    content: integer() | nil,
    added: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_profiles_conn_subscription.

  ## Parâmetros 
    - `sys_profiles_conn_subscription`: Struct do sys_profiles_conn_subscription (pode ser %SysProfilesConnSubscription{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_profiles_conn_subscription \ %__MODULE__{}, attrs) do
    sys_profiles_conn_subscription
    |> cast(attrs, [:initiator, :content, :added])
    |> validate_required([:initiator, :content, :added])
  end

  @doc """
  Changeset para atualização de um sys_profiles_conn_subscription existente.

  ## Parâmetros 
    - `sys_profiles_conn_subscription`: Struct do sys_profiles_conn_subscription (%SysProfilesConnSubscription{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_profiles_conn_subscription \ %__MODULE__{}, attrs) do
    sys_profiles_conn_subscription
    |> cast(attrs, [:initiator, :content, :added])
  end
end
