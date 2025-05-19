defmodule DeeperHub.Accounts.Auth.Token do
  @moduledoc """
  Módulo para gerenciamento de tokens JWT no DeeperHub.

  Este módulo fornece funções auxiliares para trabalhar com tokens JWT,
  incluindo geração, validação e extração de informações.
  """

  alias DeeperHub.Accounts.Auth.Guardian
  alias DeeperHub.Core.Logger
  alias DeeperHub.Core.Data.Repo
  require DeeperHub.Core.Logger

  @doc """
  Extrai o ID do usuário de um token JWT.

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, user_id}` - ID do usuário extraído do token
    * `{:error, reason}` - Se o token for inválido

  ## Exemplos
      iex> extract_user_id("valid.jwt.token")
      {:ok, "123e4567-e89b-12d3-a456-426614174000"}

      iex> extract_user_id("invalid.token")
      {:error, :invalid_token}
  """
  def extract_user_id(token) do
    case Guardian.verify_token(token) do
      {:ok, claims} -> {:ok, claims["sub"]}
      error -> error
    end
  end

  @doc """
  Extrai o tipo de um token JWT (acesso ou atualização).

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, token_type}` - Tipo do token ("access" ou "refresh")
    * `{:error, reason}` - Se o token for inválido
  """
  def extract_token_type(token) do
    case Guardian.verify_token(token) do
      {:ok, claims} -> {:ok, claims["typ"]}
      error -> error
    end
  end

  @doc """
  Verifica se um token JWT é um token de acesso válido.

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, claims}` - Se o token for um token de acesso válido
    * `{:error, reason}` - Se o token for inválido ou não for um token de acesso
  """
  def verify_access_token(token) do
    with {:ok, claims} <- Guardian.verify_token(token),
         true <- claims["typ"] == "access" do
      {:ok, claims}
    else
      false -> {:error, :not_access_token}
      error -> error
    end
  end

  @doc """
  Verifica se um token JWT é um token de atualização válido.

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, claims}` - Se o token for um token de atualização válido
    * `{:error, reason}` - Se o token for inválido ou não for um token de atualização
  """
  def verify_refresh_token(token) do
    with {:ok, claims} <- Guardian.verify_token(token),
         true <- claims["typ"] == "refresh" do
      {:ok, claims}
    else
      false -> {:error, :not_refresh_token}
      error -> error
    end
  end

  @doc """
  Obtém o tempo de expiração de um token JWT.

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, expiration_time}` - Timestamp de expiração do token
    * `{:error, reason}` - Se o token for inválido
  """
  def get_expiration_time(token) do
    case Guardian.verify_token(token) do
      {:ok, claims} -> {:ok, claims["exp"]}
      error -> error
    end
  end

  @doc """
  Verifica se um token JWT está expirado.

  ## Parâmetros
    * `token` - Token JWT

  ## Retorno
    * `{:ok, false}` - Se o token não estiver expirado
    * `{:ok, true}` - Se o token estiver expirado
    * `{:error, reason}` - Se o token for inválido
  """
  def is_expired?(token) do
    case get_expiration_time(token) do
      {:ok, exp} ->
        now = DateTime.utc_now() |> DateTime.to_unix()
        {:ok, exp < now}
      error -> error
    end
  end

  @doc """
  Revoga um token JWT específico.

  ## Parâmetros
    * `token` - Token JWT a ser revogado

  ## Retorno
    * `:ok` - Se o token for revogado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def revoke_token(token) do
    case Guardian.revoke(token) do
      {:ok, _claims} -> :ok
      error -> error
    end
  end

  @doc """
  Revoga todos os tokens associados a uma sessão.

  ## Parâmetros
    * `session_id` - ID da sessão

  ## Retorno
    * `:ok` - Se os tokens forem revogados com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def revoke_by_session(session_id) do
    # Busca todos os tokens associados à sessão no banco de dados
    sql = "SELECT token FROM user_tokens WHERE session_id = ?;"

    case Repo.query(sql, [session_id]) do
      {:ok, %{rows: rows}} ->
        # Revoga cada token encontrado
        Enum.each(rows, fn [token] ->
          Guardian.revoke(token)
        end)

        # Marca os tokens como revogados no banco de dados
        update_sql = "UPDATE user_tokens SET revoked = TRUE WHERE session_id = ?;"
        Repo.execute(update_sql, [session_id])

        :ok

      {:error, reason} ->
        Logger.error("Erro ao revogar tokens por sessão: #{inspect(reason)}",
          module: __MODULE__,
          session_id: session_id
        )
        {:error, reason}
    end
  end

  @doc """
  Revoga todos os tokens de um usuário.

  ## Parâmetros
    * `user_id` - ID do usuário
    * `reason` - Motivo da revogação (opcional) ou ID da sessão atual a ser preservada

  ## Retorno
    * `:ok` - Se os tokens forem revogados com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  """
  def revoke_all_for_user(user_id, reason_or_session_id \\ "user_logout")
  
  def revoke_all_for_user(user_id, reason) when is_binary(reason) and byte_size(reason) < 50 do
    # Busca todos os tokens do usuário no banco de dados
    sql = """
    SELECT t.token, t.token_type, t.expires_at, t.jti
    FROM user_tokens t
    WHERE t.user_id = ? AND t.revoked = FALSE;
    """

    case Repo.query(sql, [user_id]) do
      {:ok, %{rows: rows, columns: columns}} ->
        # Para cada token, adiciona à blacklist e revoga
        Enum.each(rows, fn row ->
          token_data = Enum.zip(columns, row) |> Map.new()

          # Adiciona o token à blacklist
          jti = token_data["jti"]
          token_type = token_data["token_type"]
          expires_at = case DateTime.from_iso8601(token_data["expires_at"]) do
            {:ok, datetime, _} -> datetime
            _ -> DateTime.utc_now() |> DateTime.add(3600, :second) # Fallback: 1 hora
          end

          DeeperHub.Accounts.Auth.TokenBlacklist.add_to_blacklist(
            jti,
            user_id,
            token_type,
            expires_at,
            reason
          )

          # Revoga o token no Guardian
          Guardian.revoke_token(token_data["token"])
        end)

        # Marca todos os tokens como revogados no banco de dados
        update_sql = """
        UPDATE user_tokens
        SET revoked = TRUE, revoked_at = ?, revocation_reason = ?
        WHERE user_id = ? AND revoked = FALSE;
        """

        now = DateTime.utc_now() |> DateTime.to_iso8601()
        Repo.execute(update_sql, [now, reason, user_id])

        Logger.info("Todos os tokens do usuário #{user_id} foram revogados",
          module: __MODULE__,
          reason: reason
        )

        :ok

      {:error, reason} ->
        Logger.error("Erro ao revogar tokens do usuário: #{inspect(reason)}",
          module: __MODULE__,
          user_id: user_id
        )
        {:error, reason}
    end
  end

  # Segunda cláusula para revoke_all_for_user/2
  # Revoga todos os tokens de um usuário, exceto os da sessão atual
  def revoke_all_for_user(user_id, current_session_id) do
    # Busca todos os tokens do usuário em outras sessões
    sql = "SELECT token FROM user_tokens WHERE user_id = ? AND session_id != ?;"

    case Repo.query(sql, [user_id, current_session_id]) do
      {:ok, %{rows: rows}} ->
        # Revoga cada token encontrado
        Enum.each(rows, fn [token] ->
          Guardian.revoke(token)
        end)

        # Marca os tokens como revogados no banco de dados
        update_sql = "UPDATE user_tokens SET revoked = TRUE WHERE user_id = ? AND session_id != ?;"
        Repo.execute(update_sql, [user_id, current_session_id])

        :ok

      {:error, reason} ->
        Logger.error("Erro ao revogar tokens do usuário (exceto sessão atual): #{inspect(reason)}",
          module: __MODULE__,
          user_id: user_id,
          current_session_id: current_session_id
        )
        {:error, reason}
    end
  end
end
