defmodule DeeperHub.Core.ConfigManager.Schema.SettingTable do
  @moduledoc """
  Definição da tabela Mnesia para configurações do sistema.
  """

  use Memento.Table,
    attributes: [
      :id,          # ID único da configuração
      :key,         # Chave da configuração (ex: "app.timeout")
      :value,       # Valor como string ou binário
      :scope,       # Escopo (ex: "global", "tenant:123")
      :data_type,   # Tipo de dado (:string, :integer, :float, :boolean, :list, :map)
      :is_sensitive,# Indica se é um dado sensível
      :description, # Descrição da configuração
      :created_by,  # Quem criou a configuração
      :deleted_at,  # Quando foi excluída (nil se ativa)
      :deleted_by,  # Quem excluiu a configuração
      :inserted_at, # Data de criação
      :updated_at   # Data de atualização
    ],
    index: [:key, :scope],
    type: :ordered_set
end

defmodule DeeperHub.Core.ConfigManager.Schema.Setting do
  @moduledoc """
  Schema para as configurações do sistema.

  Este schema define a estrutura das configurações armazenadas no banco de dados Mnesia.
  """

  alias DeeperHub.Core.ConfigManager.Schema.SettingTable

  # Define explicitamente os atributos da estrutura em vez de usar Memento.Table.attributes
  defstruct [
    :id,
    :key,
    :value,
    :scope,
    :data_type,
    :is_sensitive,
    :description,
    :created_by,
    :deleted_at,
    :deleted_by,
    :inserted_at,
    :updated_at
  ]

  @data_types [:string, :integer, :float, :boolean, :list, :map]

  @doc """
  Cria um novo registro de configuração.
  """
  def new(attrs) do
    id = attrs[:id] || UUID.uuid4()
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()

    # Valores padrão
    defaults = %{
      id: id,
      scope: "global",
      is_sensitive: false,
      description: "",
      created_by: "system",
      deleted_at: nil,
      deleted_by: nil,
      inserted_at: timestamp,
      updated_at: timestamp
    }

    # Mescla os atributos fornecidos com os padrões
    attrs = Map.merge(defaults, Map.new(attrs))

    # Valida os dados
    validate(attrs)
  end

  @doc """
  Valida os dados de uma configuração.
  """
  def validate(attrs) do
    with :ok <- validate_required(attrs, [:key, :value, :data_type]),
         :ok <- validate_data_type(attrs.data_type),
         :ok <- validate_key_length(attrs.key) do
      # Serializa o valor com base no tipo de dado
      attrs = prepare_value_based_on_type(attrs)
      {:ok, struct(SettingTable, attrs)}
    end
  end

  defp validate_required(attrs, fields) do
    missing = Enum.filter(fields, fn field ->
      is_nil(Map.get(attrs, field))
    end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, "Campos obrigatórios ausentes: #{Enum.join(missing, ", ")}"}
    end
  end

  defp validate_data_type(data_type) when data_type in @data_types, do: :ok
  defp validate_data_type(_), do: {:error, "Tipo de dado inválido"}

  defp validate_key_length(key) when is_binary(key) do
    if String.length(key) >= 1 and String.length(key) <= 255 do
      :ok
    else
      {:error, "A chave deve ter entre 1 e 255 caracteres"}
    end
  end

  @doc """
  Prepara o valor com base no tipo de dado.
  """
  def prepare_value_based_on_type(attrs) do
    value = attrs.value
    data_type = attrs.data_type

    case data_type do
      :string -> attrs
      :integer -> attrs
      :float -> attrs
      :boolean -> attrs
      :list -> Map.put(attrs, :value, :erlang.term_to_binary(value))
      :map -> Map.put(attrs, :value, :erlang.term_to_binary(value))
    end
  end

  @doc """
  Serializa o valor para armazenamento.
  """
  def serialize_value(value, :string) when is_binary(value), do: value
  def serialize_value(value, :integer) when is_integer(value), do: Integer.to_string(value)
  def serialize_value(value, :float) when is_float(value), do: Float.to_string(value)
  def serialize_value(value, :boolean) when is_boolean(value), do: if(value, do: "true", else: "false")
  def serialize_value(value, :list) when is_list(value), do: :erlang.term_to_binary(value)
  def serialize_value(value, :map) when is_map(value), do: :erlang.term_to_binary(value)
  def serialize_value(nil, _), do: nil
  def serialize_value(value, type) do
    # Tenta converter para o tipo esperado se possível
    case type do
      :string -> to_string(value)
      :integer ->
        case Integer.parse(to_string(value)) do
          {int, ""} -> Integer.to_string(int)
          _ -> to_string(value)
        end
      :float ->
        case Float.parse(to_string(value)) do
          {float, ""} -> Float.to_string(float)
          _ -> to_string(value)
        end
      :boolean ->
        str = String.downcase(to_string(value))
        if str in ["true", "1", "yes"], do: "true", else: "false"
      :list -> :erlang.term_to_binary(value)
      :map -> :erlang.term_to_binary(value)
    end
  end

  @doc """
  Deserializa um valor do banco de dados para o tipo correto.
  """
  def deserialize_value(nil, _), do: nil
  def deserialize_value(value, :string) when is_binary(value), do: value
  def deserialize_value(value, :integer) when is_binary(value) do
    case Integer.parse(value) do
      {int, ""} -> int
      _ -> value
    end
  end
  def deserialize_value(value, :float) when is_binary(value) do
    case Float.parse(value) do
      {float, ""} -> float
      _ -> value
    end
  end
  def deserialize_value(value, :boolean) when is_binary(value) do
    String.downcase(value) in ["true", "1", "yes"]
  end
  def deserialize_value(value, type) when type in [:list, :map] and is_binary(value) do
    try do
      :erlang.binary_to_term(value)
    rescue
      _ -> value
    end
  end
  def deserialize_value(value, _), do: value
end
