defmodule Deeper_Hub.Core.Data.DBConnection.Migrations do
  @moduledoc """
  Gerenciamento de migrações para o banco de dados SQLite usando DBConnection.
  
  Este módulo é responsável por executar as migrações necessárias para
  criar e atualizar as tabelas do banco de dados, mantendo compatibilidade
  com o sistema de migrações do Ecto.
  """
  
  alias Deeper_Hub.Core.Logger
  alias Deeper_Hub.Core.Data.DBConnection.Facade, as: DB
  
  @migrations_table "schema_migrations"
  
  @doc """
  Executa todas as migrações pendentes.
  
  ## Retorno
  
    - `:ok` se todas as migrações forem executadas com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec run_migrations() :: :ok | {:error, term()}
  def run_migrations() do
    try do
      # Registra o início das migrações
      Logger.info("Iniciando execução de migrações", %{module: __MODULE__})
      
      # Garante que a tabela de migrações existe
      :ok = ensure_migrations_table()
      
      # Obtém todas as migrações disponíveis
      available_migrations = get_available_migrations()
      
      # Obtém as migrações já aplicadas
      {:ok, applied_migrations} = get_applied_migrations()
      
      # Filtra as migrações pendentes
      pending_migrations = Enum.filter(available_migrations, fn {version, _} ->
        !Enum.member?(applied_migrations, version)
      end)
      
      # Ordena as migrações pendentes por versão
      pending_migrations = Enum.sort_by(pending_migrations, fn {version, _} -> version end)
      
      # Executa as migrações pendentes
      Enum.each(pending_migrations, fn {version, migration_module} ->
        Logger.info("Executando migração #{version}", %{
          module: __MODULE__,
          version: version,
          migration_module: migration_module
        })
        
        # Executa a migração dentro de uma transação
        case DB.transaction(fn _conn ->
          # Executa a função up da migração
          apply(migration_module, :up, [])
          
          # Registra a migração na tabela de migrações
          query = "INSERT INTO #{@migrations_table} (version, inserted_at) VALUES (?, ?)"
          now = DateTime.utc_now() |> DateTime.to_string()
          DB.query(query, [version, now])
        end) do
          {:ok, _} ->
            Logger.info("Migração #{version} executada com sucesso", %{
              module: __MODULE__,
              version: version
            })
          {:error, reason} ->
            Logger.error("Falha ao executar migração #{version}", %{
              module: __MODULE__,
              version: version,
              error: reason
            })
            
            # Interrompe a execução das migrações
            throw({:error, reason})
        end
      end)
      
      # Registra o sucesso das migrações
      Logger.info("Migrações executadas com sucesso", %{module: __MODULE__})
      
      :ok
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao executar migrações", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    catch
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Reverte a última migração executada.
  
  ## Retorno
  
    - `:ok` se a migração for revertida com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec rollback() :: :ok | {:error, term()}
  def rollback do
    try do
      # Registra o início do rollback
      Logger.info("Iniciando rollback da última migração", %{module: __MODULE__})
      
      # Obtém a última migração aplicada
      {:ok, applied_migrations} = get_applied_migrations()
      
      case List.last(applied_migrations) do
        nil ->
          Logger.info("Nenhuma migração para reverter", %{module: __MODULE__})
          :ok
        last_version ->
          # Obtém o módulo da migração
          migration_module = find_migration_module(last_version)
          
          # Executa o rollback dentro de uma transação
          case DB.transaction(fn _conn ->
            # Executa a função down da migração
            apply(migration_module, :down, [])
            
            # Remove a migração da tabela de migrações
            query = "DELETE FROM #{@migrations_table} WHERE version = ?"
            DB.query(query, [last_version])
          end) do
            {:ok, _} ->
              Logger.info("Rollback da migração #{last_version} executado com sucesso", %{
                module: __MODULE__,
                version: last_version
              })
              
              :ok
            {:error, reason} ->
              Logger.error("Falha ao executar rollback da migração #{last_version}", %{
                module: __MODULE__,
                version: last_version,
                error: reason
              })
              
              {:error, reason}
          end
      end
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao executar rollback", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Reverte um número específico de migrações.
  
  ## Parâmetros
  
    - `step`: Número de migrações a serem revertidas
  
  ## Retorno
  
    - `:ok` se as migrações forem revertidas com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec rollback_migrations(integer()) :: :ok | {:error, term()}
  def rollback_migrations(step) do
    try do
      # Registra o início do rollback
      Logger.info("Iniciando rollback de #{step} migrações", %{module: __MODULE__, step: step})
      
      # Obtém as migrações aplicadas
      {:ok, applied_migrations} = get_applied_migrations()
      
      # Obtém as migrações a serem revertidas
      migrations_to_rollback = Enum.take(Enum.reverse(applied_migrations), step)
      
      # Reverte cada migração
      Enum.each(migrations_to_rollback, fn version ->
        # Obtém o módulo da migração
        migration_module = find_migration_module(version)
        
        # Executa o rollback dentro de uma transação
        case DB.transaction(fn _conn ->
          # Executa a função down da migração
          apply(migration_module, :down, [])
          
          # Remove a migração da tabela de migrações
          query = "DELETE FROM #{@migrations_table} WHERE version = ?"
          DB.query(query, [version])
        end) do
          {:ok, _} ->
            Logger.info("Rollback da migração #{version} executado com sucesso", %{
              module: __MODULE__,
              version: version
            })
          {:error, reason} ->
            Logger.error("Falha ao executar rollback da migração #{version}", %{
              module: __MODULE__,
              version: version,
              error: reason
            })
            
            # Interrompe a execução do rollback
            throw({:error, reason})
        end
      end)
      
      # Registra o sucesso do rollback
      Logger.info("Rollback de #{length(migrations_to_rollback)} migrações executado com sucesso", %{
        module: __MODULE__,
        step: step
      })
      
      :ok
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao executar rollback de #{step} migrações", %{
          module: __MODULE__,
          step: step,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    catch
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Reverte e reaplicada todas as migrações.
  
  ## Retorno
  
    - `:ok` se as migrações forem revertidas e reaplicadas com sucesso
    - `{:error, reason}` em caso de falha
  """
  @spec reset_migrations() :: :ok | {:error, term()}
  def reset_migrations() do
    try do
      # Registra o início do reset
      Logger.info("Iniciando reset de todas as migrações", %{module: __MODULE__})
      
      # Obtém as migrações aplicadas
      {:ok, applied_migrations} = get_applied_migrations()
      
      # Reverte todas as migrações aplicadas
      Enum.each(Enum.reverse(applied_migrations), fn version ->
        # Obtém o módulo da migração
        migration_module = find_migration_module(version)
        
        # Executa o rollback dentro de uma transação
        case DB.transaction(fn _conn ->
          # Executa a função down da migração
          apply(migration_module, :down, [])
          
          # Remove a migração da tabela de migrações
          query = "DELETE FROM #{@migrations_table} WHERE version = ?"
          DB.query(query, [version])
        end) do
          {:ok, _} ->
            Logger.info("Rollback da migração #{version} executado com sucesso", %{
              module: __MODULE__,
              version: version
            })
          {:error, reason} ->
            Logger.error("Falha ao executar rollback da migração #{version}", %{
              module: __MODULE__,
              version: version,
              error: reason
            })
            
            # Interrompe a execução do reset
            throw({:error, reason})
        end
      end)
      
      # Executa todas as migrações novamente
      case run_migrations() do
        :ok ->
          # Registra o sucesso do reset
          Logger.info("Reset de migrações executado com sucesso", %{module: __MODULE__})
          
          :ok
        {:error, reason} ->
          Logger.error("Falha ao reaplicar migrações após reset", %{
            module: __MODULE__,
            error: reason
          })
          
          {:error, reason}
      end
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao executar reset de migrações", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    catch
      {:error, reason} ->
        {:error, reason}
    end
  end
  
  @doc """
  Verifica se todas as migrações foram aplicadas.
  
  ## Retorno
  
    - `:ok` se todas as migrações foram aplicadas
    - `{:error, :pending_migrations}` se existem migrações pendentes
    - `{:error, reason}` em caso de falha
  """
  @spec verify_migrations() :: :ok | {:error, term()}
  def verify_migrations() do
    try do
      # Registra o início da verificação
      Logger.info("Verificando status das migrações", %{module: __MODULE__})
      
      # Obtém todas as migrações disponíveis
      available_migrations = get_available_migrations()
      
      # Obtém as migrações já aplicadas
      {:ok, applied_migrations} = get_applied_migrations()
      
      # Filtra as migrações pendentes
      pending_migrations = Enum.filter(available_migrations, fn {version, _} ->
        !Enum.member?(applied_migrations, version)
      end)
      
      # Verifica se todas as migrações foram aplicadas
      if Enum.empty?(pending_migrations) do
        Logger.info("Todas as migrações foram aplicadas", %{module: __MODULE__})
        :ok
      else
        pending_count = length(pending_migrations)
        Logger.info("Existem #{pending_count} migrações pendentes", %{
          module: __MODULE__,
          pending_count: pending_count
        })
        
        {:error, :pending_migrations}
      end
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao verificar status das migrações", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  @doc """
  Obtém o status de todas as migrações.
  
  ## Retorno
  
    - `{:ok, [{version, status}]}` contendo o status de cada migração
    - `{:error, reason}` em caso de falha
  """
  @spec get_migration_status() :: {:ok, list({String.t(), atom()})} | {:error, term()}
  def get_migration_status() do
    try do
      # Registra o início da obtenção do status
      Logger.info("Obtendo status das migrações", %{module: __MODULE__})
      
      # Obtém todas as migrações disponíveis
      available_migrations = get_available_migrations()
      
      # Obtém as migrações já aplicadas
      {:ok, applied_migrations} = get_applied_migrations()
      
      # Gera o status de cada migração
      migration_status = Enum.map(available_migrations, fn {version, _} ->
        status = if Enum.member?(applied_migrations, version), do: :up, else: :down
        {version, status}
      end)
      
      # Ordena o status por versão
      migration_status = Enum.sort_by(migration_status, fn {version, _} -> version end)
      
      {:ok, migration_status}
    rescue
      e ->
        # Registra o erro
        Logger.error("Falha ao obter status das migrações", %{
          module: __MODULE__,
          error: e,
          stacktrace: __STACKTRACE__
        })
        
        {:error, e}
    end
  end
  
  # Funções privadas
  
  # Garante que a tabela de migrações existe
  defp ensure_migrations_table() do
    # Verifica se a tabela de migrações existe
    query = """
    SELECT name FROM sqlite_master
    WHERE type='table' AND name='#{@migrations_table}'
    """
    
    case DB.query(query, []) do
      {:ok, %{rows: []}} ->
        # Cria a tabela de migrações
        create_query = """
        CREATE TABLE #{@migrations_table} (
          version TEXT PRIMARY KEY,
          inserted_at TEXT NOT NULL
        )
        """
        
        case DB.query(create_query, []) do
          {:ok, _} ->
            Logger.info("Tabela de migrações criada com sucesso", %{module: __MODULE__})
            :ok
          {:error, reason} ->
            Logger.error("Falha ao criar tabela de migrações", %{
              module: __MODULE__,
              error: reason
            })
            
            {:error, reason}
        end
      {:ok, _} ->
        # A tabela já existe
        :ok
      {:error, reason} ->
        Logger.error("Falha ao verificar existência da tabela de migrações", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  # Obtém todas as migrações disponíveis
  defp get_available_migrations() do
    # Obtém todos os módulos de migração
    migration_modules = :code.all_loaded()
    |> Enum.filter(fn {module, _} ->
      module_name = Atom.to_string(module)
      String.contains?(module_name, "Migration")
    end)
    |> Enum.map(fn {module, _} -> module end)
    
    # Extrai a versão de cada módulo de migração
    Enum.map(migration_modules, fn module ->
      # A versão está no nome do módulo (ex: Migration20220101120000)
      module_name = Atom.to_string(module)
      version = case Regex.run(~r/\d{14}/, module_name) do
        nil -> nil
        matches -> List.first(matches)
      end
      
      {version, module}
    end)
    |> Enum.filter(fn {version, _} -> version != nil end)
  end
  
  # Obtém as migrações já aplicadas
  defp get_applied_migrations() do
    query = "SELECT version FROM #{@migrations_table} ORDER BY version"
    
    case DB.query(query, []) do
      {:ok, %{rows: rows}} ->
        # Extrai as versões das linhas
        versions = Enum.map(rows, fn [version] -> version end)
        {:ok, versions}
      {:error, reason} ->
        Logger.error("Falha ao obter migrações aplicadas", %{
          module: __MODULE__,
          error: reason
        })
        
        {:error, reason}
    end
  end
  
  # Encontra o módulo de migração para uma versão específica
  defp find_migration_module(version) do
    # Obtém todos os módulos de migração
    migration_modules = :code.all_loaded()
    |> Enum.filter(fn {module, _} ->
      module_name = Atom.to_string(module)
      String.contains?(module_name, "Migration")
    end)
    |> Enum.map(fn {module, _} -> module end)
    
    # Encontra o módulo que contém a versão especificada
    Enum.find(migration_modules, fn module ->
      module_name = Atom.to_string(module)
      String.contains?(module_name, version)
    end)
  end
end
