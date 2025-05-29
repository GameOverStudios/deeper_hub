defmodule DeeperHub.Accounts.User do
  @moduledoc """
  Módulo para gerenciamento de usuários no DeeperHub.

  Este módulo fornece funções para criar, buscar e atualizar usuários
  no sistema, trabalhando diretamente com SQL em vez de usar Ecto.
  
  Responsável por:
  - Criação e atualização de contas de usuário
  - Busca de usuários por ID ou email
  - Validação de credenciais
  - Gerenciamento de informações de perfil
  
  Todas as operações incluem validações robustas e tratamento de erros
  para garantir a integridade dos dados e a segurança do sistema.
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
    * `{:error, :invalid_id}` - Se o ID for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.User.get("user123")
      {:ok, %{"id" => "user123", "username" => "joaosilva", ...}}
  """
  @spec get(String.t()) :: {:ok, map()} | {:error, atom()}
  def get(id) when is_binary(id) and id != "" do
    try do
      sql = "SELECT * FROM users WHERE id = ?;"

      case Repo.query(sql, [id]) do
        {:ok, %{rows: [user_data], columns: columns}} ->
          user = Enum.zip(columns, user_data) |> Map.new()
          {:ok, user}

        {:ok, %{rows: []}} ->
          Logger.info("Usuário não encontrado com ID: #{id}", module: __MODULE__)
          {:error, :not_found}

        {:error, reason} ->
          Logger.error("Erro ao buscar usuário por ID: #{inspect(reason)}", module: __MODULE__)
          {:error, :database_error}
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao buscar usuário por ID: #{Exception.message(e)}", 
          module: __MODULE__,
          user_id: id
        )
        {:error, :unexpected_error}
    end
  end
  
  def get(_) do
    Logger.warn("Tentativa de buscar usuário com ID inválido", module: __MODULE__)
    {:error, :invalid_id}
  end

  @doc """
  Busca um usuário pelo email.

  ## Parâmetros
    * `email` - Email do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for encontrado
    * `{:error, :not_found}` - Se o usuário não for encontrado
    * `{:error, :invalid_email}` - Se o email for inválido
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.User.get_by_email("joao@exemplo.com")
      {:ok, %{"id" => "user123", "email" => "joao@exemplo.com", ...}}
  """
  @spec get_by_email(String.t()) :: {:ok, map()} | {:error, atom()}
  def get_by_email(email) when is_binary(email) and email != "" do
    if String.contains?(email, "@") do
      try do
        sql = "SELECT * FROM users WHERE email = ?;"

        case Repo.query(sql, [email]) do
          {:ok, %{rows: [user_data], columns: columns}} ->
            user = Enum.zip(columns, user_data) |> Map.new()
            {:ok, user}

          {:ok, %{rows: []}} ->
            Logger.info("Usuário não encontrado com email: #{email}", module: __MODULE__)
            {:error, :not_found}

          {:error, reason} ->
            Logger.error("Erro ao buscar usuário por email: #{inspect(reason)}", module: __MODULE__)
            {:error, :database_error}
        end
      rescue
        e ->
          Logger.error("Erro inesperado ao buscar usuário por email: #{Exception.message(e)}", 
            module: __MODULE__,
            email: email
          )
          {:error, :unexpected_error}
      end
    else
      Logger.warn("Tentativa de buscar usuário com formato de email inválido: #{email}", module: __MODULE__)
      {:error, :invalid_email}
    end
  end
  
  def get_by_email(_) do
    Logger.warn("Tentativa de buscar usuário com email inválido", module: __MODULE__)
    {:error, :invalid_email}
  end

  @doc """
  Cria um novo usuário.

  ## Parâmetros
    * `attrs` - Mapa com os atributos do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for criado com sucesso
    * `{:error, :missing_fields, fields}` - Se campos obrigatórios estiverem faltando
    * `{:error, :invalid_email_format}` - Se o formato do email for inválido
    * `{:error, :password_too_short}` - Se a senha for muito curta
    * `{:error, :password_too_weak}` - Se a senha não atender aos requisitos de segurança
    * `{:error, :email_already_exists}` - Se o email já estiver em uso
    * `{:error, :username_already_exists}` - Se o nome de usuário já estiver em uso
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.User.create(%{username: "joaosilva", email: "joao@exemplo.com", password: "Senha123!"})  
      {:ok, %{"id" => "user123", "username" => "joaosilva", ...}}
  """
  @spec create(map()) :: {:ok, map()} | {:error, atom()} | {:error, :missing_fields, list(atom())}
  def create(attrs) when is_map(attrs) do
    try do
      # Validação básica
      with :ok <- validate_required(attrs, [:username, :email, :password]),
          :ok <- validate_email(attrs.email),
          :ok <- validate_password(attrs.password),
          :ok <- check_email_exists(attrs.email),
          :ok <- check_username_exists(attrs.username),
          {:ok, password_hash} <- hash_password(attrs.password) do

        # Gera um UUID para o ID do usuário
        id = UUID.uuid4()
        now = DateTime.utc_now() |> DateTime.to_iso8601()

        sql = """
        INSERT INTO users (id, username, email, password_hash, full_name, bio, avatar_url, created_at, updated_at, email_verified, status)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);
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
          now,
          false,  # email_verified
          "active" # status
        ]

        case Repo.execute(sql, params) do
          {:ok, _} ->
            Logger.info("Usuário criado com sucesso: #{id}", 
              module: __MODULE__,
              username: attrs.username,
              email: attrs.email
            )
            # Busca o usuário recém-criado
            get(id)

          {:error, %{code: :constraint}} ->
            Logger.warn("Violação de restrição ao criar usuário", 
              module: __MODULE__,
              username: attrs.username,
              email: attrs.email
            )
            {:error, :constraint_violation}
            
          {:error, reason} ->
            Logger.error("Erro ao criar usuário: #{inspect(reason)}", module: __MODULE__)
            {:error, :database_error}
        end
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao criar usuário: #{Exception.message(e)}", module: __MODULE__)
        {:error, :unexpected_error}
    end
  end
  
  def create(_) do
    Logger.warn("Tentativa de criar usuário com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  # Verifica se o email já existe
  @spec check_email_exists(String.t()) :: :ok | {:error, atom()}
  defp check_email_exists(email) do
    sql = "SELECT 1 FROM users WHERE email = ?;"
    
    case Repo.query(sql, [email]) do
      {:ok, %{rows: []}} -> :ok
      {:ok, _} -> {:error, :email_already_exists}
      {:error, _} -> {:error, :database_error}
    end
  end
  
  # Verifica se o nome de usuário já existe
  @spec check_username_exists(String.t()) :: :ok | {:error, atom()}
  defp check_username_exists(username) do
    sql = "SELECT 1 FROM users WHERE username = ?;"
    
    case Repo.query(sql, [username]) do
      {:ok, %{rows: []}} -> :ok
      {:ok, _} -> {:error, :username_already_exists}
      {:error, _} -> {:error, :database_error}
    end
  end

  @doc """
  Atualiza um usuário existente.

  ## Parâmetros
    * `id` - ID do usuário
    * `attrs` - Mapa com os atributos a serem atualizados

  ## Retorno
    * `{:ok, user}` - Se o usuário for atualizado com sucesso
    * `{:error, :not_found}` - Se o usuário não for encontrado
    * `{:error, :no_fields_to_update}` - Se não houver campos para atualizar
    * `{:error, :invalid_email_format}` - Se o formato do email for inválido
    * `{:error, :email_already_exists}` - Se o novo email já estiver em uso
    * `{:error, :database_error}` - Se ocorrer um erro no banco de dados
  
  ## Exemplos
      iex> DeeperHub.Accounts.User.update("user123", %{full_name: "João da Silva"})
      {:ok, %{"id" => "user123", "full_name" => "João da Silva", ...}}
  """
  @spec update(String.t(), map()) :: {:ok, map()} | {:error, atom()}
  def update(id, attrs) when is_binary(id) and id != "" and is_map(attrs) do
    try do
      # Verifica se o usuário existe
      with {:ok, user} <- get(id),
           :ok <- validate_update_attrs(attrs, user) do
        # Constrói a query de atualização dinamicamente
        {fields, values} = build_update_fields(attrs)

        if Enum.empty?(fields) do
          Logger.info("Nenhum campo válido para atualizar", 
            module: __MODULE__,
            user_id: id
          )
          {:error, :no_fields_to_update}
        else
          # Adiciona o timestamp de atualização
          fields = fields ++ ["updated_at = ?"]
          now = DateTime.utc_now() |> DateTime.to_iso8601()
          values = values ++ [now, id]

          sql = "UPDATE users SET #{Enum.join(fields, ", ")} WHERE id = ?;"

          case Repo.execute(sql, values) do
            {:ok, %{rows_affected: 1}} -> 
              Logger.info("Usuário atualizado com sucesso: #{id}", module: __MODULE__)
              get(id)
              
            {:ok, %{rows_affected: 0}} -> 
              Logger.warn("Usuário não encontrado ao atualizar: #{id}", module: __MODULE__)
              {:error, :not_found}
              
            {:error, reason} -> 
              Logger.error("Erro ao atualizar usuário: #{inspect(reason)}", 
                module: __MODULE__,
                user_id: id
              )
              {:error, :database_error}
          end
        end
      end
    rescue
      e ->
        Logger.error("Erro inesperado ao atualizar usuário: #{Exception.message(e)}", 
          module: __MODULE__,
          user_id: id
        )
        {:error, :unexpected_error}
    end
  end
  
  def update(_, _) do
    Logger.warn("Tentativa de atualizar usuário com parâmetros inválidos", module: __MODULE__)
    {:error, :invalid_input}
  end
  
  # Valida os atributos de atualização
  @spec validate_update_attrs(map(), map()) :: :ok | {:error, atom()}
  defp validate_update_attrs(attrs, user) do
    cond do
      Map.has_key?(attrs, :email) and attrs.email != user["email"] ->
        with :ok <- validate_email(attrs.email),
             :ok <- check_email_exists(attrs.email) do
          :ok
        end
        
      Map.has_key?(attrs, :username) and attrs.username != user["username"] ->
        check_username_exists(attrs.username)
        
      true ->
        :ok
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
    # Expressão regular mais robusta para validação de email
    email_regex = ~r/^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/
    
    cond do
      is_nil(email) or email == "" ->
        {:error, :email_required}
        
      String.length(email) > 255 ->
        {:error, :email_too_long}
        
      !String.match?(email, email_regex) ->
        {:error, :invalid_email_format}
        
      true ->
        :ok
    end
  end

  # Valida senha com requisitos de segurança
  defp validate_password(password) do
    cond do
      is_nil(password) or password == "" ->
        {:error, :password_required}
        
      String.length(password) < 8 ->
        {:error, :password_too_short}
        
      String.length(password) > 72 ->
        # PBKDF2 tem limite de 72 bytes para senhas
        {:error, :password_too_long}
        
      !String.match?(password, ~r/[A-Z]/) ->
        {:error, :password_needs_uppercase}
        
      !String.match?(password, ~r/[a-z]/) ->
        {:error, :password_needs_lowercase}
        
      !String.match?(password, ~r/[0-9]/) ->
        {:error, :password_needs_number}
        
      !String.match?(password, ~r/[^A-Za-z0-9]/) ->
        {:error, :password_needs_special_char}
        
      true ->
        :ok
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
