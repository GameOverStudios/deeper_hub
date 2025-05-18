defmodule DeeperHub.Accounts.User do
  @moduledoc """
  Módulo para gerenciamento de usuários no DeeperHub.

  Este módulo fornece funções para criar, buscar e atualizar usuários
  no sistema, trabalhando diretamente com SQL em vez de usar Ecto.
  """

  alias DeeperHub.Core.Data.Repo
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Busca um usuário pelo ID.

  ## Parâmetros
    * `id` - ID do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for encontrado
    * `{:error, :not_found}` - Se o usuário não for encontrado
  """
  def get(id) do
    sql = "SELECT * FROM users WHERE id = ?;"

    case Repo.query(sql, [id]) do
      {:ok, %{rows: [user_data], columns: columns}} ->
        user = Enum.zip(columns, user_data) |> Map.new()
        {:ok, user}

      {:ok, %{rows: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Erro ao buscar usuário por ID: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca um usuário pelo email.

  ## Parâmetros
    * `email` - Email do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for encontrado
    * `{:error, :not_found}` - Se o usuário não for encontrado
  """
  def get_by_email(email) do
    sql = "SELECT * FROM users WHERE email = ?;"

    case Repo.query(sql, [email]) do
      {:ok, %{rows: [user_data], columns: columns}} ->
        user = Enum.zip(columns, user_data) |> Map.new()
        {:ok, user}

      {:ok, %{rows: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Erro ao buscar usuário por email: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Cria um novo usuário.

  ## Parâmetros
    * `attrs` - Mapa com os atributos do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for criado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def create(attrs) do
    # Validação básica
    with :ok <- validate_required(attrs, [:username, :email, :password]),
         :ok <- validate_email(attrs.email),
         :ok <- validate_password(attrs.password),
         {:ok, password_hash} <- hash_password(attrs.password) do

      # Gera um UUID para o ID do usuário
      id = UUID.uuid4()
      now = DateTime.utc_now() |> DateTime.to_iso8601()

      sql = """
      INSERT INTO users (id, username, email, password_hash, full_name, bio, avatar_url, created_at, updated_at)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
      """

      params = [
        id,
        attrs.username,
        attrs.email,
        password_hash,
        Map.get(attrs, :full_name, ""),
        Map.get(attrs, :bio, ""),
        Map.get(attrs, :avatar_url, ""),
        now,
        now
      ]

      case Repo.execute(sql, params) do
        {:ok, _} ->
          # Busca o usuário recém-criado
          get(id)

        {:error, reason} ->
          Logger.error("Erro ao criar usuário: #{inspect(reason)}", module: __MODULE__)
          {:error, reason}
      end
    end
  end

  @doc """
  Atualiza um usuário existente.

  ## Parâmetros
    * `id` - ID do usuário
    * `attrs` - Mapa com os atributos a serem atualizados

  ## Retorno
    * `{:ok, user}` - Se o usuário for atualizado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def update(id, attrs) do
    # Verifica se o usuário existe
    with {:ok, _user} <- get(id) do
      # Constrói a query de atualização dinamicamente
      {fields, values} = build_update_fields(attrs)

      if Enum.empty?(fields) do
        {:error, :no_fields_to_update}
      else
        # Adiciona o timestamp de atualização
        fields = fields ++ ["updated_at = ?"]
        now = DateTime.utc_now() |> DateTime.to_iso8601()
        values = values ++ [now, id]

        sql = "UPDATE users SET #{Enum.join(fields, ", ")} WHERE id = ?;"

        case Repo.execute(sql, values) do
          {:ok, _} -> get(id)
          {:error, reason} -> {:error, reason}
        end
      end
    end
  end

  @doc """
  Verifica se as credenciais de um usuário são válidas.

  ## Parâmetros
    * `email` - Email do usuário
    * `password` - Senha do usuário

  ## Retorno
    * `{:ok, user}` - Se as credenciais forem válidas
    * `{:error, reason}` - Se as credenciais forem inválidas
  """
  def verify_credentials(email, password) do
    case get_by_email(email) do
      {:ok, user} ->
        if verify_password(password, user["password_hash"]) do
          {:ok, user}
        else
          {:error, :invalid_credentials}
        end

      {:error, :not_found} ->
        # Executa uma verificação de senha falsa para evitar timing attacks
        Pbkdf2.no_user_verify()
        {:error, :invalid_credentials}

      {:error, reason} ->
        {:error, reason}
    end
  end

  # Funções privadas

  # Valida campos obrigatórios
  defp validate_required(attrs, fields) do
    missing = Enum.filter(fields, fn field -> !Map.has_key?(attrs, field) || is_nil(Map.get(attrs, field)) || Map.get(attrs, field) == "" end)

    if Enum.empty?(missing) do
      :ok
    else
      {:error, {:missing_fields, missing}}
    end
  end

  # Valida formato de email
  defp validate_email(email) do
    if String.match?(email, ~r/^[^\s]+@[^\s]+\.[^\s]+$/) do
      :ok
    else
      {:error, :invalid_email}
    end
  end

  # Valida senha (mínimo 8 caracteres)
  defp validate_password(password) do
    if String.length(password) >= 8 do
      :ok
    else
      {:error, :password_too_short}
    end
  end

  # Gera hash da senha
  defp hash_password(password) do
    {:ok, Pbkdf2.hash_pwd_salt(password)}
  end

  # Verifica se a senha está correta
  defp verify_password(password, password_hash) do
    Pbkdf2.verify_pass(password, password_hash)
  end

  # Constrói os campos e valores para atualização
  defp build_update_fields(attrs) do
    allowed_fields = [:username, :email, :full_name, :bio, :avatar_url, :status]

    Enum.reduce(allowed_fields, {[], []}, fn field, {fields, values} ->
      atom_field = field
      string_field = Atom.to_string(field)

      if Map.has_key?(attrs, atom_field) && !is_nil(attrs[atom_field]) do
        {fields ++ ["#{string_field} = ?"], values ++ [attrs[atom_field]]}
      else
        {fields, values}
      end
    end)
  end
end
