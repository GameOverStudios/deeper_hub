defmodule DeeperHub.Accounts.Auth do
  @moduledoc """
  Contexto de autenticação para o DeeperHub.

  Este módulo fornece funções para autenticação de usuários,
  gerenciamento de senhas e tokens de acesso.
  """

  alias DeeperHub.Accounts.User
  alias DeeperHub.Accounts.Auth.Guardian
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Repo
  require DeeperHub.Core.Logger

  # Importa funções do Guardian para encode_and_sign
  import DeeperHub.Accounts.Auth.Guardian, only: [encode_and_sign: 3]

  @doc """
  Registra um novo usuário no sistema.

  ## Parâmetros
    * `attrs` - Mapa contendo os atributos do usuário (nome, email, senha, etc.)

  ## Exemplos
      iex> register_user(%{username: "joaosilva", email: "joao@exemplo.com", password: "senha123"})
      {:ok, user}

      iex> register_user(%{email: "email_invalido"})
      {:error, {:missing_fields, [:username, :password]}}
  """
  def register_user(attrs) do
    Logger.info("Registrando novo usuário com email: #{Map.get(attrs, :email, "não informado")}", module: __MODULE__)
    User.create(attrs)
  end

  @doc """
  Realiza o login de um usuário com email e senha.

  ## Parâmetros
    * `email` - Email do usuário
    * `password` - Senha do usuário
    * `opts` - Opções adicionais:
      * `:device_info` - Informações sobre o dispositivo (mapa)
      * `:ip_address` - Endereço IP do cliente
      * `:user_agent` - User-Agent do cliente
      * `:persistent` - Se a sessão deve ser persistente (lembrar-me)

  ## Retorno
    * `{:ok, user, tokens, session_id}` - Se o login for bem-sucedido
    * `{:error, :invalid_credentials}` - Se as credenciais forem inválidas
    * `{:error, :email_not_verified}` - Se o email não foi verificado
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec login_with_email_password(String.t(), String.t(), Keyword.t()) ::
    {:ok, map(), map(), String.t()} |
    {:error, atom()} |
    {:error, any()}
  def login_with_email_password(email, password, opts \\ []) do
    # Extrai opções
    device_info = Keyword.get(opts, :device_info, %{})
    ip_address = Keyword.get(opts, :ip_address, "desconhecido")
    user_agent = Keyword.get(opts, :user_agent, "desconhecido")
    persistent = Keyword.get(opts, :persistent, false)

    # Busca o usuário pelo email
    case get_user_by_email(email) do
      {:ok, user} ->
        # Verifica se o email foi verificado, se a verificação estiver ativada
        verification_result = if Application.get_env(:deeper_hub, :require_email_verification, false) do
          case user["email_verified"] do
            true -> :ok
            _ ->
              Logger.info("Tentativa de login com email não verificado: #{email}",
                module: __MODULE__,
                user_id: user["id"]
              )
              {:error, :email_not_verified}
          end
        else
          :ok
        end

        case verification_result do
          :ok ->
            # Continua com a verificação de senha
            if verify_password(password, user["password_hash"]) do
              # Gera tokens de acesso e refresh
              with {:ok, access_token, access_claims} <- generate_access_token(user),
                   {:ok, refresh_token, refresh_claims} <- generate_refresh_token(user) do

                # Cria uma nova sessão
                case DeeperHub.Accounts.SessionManager.create_session(
                  user,
                  refresh_claims["jti"],
                  [
                    device_info: device_info,
                    ip_address: ip_address,
                    user_agent: user_agent,
                    persistent: persistent
                  ]
                ) do
                  {:ok, session_id} ->
                    # Registra a atividade de login
                    DeeperHub.Accounts.ActivityLog.log_activity(user["id"], :login, %{
                      method: "email_password",
                      session_id: session_id,
                      persistent: persistent
                    }, ip_address)

                    # Retorna os tokens e o ID da sessão
                    tokens = %{
                      access_token: access_token,
                      refresh_token: refresh_token,
                      token_type: "Bearer",
                      expires_in: access_claims["exp"] - :os.system_time(:second)
                    }

                    {:ok, user, tokens, session_id}

                  {:error, reason} ->
                    Logger.error("Erro ao criar sessão: #{inspect(reason)}",
                      module: __MODULE__,
                      user_id: user["id"]
                    )
                    {:error, :session_creation_failed}
                end
              else
                error ->
                  Logger.error("Erro ao gerar tokens: #{inspect(error)}",
                    module: __MODULE__,
                    user_id: user["id"]
                  )
                  {:error, :token_generation_failed}
              end
            else
              # Senha inválida
              DeeperHub.Accounts.ActivityLog.log_activity(user["id"], :auth_failure, %{
                method: "email_password",
                reason: "invalid_password"
              }, ip_address)

              {:error, :invalid_credentials}
            end

          {:error, reason} -> {:error, reason}
        end

      {:error, :not_found} ->
        # Usuário não encontrado
        Logger.info("Tentativa de login com email não cadastrado: #{email}", module: __MODULE__)
        {:error, :invalid_credentials}

      {:error, reason} ->
        # Outro erro
        Logger.error("Erro ao buscar usuário: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Gera tokens de acesso e atualização para um usuário autenticado.

  ## Parâmetros
    * `user` - Struct do usuário

  ## Retorno
    * `{:ok, tokens}` - Mapa contendo os tokens gerados
    * `{:error, reason}` - Se ocorrer um erro na geração dos tokens

  ## Exemplos
      iex> generate_tokens(%User{})
      {:ok, %{access_token: "...", refresh_token: "..."}}
  """
  def generate_tokens(user) do
    with {:ok, access_token, _claims} <- Guardian.generate_access_token(user),
         {:ok, refresh_token, _claims} <- Guardian.generate_refresh_token(user) do
      {:ok, %{
        access_token: access_token,
        refresh_token: refresh_token
      }}
    else
      error -> error
    end
  end

  @doc """
  Atualiza um token de acesso usando um token de atualização válido.

  ## Parâmetros
    * `refresh_token` - Token de atualização

  ## Retorno
    * `{:ok, tokens}` - Mapa contendo os novos tokens gerados
    * `{:error, reason}` - Se o token de atualização for inválido
  """
  def refresh_tokens(refresh_token) do
    with {:ok, claims} <- Guardian.verify_token(refresh_token),
         {:ok, user} <- Guardian.resource_from_claims(claims),
         true <- claims["typ"] == "refresh" do
      generate_tokens(user)
    else
      _ -> {:error, :invalid_token}
    end
  end

  @doc """
  Revoga um token, invalidando-o para uso futuro.

  ## Parâmetros
    * `token` - Token a ser revogado

  ## Retorno
    * `:ok` - Se o token foi revogado com sucesso
    * `{:error, reason}` - Se ocorrer um erro ao revogar o token
  """
  def revoke_token(token) do
    case Guardian.revoke_token(token) do
      {:ok, _claims} -> :ok
      error -> error
    end
  end

  @doc """
  Verifica se um token é válido.

  ## Parâmetros
    * `token` - Token a ser verificado

  ## Retorno
    * `{:ok, claims}` - Se o token for válido, retorna as claims
    * `{:error, reason}` - Se o token for inválido
  """
  def verify_token(token) do
    Guardian.verify_token(token)
  end

  @doc """
  Gera um token de acesso para um usuário.

  ## Parâmetros
    * `user` - Mapa com dados do usuário

  ## Retorno
    * `{:ok, token, claims}` - Se o token for gerado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def generate_access_token(user) do
    encode_and_sign(user, %{}, token_options(:access))
  end

  @doc """
  Gera um token de refresh para um usuário.

  ## Parâmetros
    * `user` - Mapa com dados do usuário

  ## Retorno
    * `{:ok, token, claims}` - Se o token for gerado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def generate_refresh_token(user) do
    encode_and_sign(user, %{}, token_options(:refresh))
  end

  @doc """
  Atualiza tokens usando um token de refresh válido.

  ## Parâmetros
    * `refresh_token` - Token de refresh
    * `session_id` - ID da sessão associada ao token
    * `opts` - Opções adicionais:
      * `:ip_address` - Endereço IP do cliente

  ## Retorno
    * `{:ok, user, tokens}` - Se os tokens forem atualizados com sucesso
    * `{:error, :invalid_token}` - Se o token de refresh for inválido
    * `{:error, :session_not_found}` - Se a sessão não for encontrada
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec refresh_tokens(String.t(), String.t(), Keyword.t()) ::
    {:ok, map(), map()} |
    {:error, atom()} |
    {:error, any()}
  def refresh_tokens(refresh_token, session_id, opts \\ []) do
    ip_address = Keyword.get(opts, :ip_address, "desconhecido")

    # Verifica o token de refresh
    case Guardian.verify_token(refresh_token) do
      {:ok, claims} ->
        # Verifica se a sessão existe e está ativa
        case DeeperHub.Accounts.SessionManager.verify_session(session_id) do
          {:ok, session} ->
            # Verifica se o JTI do token corresponde ao da sessão
            if claims["jti"] == session["refresh_token_jti"] do
              # Busca o usuário
              case get_user_by_id(claims["sub"]) do
                {:ok, user} ->
                  # Revoga o token de refresh atual
                  DeeperHub.Accounts.Auth.TokenBlacklist.add_to_blacklist(
                    claims["jti"],
                    user["id"],
                    "refresh",
                    DateTime.from_iso8601!(claims["exp"]),
                    "refresh_token_rotation"
                  )

                  # Gera novos tokens
                  with {:ok, access_token, access_claims} <- generate_access_token(user),
                       {:ok, new_refresh_token, refresh_claims} <- generate_refresh_token(user) do

                    # Atualiza a sessão com o novo JTI do token de refresh
                    sql = """
                    UPDATE user_sessions
                    SET refresh_token_jti = ?, updated_at = ?
                    WHERE id = ?;
                    """

                    now = DateTime.utc_now() |> DateTime.to_iso8601()
                    DeeperHub.Core.Data.Repo.execute(sql, [refresh_claims["jti"], now, session_id])

                    # Registra a atividade
                    DeeperHub.Accounts.ActivityLog.log_activity(user["id"], :token_refreshed, %{
                      session_id: session_id
                    }, ip_address)

                    # Retorna os novos tokens
                    tokens = %{
                      access_token: access_token,
                      refresh_token: new_refresh_token,
                      token_type: "Bearer",
                      expires_in: access_claims["exp"] - :os.system_time(:second)
                    }

                    {:ok, user, tokens}
                  else
                    error ->
                      Logger.error("Erro ao gerar novos tokens: #{inspect(error)}",
                        module: __MODULE__,
                        user_id: user["id"],
                        session_id: session_id
                      )
                      {:error, :token_generation_failed}
                  end

                {:error, reason} ->
                  Logger.error("Erro ao buscar usuário para refresh: #{inspect(reason)}",
                    module: __MODULE__,
                    user_id: claims["sub"],
                    session_id: session_id
                  )
                  {:error, reason}
              end
            else
              # JTI não corresponde - possível tentativa de reutilização de token
              Logger.warn("Tentativa de refresh com JTI inválido",
                module: __MODULE__,
                session_id: session_id,
                expected_jti: session["refresh_token_jti"],
                received_jti: claims["jti"]
              )

              # Invalida a sessão por segurança
              DeeperHub.Accounts.SessionManager.invalidate_session(session_id, "invalid_refresh_token_jti")

              {:error, :invalid_token}
            end

          {:error, :session_not_found} ->
            Logger.warn("Tentativa de refresh com sessão inexistente",
              module: __MODULE__,
              session_id: session_id
            )
            {:error, :session_not_found}

          {:error, :session_expired} ->
            Logger.info("Tentativa de refresh com sessão expirada",
              module: __MODULE__,
              session_id: session_id
            )
            {:error, :session_expired}

          {:error, reason} ->
            Logger.error("Erro ao verificar sessão para refresh: #{inspect(reason)}",
              module: __MODULE__,
              session_id: session_id
            )
            {:error, reason}
        end

      {:error, :token_revoked} ->
        # Token já foi revogado
        Logger.warn("Tentativa de refresh com token revogado",
          module: __MODULE__,
          session_id: session_id
        )
        {:error, :invalid_token}

      {:error, _reason} ->
        # Token inválido por outro motivo
        Logger.warn("Tentativa de refresh com token inválido",
          module: __MODULE__,
          session_id: session_id
        )
        {:error, :invalid_token}
    end
  end

  # Funções privadas

  @doc """
  Busca um usuário pelo email.

  ## Parâmetros
    * `email` - Email do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for encontrado
    * `{:error, :not_found}` - Se o usuário não for encontrado
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec get_user_by_email(String.t()) :: {:ok, map()} | {:error, atom()} | {:error, any()}
  def get_user_by_email(email) do
    sql = "SELECT * FROM users WHERE email = ? LIMIT 1;"

    case Repo.query(sql, [email]) do
      {:ok, %{rows: [row], columns: columns}} ->
        user = Enum.zip(columns, row) |> Map.new()
        {:ok, user}

      {:ok, %{rows: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Erro ao buscar usuário por email: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Busca um usuário pelo ID.

  ## Parâmetros
    * `user_id` - ID do usuário

  ## Retorno
    * `{:ok, user}` - Se o usuário for encontrado
    * `{:error, :not_found}` - Se o usuário não for encontrado
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec get_user_by_id(String.t()) :: {:ok, map()} | {:error, atom()} | {:error, any()}
  def get_user_by_id(user_id) do
    sql = "SELECT * FROM users WHERE id = ? LIMIT 1;"

    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: [row], columns: columns}} ->
        user = Enum.zip(columns, row) |> Map.new()
        {:ok, user}

      {:ok, %{rows: []}} ->
        {:error, :not_found}

      {:error, reason} ->
        Logger.error("Erro ao buscar usuário por ID: #{inspect(reason)}", module: __MODULE__)
        {:error, reason}
    end
  end

  @doc """
  Verifica se uma senha corresponde ao hash armazenado.
  
  ## Parâmetros
    * `password` - Senha em texto plano
    * `password_hash` - Hash da senha armazenado
  
  ## Retorno
    * `true` - Se a senha for válida
    * `false` - Se a senha for inválida
  """
  @spec verify_password(String.t(), String.t()) :: boolean()
  def verify_password(password, password_hash) do
    Pbkdf2.verify_pass(password, password_hash)
  end

  @doc """
  Retorna as opções para geração de tokens.

  ## Parâmetros
    * `type` - Tipo de token (:access ou :refresh)

  ## Retorno
    * Mapa com as opções do token
  """
  @spec token_options(atom()) :: map()
  # Configurações de token
  @token_config %{
    access: %{
      ttl: {1, :hour},
      token_type: "access"
    },
    refresh: %{
      ttl: {30, :day},
      token_type: "refresh"
    }
  }

  def token_options(:access) do
    @token_config.access
  end
  def token_options(:refresh) do
    @token_config.refresh
  end
end
