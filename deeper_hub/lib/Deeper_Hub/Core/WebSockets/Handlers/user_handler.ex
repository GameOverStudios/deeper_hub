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
      {:error, %{type: type, payload: payload}} when is_map(payload) ->
        Logger.error("Erro ao processar mensagem de usuário", %{
          module: __MODULE__,
          action: action,
          user_id: state[:user_id],
          error_type: type
        })
        
        # Retornamos o erro estruturado diretamente
        {:error, %{message: "Erro ao processar mensagem de usuário", type: type, payload: payload}}
        
      {:error, reason} ->
        Logger.error("Erro ao processar mensagem de usuário", %{
          module: __MODULE__,
          action: action,
          user_id: state[:user_id],
          error: reason
        })
        
        # Convertemos o erro para string de forma segura
        error_message = cond do
          is_binary(reason) -> reason
          is_atom(reason) -> Atom.to_string(reason)
          true -> inspect(reason)
        end
        
        {:error, %{message: "Erro ao processar mensagem de usuário: #{error_message}"}}
    end
  end
  
  # Handlers específicos para cada tipo de ação
  defp do_handle_message("get", %{"user_id" => user_id}, _state) when is_binary(user_id) do
    Logger.info("Buscando usuário via WebSocket", %{
      module: __MODULE__,
      user_id: user_id
    })
    
    case UserRepository.get_by_id(user_id) do
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
          type: "user.get.success",
          payload: user_map
        }}
        
      {:error, :not_found} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário via WebSocket", %{
          module: __MODULE__,
          user_id: user_id,
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
      password_hash: password, # Armazenamos a senha diretamente para manter compatibilidade com AuthService
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
              type: "user.create.success",
              payload: user_map
            }}
            
          {:error, %DBConnection.ConnectionError{reason: "UNIQUE constraint failed: users.username"}} ->
            Logger.error("Erro ao inserir usuário via WebSocket: nome de usuário já existe", %{
              module: __MODULE__,
              username: username,
              email: email
            })
            
            {:error, %{
              type: "user.create.error",
              payload: %{
                error: "username_already_exists",
                message: "O nome de usuário já está em uso"
              }
            }}
            
          {:error, %DBConnection.ConnectionError{reason: "UNIQUE constraint failed: users.email"}} ->
            Logger.error("Erro ao inserir usuário via WebSocket: email já existe", %{
              module: __MODULE__,
              username: username,
              email: email
            })
            
            {:error, %{
              type: "user.create.error",
              payload: %{
                error: "email_already_exists",
                message: "O email já está em uso"
              }
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
  defp do_handle_message("update", %{"user_id" => user_id} = payload, _state) when is_binary(user_id) do
    Logger.info("Atualizando usuário via WebSocket", %{
      module: __MODULE__,
      user_id: user_id,
      payload: payload
    })
    
    # Primeiro, buscamos o usuário
    case UserRepository.get_by_id(user_id) do
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
                  type: "user.update.success",
                  payload: user_map
                }}
                
              {:error, reason} ->
                Logger.error("Erro ao salvar usuário atualizado via WebSocket", %{
                  module: __MODULE__,
                  user_id: user_id,
                  error: reason
                })
                
                {:error, :database_error}
            end
            
          {:error, reason} ->
            Logger.error("Erro ao atualizar usuário via WebSocket", %{
              module: __MODULE__,
              user_id: user_id,
              error: reason
            })
            
            {:error, :validation_error}
        end
        
      {:error, :not_found} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário para atualização via WebSocket", %{
          module: __MODULE__,
          user_id: user_id,
          error: reason
        })
        
        {:error, :database_error}
    end
  end
  
  defp do_handle_message("update", _payload, _state) do
    {:error, :invalid_payload}
  end
  
  # Exclui um usuário
  defp do_handle_message("delete", %{"user_id" => user_id}, _state) when is_binary(user_id) do
    Logger.info("Excluindo usuário via WebSocket", %{
      module: __MODULE__,
      user_id: user_id
    })
    
    case UserRepository.delete(user_id) do
      {:ok, deleted_id} ->
        {:ok, %{
          type: "user.delete.success",
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
          user_id: user_id,
          error: reason
        })
        
        {:error, :database_error}
    end
  end
  
  defp do_handle_message("delete", _payload, _state) do
    {:error, :invalid_payload}
  end
  
  # Altera a senha de um usuário
  defp do_handle_message("change_password", %{"username" => username, "password" => password}, _state) 
    when is_binary(username) and is_binary(password) do
    
    Logger.info("Alterando senha de usuário via WebSocket", %{
      module: __MODULE__,
      username: username
    })
    
    # Busca o usuário pelo nome de usuário
    case UserRepository.get_by_username(username) do
      {:ok, user} ->
        # Atualiza a senha
        updated_user = Map.put(user, :password_hash, password)
        
        case UserRepository.update(updated_user) do
          {:ok, _} ->
            {:ok, %{
              type: "user.change_password.success",
              payload: %{
                message: "Senha alterada com sucesso",
                username: username
              }
            }}
            
          {:error, reason} ->
            Logger.error("Erro ao atualizar senha do usuário via WebSocket", %{
              module: __MODULE__,
              username: username,
              error: reason
            })
            
            {:error, :database_error}
        end
        
      {:error, :not_found} ->
        {:error, :user_not_found}
        
      {:error, reason} ->
        Logger.error("Erro ao buscar usuário para alterar senha via WebSocket", %{
          module: __MODULE__,
          username: username,
          error: reason
        })
        
        {:error, :database_error}
    end
  end
  
  defp do_handle_message("change_password", _payload, _state) do
    {:error, :invalid_payload}
  end

  # Lista todos os usuários
  defp do_handle_message("list", _payload, _state) do
    Logger.info("Listando usuários via WebSocket", %{
      module: __MODULE__
    })
    
    case UserRepository.list() do
      {:ok, users} ->
        # Convertemos os usuários para mapas sem campos sensíveis
        users_list = Enum.map(users, fn user ->
          %{
            id: user.id,
            username: user.username,
            email: user.email,
            is_active: user.is_active,
            inserted_at: user.inserted_at,
            updated_at: user.updated_at
          }
        end)
        
        {:ok, %{
          type: "user.list.success",
          payload: %{
            users: users_list,
            count: length(users_list)
          }
        }}
        
      {:error, reason} ->
        Logger.error("Erro ao listar usuários via WebSocket", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, :database_error}
    end
  end

  # Ação desconhecida
  defp do_handle_message(action, _payload, _state) do
    {:error, "Ação desconhecida: #{action}"}
  end
end
