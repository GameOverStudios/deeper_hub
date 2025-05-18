defmodule Deeper_Hub.Core.WebSockets.Auth.Token.TokenRotationService do
  @moduledoc """
  Serviço para rotação de tokens de refresh.
  
  Este módulo gerencia a rotação de tokens de refresh, garantindo
  que tokens antigos sejam invalidados quando novos são gerados.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.WebSockets.Auth.JwtService
  alias Deeper_Hub.Core.WebSockets.Auth.Session.SessionPolicy
  
  @doc """
  Rotaciona um par de tokens.
  
  ## Parâmetros
  
    - `refresh_token`: Token de refresh atual
    
  ## Retorno
  
    - `{:ok, new_tokens, updated_session}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def rotate_tokens(refresh_token) do
    with {:ok, claims} <- JwtService.verify_token(refresh_token),
         "refresh" <- Map.get(claims, "typ"),
         user_id = Map.get(claims, "user_id"),
         session_id = Map.get(claims, "session_id"),
         remember_me = Map.get(claims, "remember_me", false) do
      
      # Revoga o token de refresh antigo
      JwtService.revoke_token(refresh_token)
      
      # Determina o tempo de expiração com base na política
      token_expiry = if remember_me do
        SessionPolicy.remember_me_expiry()
      else
        SessionPolicy.refresh_token_expiry()
      end
      
      # Gera novos tokens
      case JwtService.generate_token_pair(user_id, token_expiry, %{
        "session_id" => session_id,
        "remember_me" => remember_me
      }) do
        {:ok, access_token, new_refresh_token, claims} ->
          # Atualiza a sessão com os novos tokens
          update_session_tokens(session_id, access_token, new_refresh_token)
          
          # Constrói a resposta
          tokens = %{
            access_token: access_token,
            refresh_token: new_refresh_token,
            expires_in: Map.get(claims.access, "exp") - Map.get(claims.access, "iat")
          }
          
          {:ok, tokens}
          
        error ->
          Logger.error("Erro ao gerar novos tokens durante rotação", %{
            module: __MODULE__,
            user_id: user_id,
            error: error
          })
          
          {:error, :token_generation_failed}
      end
    else
      "access" ->
        Logger.warning("Tentativa de rotação com token de acesso", %{
          module: __MODULE__
        })
        
        {:error, :invalid_token_type}
        
      {:error, :token_blacklisted} ->
        Logger.warning("Tentativa de rotação com token revogado", %{
          module: __MODULE__
        })
        
        {:error, :token_revoked}
        
      {:error, reason} ->
        Logger.error("Erro ao verificar token durante rotação", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, :invalid_token}
        
      nil ->
        Logger.error("Token de refresh sem tipo durante rotação", %{
          module: __MODULE__
        })
        
        {:error, :invalid_token}
    end
  end
  
  # Atualiza os tokens de uma sessão
  defp update_session_tokens(session_id, access_token, refresh_token) do
    # Em uma implementação real, isso atualizaria a sessão no banco de dados
    # Para esta implementação em memória, tentamos atualizar na tabela ETS
    
    case :ets.lookup(:sessions, session_id) do
      [{^session_id, session}] ->
        updated_session = %{session | 
          access_token: access_token, 
          refresh_token: refresh_token,
          last_activity: DateTime.utc_now()
        }
        
        :ets.insert(:sessions, {session_id, updated_session})
        
      [] ->
        Logger.warning("Tentativa de atualizar tokens para sessão inexistente", %{
          module: __MODULE__,
          session_id: session_id
        })
    end
  end
end
