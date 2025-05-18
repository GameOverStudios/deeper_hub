defmodule Deeper_Hub.Factory do
  @moduledoc """
  Factory para criação de dados de teste usando ExMachina.
  
  Este módulo define factories para criar estruturas de dados para testes,
  facilitando a criação de dados consistentes e realistas.
  """
  
  # Usando ExMachina sem Ecto
  use ExMachina
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Factory para usuários.
  
  ## Retorno
  
    - Mapa representando um usuário
  """
  def user_factory do
    %{
      id: sequence(:id, &"user_#{&1}"),
      username: sequence(:username, &"user#{&1}"),
      email: sequence(:email, &"user#{&1}@example.com"),
      password_hash: "$2b$12$k9bUzimRXFDgAWk6nSZOZ.RPaU0.zY/WBtQJX5t2VJwGOsRyr2tLW", # "password123"
      first_name: "Test",
      last_name: "User",
      active: true,
      role: "user",
      inserted_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      updated_at: DateTime.utc_now() |> DateTime.to_iso8601()
    }
  end
  
  @doc """
  Factory para administradores.
  
  ## Retorno
  
    - Mapa representando um administrador
  """
  def admin_factory do
    user_factory()
    |> Map.put(:role, "admin")
  end
  
  @doc """
  Factory para entradas de cache.
  
  ## Retorno
  
    - Mapa representando uma entrada de cache
  """
  def cache_entry_factory do
    %{
      key: sequence(:cache_key, &"cache_key_#{&1}"),
      value: %{data: "cached_data"},
      inserted_at: DateTime.utc_now() |> DateTime.to_iso8601(),
      ttl: 600 # 10 minutos em segundos
    }
  end
  
  @doc """
  Factory para tokens JWT.
  
  ## Retorno
  
    - Mapa representando um token JWT
  """
  def jwt_token_factory do
    user = build(:user)
    
    %{
      user_id: user.id,
      token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiI#{user.id}",
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second),
      type: "access",
      metadata: %{ip_address: "127.0.0.1", user_agent: "Mozilla/5.0"}
    }
  end
  
  @doc """
  Factory para tokens opacos.
  
  ## Retorno
  
    - Mapa representando um token opaco
  """
  def opaque_token_factory do
    user = build(:user)
    
    %{
      token: sequence(:token, &"opaque_token_#{&1}"),
      purpose: :password_reset,
      identifier: user.id,
      expires_at: DateTime.utc_now() |> DateTime.add(3600, :second),
      metadata: %{},
      created_at: DateTime.utc_now()
    }
  end
  
  @doc """
  Factory para sessões de usuário.
  
  ## Retorno
  
    - Mapa representando uma sessão de usuário
  """
  def session_factory do
    user = build(:user)
    
    %{
      id: sequence(:session_id, &"session_#{&1}"),
      user_id: user.id,
      access_token: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiI#{user.id}",
      refresh_token: "refresh_#{sequence(:refresh_token, &"token_#{&1}")}",
      expires_at: DateTime.utc_now() |> DateTime.add(86400, :second),
      last_activity: DateTime.utc_now(),
      metadata: %{
        ip_address: "127.0.0.1",
        user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
      },
      created_at: DateTime.utc_now()
    }
  end
  
  @doc """
  Função personalizada para inserir um usuário no banco de dados.
  
  ## Parâmetros
  
    - `attrs`: Atributos adicionais ou substituições
  
  ## Retorno
  
    - `{:ok, user}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def insert_user(attrs \\ []) do
    user = build(:user, attrs)
    
    # Aqui usamos a API do módulo User para inserir no banco
    try do
      # Esta é uma implementação simulada, você precisaria adaptar para a API real
      Logger.info("Inserindo usuário de teste no banco de dados", %{
        module: __MODULE__,
        user: user
      })
      
      # Simulando uma inserção bem-sucedida
      {:ok, user}
    rescue
      e ->
        Logger.error("Erro ao inserir usuário de teste", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Função personalizada para inserir uma entrada no cache.
  
  ## Parâmetros
  
    - `attrs`: Atributos adicionais ou substituições
  
  ## Retorno
  
    - `{:ok, true}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def insert_cache_entry(attrs \\ []) do
    entry = build(:cache_entry, attrs)
    
    # Usamos a API do módulo Cache para inserir no cache
    Deeper_Hub.Core.Cache.put(entry.key, entry.value, entry.ttl)
  end
end
