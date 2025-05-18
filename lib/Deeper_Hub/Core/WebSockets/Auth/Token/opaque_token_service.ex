defmodule Deeper_Hub.Core.WebSockets.Auth.Token.OpaqueTokenService do
  @moduledoc """
  Serviço para gerenciamento de tokens opacos.
  
  Este módulo fornece funções para criar, verificar e revogar tokens opacos
  usados para operações específicas como recuperação de senha, verificação de email
  e tokens de API.
  """
  
  alias Deeper_Hub.Core.Logger
  
  # Duração padrão dos tokens por finalidade (em segundos)
  @default_expiry %{
    password_reset: 3600,        # 1 hora
    email_verification: 86400,   # 24 horas
    api: 2_592_000               # 30 dias
  }
  
  # Comprimento do token
  @token_length 32
  
  @doc """
  Gera um token opaco para uma finalidade específica.
  
  ## Parâmetros
  
    - `purpose`: Finalidade do token (`:password_reset`, `:email_verification`, `:api`)
    - `identifier`: Identificador associado ao token (geralmente user_id)
    - `expiry`: Tempo de expiração em segundos (opcional)
    - `metadata`: Metadados adicionais (opcional)
    
  ## Retorno
  
    - `{:ok, token, expires_at}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def generate_token(purpose, identifier, expiry \\ nil, metadata \\ %{}) do
    # Valida a finalidade
    if not (purpose in [:password_reset, :email_verification, :api]) do
      Logger.error("Finalidade de token inválida", %{
        module: __MODULE__,
        purpose: purpose
      })
      
      {:error, :invalid_purpose}
    else
      # Determina o tempo de expiração
      expiry_seconds = expiry || Map.get(@default_expiry, purpose)
      expires_at = DateTime.utc_now() |> DateTime.add(expiry_seconds, :second)
      
      # Gera um token aleatório
      token = generate_random_token()
      
      # Cria o registro do token
      token_data = %{
        purpose: purpose,
        identifier: identifier,
        expires_at: expires_at,
        metadata: metadata,
        created_at: DateTime.utc_now()
      }
      
      # Armazena o token
      :ets.insert(:opaque_tokens, {token, token_data})
      
      Logger.info("Token opaco gerado", %{
        module: __MODULE__,
        purpose: purpose,
        identifier: identifier
      })
      
      {:ok, token, expires_at}
    end
  end
  
  @doc """
  Verifica um token opaco.
  
  ## Parâmetros
  
    - `token`: Token opaco a ser verificado
    - `purpose`: Finalidade esperada do token
    
  ## Retorno
  
    - `{:ok, data}` em caso de sucesso, onde `data` contém o identificador e metadados
    - `{:error, reason}` em caso de falha
  """
  def verify_token(token, purpose) do
    case :ets.lookup(:opaque_tokens, token) do
      [{^token, token_data}] ->
        # Verifica a finalidade
        if token_data.purpose != purpose do
          Logger.warning("Tentativa de usar token com finalidade incorreta", %{
            module: __MODULE__,
            expected: purpose,
            actual: token_data.purpose
          })
          
          {:error, :invalid_purpose}
        else
          # Verifica a expiração
          now = DateTime.utc_now()
          
          if DateTime.compare(token_data.expires_at, now) == :lt do
            Logger.warning("Tentativa de usar token expirado", %{
              module: __MODULE__,
              purpose: purpose,
              identifier: token_data.identifier
            })
            
            # Remove o token expirado
            :ets.delete(:opaque_tokens, token)
            
            {:error, :token_expired}
          else
            # Token válido
            data = %{
              identifier: token_data.identifier,
              metadata: token_data.metadata,
              created_at: token_data.created_at
            }
            
            {:ok, data}
          end
        end
        
      [] ->
        Logger.warning("Tentativa de verificar token inexistente", %{
          module: __MODULE__,
          purpose: purpose
        })
        
        {:error, :invalid_token}
    end
  end
  
  @doc """
  Revoga um token opaco.
  
  ## Parâmetros
  
    - `token`: Token opaco a ser revogado
    
  ## Retorno
  
    - `:ok` em caso de sucesso
    - `{:error, :not_found}` se o token não existir
  """
  def revoke_token(token) do
    case :ets.lookup(:opaque_tokens, token) do
      [{^token, _}] ->
        :ets.delete(:opaque_tokens, token)
        :ok
        
      [] ->
        {:error, :not_found}
    end
  end
  
  @doc """
  Revoga todos os tokens opacos para um identificador e finalidade específicos.
  
  ## Parâmetros
  
    - `identifier`: Identificador associado aos tokens
    - `purpose`: Finalidade dos tokens a serem revogados
    
  ## Retorno
  
    - `:ok` em caso de sucesso
  """
  def revoke_all_tokens(identifier, purpose) do
    # Obtém todos os tokens
    all_tokens = :ets.tab2list(:opaque_tokens)
    
    # Filtra tokens pelo identificador e finalidade
    tokens_to_revoke = Enum.filter(all_tokens, fn {_token, data} ->
      data.identifier == identifier && data.purpose == purpose
    end)
    
    # Revoga os tokens
    Enum.each(tokens_to_revoke, fn {token, _} ->
      :ets.delete(:opaque_tokens, token)
    end)
    
    # Registra a revogação
    count = length(tokens_to_revoke)
    
    if count > 0 do
      Logger.info("Tokens opacos revogados", %{
        module: __MODULE__,
        purpose: purpose,
        identifier: identifier,
        count: count
      })
    end
    
    :ok
  end
  
  @doc """
  Limpa tokens opacos expirados.
  
  ## Retorno
  
    - Número de tokens removidos
  """
  def cleanup_expired_tokens do
    # Obtém todos os tokens
    all_tokens = :ets.tab2list(:opaque_tokens)
    now = DateTime.utc_now()
    
    # Filtra tokens expirados
    expired_tokens = Enum.filter(all_tokens, fn {_token, data} ->
      DateTime.compare(data.expires_at, now) == :lt
    end)
    
    # Remove tokens expirados
    Enum.each(expired_tokens, fn {token, _} ->
      :ets.delete(:opaque_tokens, token)
    end)
    
    # Registra a limpeza
    count = length(expired_tokens)
    
    if count > 0 do
      Logger.info("Tokens opacos expirados removidos", %{
        module: __MODULE__,
        count: count
      })
    end
    
    count
  end
  
  @doc """
  Inicializa o armazenamento de tokens opacos.
  
  ## Retorno
  
    - `:ok`
  """
  def init do
    # Cria a tabela ETS se não existir
    if :ets.whereis(:opaque_tokens) == :undefined do
      :ets.new(:opaque_tokens, [:set, :public, :named_table])
    end
    
    :ok
  end
  
  # Funções privadas
  
  # Gera um token aleatório
  defp generate_random_token do
    :crypto.strong_rand_bytes(@token_length)
    |> Base.url_encode64(padding: false)
  end
end
