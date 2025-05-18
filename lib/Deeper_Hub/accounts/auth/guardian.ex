defmodule DeeperHub.Accounts.Auth.Guardian do
  @moduledoc """
  Implementação do Guardian para autenticação JWT no DeeperHub.
  
  Este módulo é responsável por gerenciar tokens JWT para autenticação
  de usuários, incluindo geração, validação e revogação de tokens.
  """
  use Guardian, otp_app: :deeper_hub

  alias DeeperHub.Accounts.User
  alias DeeperHub.Core.Logger
  require DeeperHub.Core.Logger

  @doc """
  Função chamada pelo Guardian para buscar o recurso associado a um token.
  Recebe o subject do token e retorna o recurso correspondente.
  """
  def subject_for_token(user, _claims) when is_map(user) do
    # Extrai o ID do usuário do mapa
    sub = to_string(user["id"] || user[:id])
    {:ok, sub}
  end

  def subject_for_token(_, _) do
    {:error, :invalid_resource}
  end

  @doc """
  Função chamada pelo Guardian para converter um subject de token em um recurso.
  Recebe o subject e retorna o recurso correspondente.
  """
  def resource_from_claims(%{"sub" => sub}) do
    case User.get(sub) do
      {:ok, user} -> {:ok, user}
      {:error, :not_found} -> {:error, :resource_not_found}
      {:error, reason} -> 
        Logger.error("Erro ao buscar usuário para claims: #{inspect(reason)}", module: __MODULE__)
        {:error, :resource_error}
    end
  end

  def resource_from_claims(_claims) do
    {:error, :invalid_claims}
  end

  @doc """
  Gera um token de acesso para um usuário.
  """
  def generate_access_token(user) do
    encode_and_sign(user, %{}, token_options(:access))
  end

  @doc """
  Gera um token de atualização (refresh token) para um usuário.
  """
  def generate_refresh_token(user) do
    encode_and_sign(user, %{}, token_options(:refresh))
  end

  @doc """
  Verifica se um token é válido.
  """
  def verify_token(token) do
    decode_and_verify(token)
  end

  @doc """
  Revoga um token.
  """
  def revoke_token(token) do
    revoke(token)
  end

  # Configurações para diferentes tipos de tokens
  defp token_options(:access) do
    [
      token_type: "access",
      ttl: {1, :hour}
    ]
  end

  defp token_options(:refresh) do
    [
      token_type: "refresh",
      ttl: {30, :days}
    ]
  end
end
