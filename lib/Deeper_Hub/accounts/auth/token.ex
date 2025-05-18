defmodule DeeperHub.Accounts.Auth.Token do
  @moduledoc """
  Módulo para gerenciamento de tokens JWT no DeeperHub.
  
  Este módulo fornece funções auxiliares para trabalhar com tokens JWT,
  incluindo geração, validação e extração de informações.
  """

  alias DeeperHub.Accounts.Auth.Guardian

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
end
