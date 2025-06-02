defmodule DeeperHub.Schema.SysTranscoderFilter do
  @moduledoc """
  Schema para representação de sys_transcoder_filters no sistema

  Este schema armazena as informações de um sys_transcoder_filter.
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "sys_transcoder_filters" do
    field :transcoder_object, :string  # varchar(64)
    field :filter, :string  # varchar(32)
    field :filter_params, :string  # text
    field :order, :integer, default: 0  # int(11)

    timestamps()
  end

  @typedoc """
  Tipo que representa um sys_transcoder_filter no sistema
  """
  @type t :: %__MODULE__{
    id: Ecto.UUID.t(),
    transcoder_object: String.t() | nil,
    filter: String.t() | nil,
    filter_params: String.t() | nil,
    order: integer() | nil,
    inserted_at: NaiveDateTime.t() | nil,
    updated_at: NaiveDateTime.t() | nil
  }

  @doc """
  Changeset para criação de um novo sys_transcoder_filter.

  ## Parâmetros 
    - `sys_transcoder_filter`: Struct do sys_transcoder_filter (pode ser %SysTranscoderFilter{} ou %{})
    - `attrs`: Mapa com os atributos para criação

  ## Retorno 
    - Changeset válido ou inválido
  """
  def create_changeset(sys_transcoder_filter \ %__MODULE__{}, attrs) do
    sys_transcoder_filter
    |> cast(attrs, [:transcoder_object, :filter, :filter_params, :order])
    |> validate_required([:transcoder_object, :filter, :filter_params])
  end

  @doc """
  Changeset para atualização de um sys_transcoder_filter existente.

  ## Parâmetros 
    - `sys_transcoder_filter`: Struct do sys_transcoder_filter (%SysTranscoderFilter{})
    - `attrs`: Mapa com os atributos para atualização

  ## Retorno 
    - Changeset válido ou inválido
  """
  def update_changeset(sys_transcoder_filter \ %__MODULE__{}, attrs) do
    sys_transcoder_filter
    |> cast(attrs, [:transcoder_object, :filter, :filter_params, :order])
  end
end
