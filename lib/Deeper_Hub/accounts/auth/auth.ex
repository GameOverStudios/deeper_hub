defmodule DeeperHub.Accounts.Auth do
  @moduledoc """
  Contexto de autenticação para o DeeperHub.
  
  Este módulo fornece funções para autenticação de usuários,
  gerenciamento de senhas e tokens de acesso.
  """

  alias DeeperHub.Accounts.User
  alias DeeperHub.Accounts.Auth.Guardian
  alias DeeperHub.Core.Data.Repo

  @doc """
  Registra um novo usuário no sistema.
  
  ## Parâmetros
    * `attrs` - Mapa contendo os atributos do usuário (nome, email, senha, etc.)
  
  ## Exemplos
      iex> register_user(%{name: "João Silva", email: "joao@exemplo.com", password: "senha123"})
      {:ok, %User{}}
      
      iex> register_user(%{email: "email_invalido"})
      {:error, %Ecto.Changeset{}}
  """
  def register_user(attrs) do
    %User{}
    |> User.registration_changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Autentica um usuário com email e senha.
  
  ## Parâmetros
    * `email` - Email do usuário
    * `password` - Senha do usuário
  
  ## Retorno
    * `{:ok, user}` - Se a autenticação for bem-sucedida
    * `{:error, :invalid_credentials}` - Se as credenciais forem inválidas
  
  ## Exemplos
      iex> authenticate_user("joao@exemplo.com", "senha123")
      {:ok, %User{}}
      
      iex> authenticate_user("joao@exemplo.com", "senha_errada")
      {:error, :invalid_credentials}
  """
  def authenticate_user(email, password) do
    case DeeperHub.Accounts.get_user_by_email(email) do
      nil ->
        # Executa uma verificação de senha falsa para evitar timing attacks
        Argon2.no_user_verify()
        {:error, :invalid_credentials}
      
      user ->
        verify_password(user, password)
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

  # Funções privadas

  # Verifica se a senha fornecida corresponde à senha armazenada do usuário
  defp verify_password(user, password) do
    if Argon2.verify_pass(password, user.password_hash) do
      {:ok, user}
    else
      {:error, :invalid_credentials}
    end
  end
end
