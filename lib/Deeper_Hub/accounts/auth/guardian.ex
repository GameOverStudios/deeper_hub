defmodule DeeperHub.Accounts.Auth.Guardian do
  @moduledoc """
  Implementação do Guardian para autenticação JWT no DeeperHub.
  
  Este módulo é responsável por gerenciar tokens JWT para autenticação
  de usuários, incluindo geração, validação e revogação de tokens.
  
  O Guardian é utilizado para implementar a autenticação baseada em tokens JWT,
  fornecendo uma camada de abstração para geração, validação e revogação de tokens,
  além de integração com a blacklist de tokens revogados.
  """
  use Guardian, otp_app: :deeper_hub

  alias DeeperHub.Accounts.User
  alias DeeperHub.Core.Logger
  alias DeeperHub.Accounts.Auth.TokenBlacklist
  require DeeperHub.Core.Logger

  @doc """
  Função chamada pelo Guardian para extrair o subject de um token a partir de um recurso.
  
  Recebe o recurso (geralmente um usuário) e retorna o subject que será usado no token.
  No caso do DeeperHub, o subject é o ID do usuário.
  
  ## Parâmetros
    * `user` - Mapa contendo os dados do usuário
    * `_claims` - Claims adicionais (não utilizado)
  
  ## Retorno
    * `{:ok, subject}` - Se o subject for extraído com sucesso
    * `{:error, :invalid_resource}` - Se o recurso for inválido
  """
  @spec subject_for_token(map(), map()) :: {:ok, String.t()} | {:error, atom()}
  def subject_for_token(user, _claims) when is_map(user) do
    # Extrai o ID do usuário do mapa, suportando tanto strings quanto atoms como chaves
    sub = to_string(user["id"] || user[:id])
    
    if sub && String.length(sub) > 0 do
      {:ok, sub}
    else
      Logger.error("Tentativa de gerar token com ID de usuário inválido", module: __MODULE__)
      {:error, :invalid_resource}
    end
  end

  def subject_for_token(resource, _claims) do
    Logger.error("Tentativa de gerar token com recurso inválido: #{inspect(resource)}", module: __MODULE__)
    {:error, :invalid_resource}
  end

  @doc """
  Função chamada pelo Guardian para converter um subject de token em um recurso.
  
  Recebe as claims do token e retorna o recurso correspondente.
  No caso do DeeperHub, busca o usuário pelo ID contido no subject do token.
  
  ## Parâmetros
    * `claims` - Mapa contendo as claims do token
  
  ## Retorno
    * `{:ok, user}` - Se o usuário for encontrado
    * `{:error, :resource_not_found}` - Se o usuário não for encontrado
    * `{:error, :invalid_claims}` - Se as claims forem inválidas
    * `{:error, :resource_error}` - Se ocorrer outro erro
  """
  @spec resource_from_claims(map()) :: {:ok, map()} | {:error, atom()}
  def resource_from_claims(%{"sub" => sub}) when is_binary(sub) and sub != "" do
    case User.get(sub) do
      {:ok, user} -> 
        {:ok, user}
        
      {:error, :not_found} -> 
        Logger.warn("Tentativa de uso de token com usuário inexistente: #{sub}", module: __MODULE__)
        {:error, :resource_not_found}
        
      {:error, reason} -> 
        Logger.error("Erro ao buscar usuário para claims: #{inspect(reason)}", 
          module: __MODULE__,
          user_id: sub
        )
        {:error, :resource_error}
    end
  end

  def resource_from_claims(claims) do
    Logger.warn("Tentativa de uso de token com claims inválidas: #{inspect(claims)}", module: __MODULE__)
    {:error, :invalid_claims}
  end

  @doc """
  Gera um token de acesso para um usuário.
  
  ## Parâmetros
    * `user` - Mapa contendo os dados do usuário
  
  ## Retorno
    * `{:ok, token, claims}` - Se o token for gerado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.Guardian.generate_access_token(user)
      {:ok, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", %{"exp" => 1622505600, ...}}
  """
  @spec generate_access_token(map()) :: {:ok, String.t(), map()} | {:error, any()}
  def generate_access_token(user) do
    encode_and_sign(user, %{}, token_options(:access))
  end

  @doc """
  Gera um token de atualização (refresh token) para um usuário.
  
  ## Parâmetros
    * `user` - Mapa contendo os dados do usuário
  
  ## Retorno
    * `{:ok, token, claims}` - Se o token for gerado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.Guardian.generate_refresh_token(user)
      {:ok, "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...", %{"exp" => 1625097600, ...}}
  """
  @spec generate_refresh_token(map()) :: {:ok, String.t(), map()} | {:error, any()}
  def generate_refresh_token(user) do
    encode_and_sign(user, %{}, token_options(:refresh))
  end

  @doc """
  Verifica se um token é válido.
  
  Além da verificação padrão do Guardian, também verifica se o token
  está na blacklist de tokens revogados.
  
  ## Parâmetros
    * `token` - Token JWT a ser verificado
  
  ## Retorno
    * `{:ok, claims}` - Se o token for válido
    * `{:error, :token_revoked}` - Se o token estiver na blacklist
    * `{:error, :invalid_token}` - Se o token for inválido
    * `{:error, reason}` - Se ocorrer outro erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.Guardian.verify_token("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
      {:ok, %{"sub" => "user123", "exp" => 1622505600, ...}}
  """
  @spec verify_token(String.t()) :: {:ok, map()} | {:error, any()}
  def verify_token(token) when is_binary(token) do
    with {:ok, claims} <- decode_and_verify(token),
         jti <- Map.get(claims, "jti"),
         {:ok, false} <- TokenBlacklist.is_blacklisted?(jti) do
      {:ok, claims}
    else
      {:ok, true} -> 
        # Token está na blacklist
        Logger.warn("Tentativa de uso de token revogado", module: __MODULE__)
        {:error, :token_revoked}
        
      {:error, %{message: message}} ->
        # Erro do Guardian
        Logger.warn("Token inválido: #{message}", module: __MODULE__)
        {:error, :invalid_token}
        
      {:error, reason} = error when is_atom(reason) -> 
        # Outros erros do Guardian
        Logger.warn("Erro ao verificar token: #{reason}", module: __MODULE__)
        error
        
      error -> 
        # Erro inesperado
        Logger.error("Erro inesperado ao verificar token: #{inspect(error)}", module: __MODULE__)
        {:error, :verification_error}
    end
  end
  
  def verify_token(_) do
    Logger.warn("Tentativa de verificar token não-string", module: __MODULE__)
    {:error, :invalid_token}
  end

  @doc """
  Revoga um token, adicionando-o à blacklist.
  
  ## Parâmetros
    * `token` - Token JWT a ser revogado
  
  ## Retorno
    * `{:ok, claims}` - Se o token for revogado com sucesso
    * `{:error, reason}` - Se ocorrer um erro
  
  ## Exemplos
      iex> DeeperHub.Accounts.Auth.Guardian.revoke_token("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...")
      {:ok, %{"sub" => "user123", "exp" => 1622505600, ...}}
  """
  @spec revoke_token(String.t()) :: {:ok, map()} | {:error, any()}
  def revoke_token(token) when is_binary(token) do
    case decode_and_verify(token) do
      {:ok, claims} ->
        # Adiciona o token à blacklist
        jti = Map.get(claims, "jti")
        user_id = Map.get(claims, "sub")
        token_type = Map.get(claims, "typ")
        
        # Obtém a data de expiração
        exp = Map.get(claims, "exp")
        expires_at = DateTime.from_unix!(exp)
        
        case TokenBlacklist.add_to_blacklist(jti, user_id, token_type, expires_at, "revoked_by_user") do
          :ok -> 
            Logger.info("Token revogado com sucesso", 
              module: __MODULE__, 
              user_id: user_id, 
              token_type: token_type
            )
            {:ok, claims}
            
          {:error, reason} ->
            Logger.error("Erro ao adicionar token à blacklist: #{inspect(reason)}", 
              module: __MODULE__, 
              user_id: user_id
            )
            {:error, :revocation_failed}
        end
        
      {:error, reason} ->
        Logger.warn("Tentativa de revogar token inválido: #{inspect(reason)}", module: __MODULE__)
        {:error, :invalid_token}
    end
  end
  
  def revoke_token(_) do
    Logger.warn("Tentativa de revogar token não-string", module: __MODULE__)
    {:error, :invalid_token}
  end

  @doc false
  # Configurações para diferentes tipos de tokens
  @spec token_options(atom()) :: keyword()
  defp token_options(:access) do
    # Obtém configurações do config ou usa valores padrão
    ttl = get_token_ttl("access", {1, :hour})
    
    [
      token_type: "access",
      ttl: ttl,
      # Adiciona JTI (JWT ID) para rastreamento e revogação
      jti: generate_jti(),
      # Adiciona metadados úteis para auditoria
      iat: DateTime.utc_now() |> DateTime.to_unix(),
      # Adiciona informações do emissor
      iss: "deeper_hub"
    ]
  end

  @doc false
  @spec token_options(atom()) :: keyword()
  defp token_options(:refresh) do
    # Obtém configurações do config ou usa valores padrão
    ttl = get_token_ttl("refresh", {30, :days})
    
    [
      token_type: "refresh",
      ttl: ttl,
      # Adiciona JTI (JWT ID) para rastreamento e revogação
      jti: generate_jti(),
      # Adiciona metadados úteis para auditoria
      iat: DateTime.utc_now() |> DateTime.to_unix(),
      # Adiciona informações do emissor
      iss: "deeper_hub"
    ]
  end
  
  @doc false
  # Obtém a configuração TTL para um tipo específico de token
  @spec get_token_ttl(String.t(), tuple()) :: tuple()
  defp get_token_ttl(type, default) do
    case Application.get_env(:deeper_hub, __MODULE__)[:token_ttl] do
      %{^type => ttl} when is_tuple(ttl) -> ttl
      _ -> default
    end
  end
  
  @doc false
  # Gera um identificador único para o token (JWT ID)
  @spec generate_jti() :: String.t()
  defp generate_jti do
    :crypto.strong_rand_bytes(16) |> Base.url_encode64(padding: false)
  end
  
  @doc """
  Verifica se um token está próximo de expirar.
  
  ## Parâmetros
    * `token` - Token JWT a ser verificado
    * `threshold_seconds` - Limiar em segundos para considerar o token próximo de expirar
  
  ## Retorno
    * `{:ok, seconds_remaining}` - Se o token for válido, retorna os segundos restantes
    * `{:error, :token_expired}` - Se o token já expirou
    * `{:error, reason}` - Se ocorrer outro erro
  """
  @spec token_expiring?(String.t(), integer()) :: {:ok, integer()} | {:error, any()}
  def token_expiring?(token, threshold_seconds \\ 300) when is_binary(token) do
    case verify_token(token) do
      {:ok, claims} ->
        exp = Map.get(claims, "exp")
        now = DateTime.utc_now() |> DateTime.to_unix()
        seconds_remaining = exp - now
        
        cond do
          seconds_remaining <= 0 ->
            {:error, :token_expired}
            
          seconds_remaining <= threshold_seconds ->
            {:ok, seconds_remaining}
            
          true ->
            {:ok, seconds_remaining}
        end
        
      error -> error
    end
  end
end
