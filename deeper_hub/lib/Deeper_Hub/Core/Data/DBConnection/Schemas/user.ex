defmodule Deeper_Hub.Core.Data.DBConnection.Schemas.User do
  @moduledoc """
  Schema para usuários do sistema.
  
  Este módulo define a estrutura de dados para usuários no banco de dados,
  incluindo validações e transformações.
  """
  
  # Sem aliases externos por enquanto
  
  @type t :: %__MODULE__{
    id: String.t(),
    username: String.t(),
    email: String.t(),
    password_hash: String.t(),
    is_active: boolean(),
    last_login: DateTime.t() | nil,
    inserted_at: DateTime.t(),
    updated_at: DateTime.t()
  }
  
  defstruct [
    :id,
    :username,
    :email,
    :password_hash,
    :is_active,
    :last_login,
    :inserted_at,
    :updated_at
  ]
  
  @table_name "users"
  @required_fields [:username, :email]
  # Campos opcionais para referência futura
  # @optional_fields [:password_hash, :is_active, :last_login]
  
  @doc """
  Cria uma nova struct de usuário a partir de um mapa de atributos.
  
  ## Parâmetros
  
    - `attrs`: Mapa com os atributos do usuário
  
  ## Retorno
  
    - `{:ok, user}` se os atributos forem válidos
    - `{:error, errors}` se houver erros de validação
  """
  @spec new(map()) :: {:ok, t()} | {:error, map()}
  def new(attrs) do
    # Valida os campos obrigatórios
    with :ok <- validate_required_fields(attrs),
         :ok <- validate_username(attrs),
         :ok <- validate_email(attrs) do
      
      # Cria a struct com valores padrão para campos opcionais
      user = %__MODULE__{
        id: attrs[:id] || UUID.uuid4(),
        username: attrs.username,
        email: attrs.email,
        password_hash: attrs[:password_hash] || "",
        is_active: attrs[:is_active] || true,
        last_login: attrs[:last_login],
        inserted_at: attrs[:inserted_at] || DateTime.utc_now(),
        updated_at: attrs[:updated_at] || DateTime.utc_now()
      }
      
      {:ok, user}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Valida e atualiza uma struct de usuário com novos atributos.
  
  ## Parâmetros
  
    - `user`: A struct de usuário existente
    - `attrs`: Mapa com os novos atributos
  
  ## Retorno
  
    - `{:ok, updated_user}` se os atributos forem válidos
    - `{:error, errors}` se houver erros de validação
  """
  @spec update(t(), map()) :: {:ok, t()} | {:error, map()}
  def update(user, attrs) do
    # Valida os campos que estão sendo atualizados
    with :ok <- validate_update_fields(attrs) do
      # Atualiza apenas os campos fornecidos
      updated_user = Enum.reduce(attrs, user, fn {key, value}, acc ->
        case key do
          :username -> 
            if validate_username(%{username: value}) == :ok, do: Map.put(acc, :username, value), else: acc
          :email -> 
            if validate_email(%{email: value}) == :ok, do: Map.put(acc, :email, value), else: acc
          :password -> 
            # Se for senha, gera o hash
            hash = hash_password(value)
            Map.put(acc, :password_hash, hash)
          key when key in [:is_active, :last_login, :password_hash] ->
            Map.put(acc, key, value)
          _ -> 
            # Ignora campos desconhecidos
            acc
        end
      end)
      
      # Atualiza o timestamp
      updated_user = Map.put(updated_user, :updated_at, DateTime.utc_now())
      
      {:ok, updated_user}
    else
      {:error, reason} -> {:error, reason}
    end
  end
  
  @doc """
  Converte um mapa ou lista de resultados do banco de dados em uma struct de usuário.
  
  ## Parâmetros
  
    - `row`: Mapa ou lista com os dados do banco
  
  ## Retorno
  
    - Uma struct de usuário
  """
  @spec from_db(map() | list()) :: t()
  def from_db(row) when is_list(row) do
    # Se for uma lista, converte para um mapa com índices numéricos
    # Assumindo a ordem: id, username, email, password_hash, is_active, last_login, inserted_at, updated_at
    [id, username, email, password_hash, is_active, last_login, inserted_at, updated_at] = row
    
    %__MODULE__{
      id: id,
      username: username,
      email: email,
      password_hash: password_hash,
      is_active: is_active == 1 || is_active == true,
      last_login: parse_datetime(last_login),
      inserted_at: parse_datetime(inserted_at),
      updated_at: parse_datetime(updated_at)
    }
  end
  
  def from_db(row) when is_map(row) do
    # Converte strings de chaves para atoms quando necessário
    row = if is_map_key(row, "id"), do: convert_string_keys_to_atoms(row), else: row
    
    # Converte timestamps de string para DateTime quando necessário
    inserted_at = parse_datetime(row[:inserted_at])
    updated_at = parse_datetime(row[:updated_at])
    last_login = parse_datetime(row[:last_login])
    
    %__MODULE__{
      id: row[:id],
      username: row[:username],
      email: row[:email],
      password_hash: row[:password_hash],
      is_active: row[:is_active] == 1 || row[:is_active] == true,
      last_login: last_login,
      inserted_at: inserted_at,
      updated_at: updated_at
    }
  end
  
  @doc """
  Converte uma struct de usuário em um mapa para inserção no banco de dados.
  
  ## Parâmetros
  
    - `user`: A struct de usuário
  
  ## Retorno
  
    - Um mapa com os dados para o banco
  """
  @spec to_db(t()) :: map()
  def to_db(user) do
    %{
      id: user.id,
      username: user.username,
      email: user.email,
      password_hash: user.password_hash,
      is_active: if(user.is_active, do: 1, else: 0),
      last_login: format_datetime(user.last_login),
      inserted_at: format_datetime(user.inserted_at),
      updated_at: format_datetime(user.updated_at)
    }
  end
  
  @doc """
  Retorna o nome da tabela no banco de dados.
  """
  @spec table_name() :: String.t()
  def table_name, do: @table_name
  
  @doc """
  Verifica a senha de um usuário.
  
  ## Parâmetros
  
    - `user`: A struct de usuário
    - `password`: A senha a ser verificada
  
  ## Retorno
  
    - `true` se a senha estiver correta
    - `false` caso contrário
  """
  @spec verify_password(t(), String.t()) :: boolean()
  def verify_password(user, password) do
    hash = hash_password(password)
    hash == user.password_hash
  end
  
  # Funções privadas para validação
  
  defp validate_required_fields(attrs) do
    missing_fields = Enum.filter(@required_fields, fn field -> !Map.has_key?(attrs, field) end)
    
    if Enum.empty?(missing_fields) do
      :ok
    else
      {:error, %{missing_fields: missing_fields}}
    end
  end
  
  defp validate_update_fields(_attrs) do
    # Aqui poderia haver validações específicas para atualização
    :ok
  end
  
  defp validate_username(%{username: username}) do
    cond do
      String.length(username) < 3 ->
        {:error, %{username: "deve ter pelo menos 3 caracteres"}}
      String.length(username) > 50 ->
        {:error, %{username: "deve ter no máximo 50 caracteres"}}
      true ->
        :ok
    end
  end
  
  defp validate_email(%{email: email}) do
    if String.match?(email, ~r/@/) do
      :ok
    else
      {:error, %{email: "formato inválido"}}
    end
  end
  
  # Função para hash de senha
  defp hash_password(password) do
    # Em um ambiente real, usaríamos uma biblioteca como Bcrypt
    # Para simplificar, usamos :crypto.hash
    :crypto.hash(:sha256, password) |> Base.encode64()
  end
  
  # Funções auxiliares para conversão de dados
  
  defp convert_string_keys_to_atoms(map) do
    Map.new(map, fn
      {key, value} when is_binary(key) -> {String.to_atom(key), value}
      {key, value} -> {key, value}
    end)
  end
  
  defp parse_datetime(nil), do: nil
  defp parse_datetime(datetime) when is_binary(datetime) do
    case DateTime.from_iso8601(datetime) do
      {:ok, dt, _} -> dt
      _ -> nil
    end
  end
  defp parse_datetime(datetime), do: datetime
  
  defp format_datetime(nil), do: nil
  defp format_datetime(datetime), do: DateTime.to_iso8601(datetime)
end
