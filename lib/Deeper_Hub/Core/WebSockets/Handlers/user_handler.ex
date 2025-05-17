defmodule Deeper_Hub.Core.WebSockets.Handlers.UserHandler do
  @moduledoc """
  Handler para mensagens relacionadas a usuários.
  
  Este módulo processa operações CRUD para usuários através do WebSocket.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Repositories.UserRepository
  alias Deeper_Hub.Core.Data.DBConnection.Schemas.User
  
  @doc """
  Processa uma mensagem WebSocket relacionada a usuários.
  
  ## Parâmetros
  
    - `action`: Ação a ser executada
    - `payload`: Dados da mensagem
    - `state`: Estado da conexão WebSocket
  
  ## Retorno
  
    - `{:ok, response}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def handle_message(action, payload, state) do
    Logger.debug("Processando mensagem de usuário", %{
      module: __MODULE__,
      action: action,
      user_id: state[:user_id]
    })
    
    case do_handle_message(action, payload, state) do
      {:ok, response} ->
        {:ok, response}
      {:error, reason} ->
        Logger.error("Erro ao processar mensagem de usuário", %{
          module: __MODULE__,
          action: action,
          user_id: state[:user_id],
          error: reason
        })
        
        {:error, %{message: "Erro ao processar mensagem de usuário: #{reason}"}}
    end
  end
  
  # Handlers específicos para cada tipo de ação
  defp do_handle_message("get", %{"id" => id}, _state) when is_binary(id) do
    Logger.info("Buscando usuário via WebSocket", %{
      module: __MODULE__,
      user_id: id
    })
    
    case UserRepository.get_by_id(id) do
      {:ok, user} ->
        # Convertemos o usuário para um mapa sem campos sensíveis
        user_map = %{
          id: user.id,
          username: user.username,
          email: user.email,
          is_active: user.is_active,
          inserted_at: user.inserted_at,
          updated_at: user.updated_at
        }
        
        {:ok, %{
          type: "user.get.response",
          payload: user_map
        }}
        
      {:error, :not_found} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário via WebSocket", %{
          module: __MODULE__,
          user_id: id,
          error: reason
        })
        
        {:error, :database_error}
    end
  end
  
  defp do_handle_message("get", _payload, _state) do
    {:error, :invalid_payload}
  end
  
  # Cria um novo usuário
  defp do_handle_message("create", %{"username" => username, "email" => email, "password" => password}, _state) 
    when is_binary(username) and is_binary(email) and is_binary(password) do
    
    Logger.info("Criando usuário via WebSocket", %{
      module: __MODULE__,
      username: username,
      email: email
    })
    
    # Cria um novo usuário
    user_attrs = %{
      username: username,
      email: email,
      password_hash: password, # Em produção, deveria ser hash
      is_active: true
    }
    
    case User.new(user_attrs) do
      {:ok, user} ->
        case UserRepository.insert(user) do
          {:ok, created_user} ->
            # Convertemos o usuário para um mapa sem campos sensíveis
            user_map = %{
              id: created_user.id,
              username: created_user.username,
              email: created_user.email,
              is_active: created_user.is_active,
              inserted_at: created_user.inserted_at,
              updated_at: created_user.updated_at
            }
            
            {:ok, %{
              type: "user.create.response",
              payload: user_map
            }}
            
          {:error, reason} ->
            Logger.error("Erro ao inserir usuário via WebSocket", %{
              module: __MODULE__,
              username: username,
              email: email,
              error: reason
            })
            
            {:error, :database_error}
        end
        
      {:error, reason} ->
        Logger.error("Erro ao criar usuário via WebSocket", %{
          module: __MODULE__,
          username: username,
          email: email,
          error: reason
        })
        
        {:error, :validation_error}
    end
  end
  
  defp do_handle_message("create", _payload, _state) do
    {:error, :invalid_payload}
  end
  
  # Atualiza um usuário existente
  defp do_handle_message("update", %{"id" => id} = payload, _state) when is_binary(id) do
    Logger.info("Atualizando usuário via WebSocket", %{
      module: __MODULE__,
      user_id: id,
      payload: payload
    })
    
    # Primeiro, buscamos o usuário
    case UserRepository.get_by_id(id) do
      {:ok, user} ->
        # Preparamos os atributos para atualização
        update_attrs = %{}
        
        update_attrs = if Map.has_key?(payload, "username"), 
          do: Map.put(update_attrs, :username, payload["username"]), 
          else: update_attrs
          
        update_attrs = if Map.has_key?(payload, "email"), 
          do: Map.put(update_attrs, :email, payload["email"]), 
          else: update_attrs
          
        update_attrs = if Map.has_key?(payload, "is_active"), 
          do: Map.put(update_attrs, :is_active, payload["is_active"]), 
          else: update_attrs
        
        # Atualizamos o usuário
        case User.update(user, update_attrs) do
          {:ok, updated_user} ->
            case UserRepository.update(updated_user) do
              {:ok, saved_user} ->
                # Convertemos o usuário para um mapa sem campos sensíveis
                user_map = %{
                  id: saved_user.id,
                  username: saved_user.username,
                  email: saved_user.email,
                  is_active: saved_user.is_active,
                  inserted_at: saved_user.inserted_at,
                  updated_at: saved_user.updated_at
                }
                
                {:ok, %{
                  type: "user.update.response",
                  payload: user_map
                }}
                
              {:error, reason} ->
                Logger.error("Erro ao salvar usuário atualizado via WebSocket", %{
                  module: __MODULE__,
                  user_id: id,
                  error: reason
                })
                
                {:error, :database_error}
            end
            
          {:error, reason} ->
            Logger.error("Erro ao atualizar usuário via WebSocket", %{
              module: __MODULE__,
              user_id: id,
              error: reason
            })
            
            {:error, :validation_error}
        end
        
      {:error, :not_found} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário para atualização via WebSocket", %{
          module: __MODULE__,
          user_id: id,
          error: reason
        })
        
        {:error, :database_error}
    end
  end
  
  defp do_handle_message("update", _payload, _state) do
    {:error, :invalid_payload}
  end
  
  # Exclui um usuário
  defp do_handle_message("delete", %{"id" => id}, _state) when is_binary(id) do
    Logger.info("Excluindo usuário via WebSocket", %{
      module: __MODULE__,
      user_id: id
    })
    
    case UserRepository.delete(id) do
      {:ok, deleted_id} ->
        {:ok, %{
          type: "user.delete.response",
          payload: %{
            id: deleted_id,
            deleted: true
          }
        }}
        
      {:error, :not_found} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao excluir usuário via WebSocket", %{
          module: __MODULE__,
          user_id: id,
          error: reason
        })
        
        {:error, :database_error}
    end
  end
  
  defp do_handle_message("delete", _payload, _state) do
    {:error, :invalid_payload}
  end
  
  # Ação desconhecida
  defp do_handle_message(action, _payload, _state) do
    {:error, "Ação desconhecida: #{action}"}
  end
end
