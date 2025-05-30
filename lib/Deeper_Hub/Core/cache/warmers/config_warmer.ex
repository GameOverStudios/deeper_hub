defmodule DeeperHub.Core.Cache.Warmers.ConfigWarmer do
  @moduledoc """
  Warmer para pré-carregar configurações do sistema no cache.
  
  Este módulo implementa o comportamento Cachex.Warmer para permitir
  o pré-carregamento de configurações do sistema no cache, garantindo
  que dados frequentemente acessados estejam disponíveis imediatamente
  após a inicialização do sistema.
  """
  
  @behaviour Cachex.Warmer
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Inicializa o warmer com um estado personalizado.
  
  ## Parâmetros
  
    * `state` - Estado inicial, geralmente opções de configuração.
  
  ## Retorno
  
    * `{:ok, state}` - Estado inicializado com sucesso
  """
  def init(state) do
    Logger.info("Inicializando warmer de configurações do cache", module: __MODULE__)
    {:ok, state}
  end
  
  @doc """
  Define o intervalo de execução automática do warmer.
  
  Este método define quanto tempo o Cachex deve esperar entre execuções
  automáticas do warmer.
  
  ## Retorno
  
    * Intervalo em milissegundos entre execuções
  """
  def interval do
    # Executar a cada 30 minutos (em milissegundos)
    :timer.minutes(30)
  end
  
  @doc """
  Executa o warmer para pré-carregar configurações no cache.
  
  ## Parâmetros
  
    * `state` - Estado atual do warmer
  
  ## Retorno
  
    * `{:ok, entries, state}` - Entradas a serem inseridas no cache e novo estado
  """
  @impl Cachex.Warmer
  def execute(state) do
    Logger.info("Executando pré-carregamento de configurações no cache", module: __MODULE__)
    
    # Carregar configurações do sistema
    # Aqui poderíamos buscar configurações do banco de dados, arquivos, etc.
    entries = [
      # Configurações gerais com namespace "config:"
      {"config:app_name", "DeeperHub"},
      {"config:version", "0.1.0"},
      {"config:environment", get_environment()},
      
      # Configurações de segurança com namespace "security:"
      {"security:max_login_attempts", 5},
      {"security:password_min_length", 8},
      {"security:session_timeout", 3600},
      
      # Prazos de expiração de cache por tipo de dados
      {"cache_ttl:user", 600},       # 10 minutos
      {"cache_ttl:session", 3600},   # 1 hora
      {"cache_ttl:config", 86400}    # 24 horas
    ]
    
    # Log de conclusão
    Logger.info("Pré-carregamento de configurações concluído: #{length(entries)} entradas", 
                module: __MODULE__)
    
    # Retorna as entradas a serem carregadas no cache
    {:ok, entries, state}
  end
  
  # Funções privadas
  
  # Obtém o ambiente atual da aplicação
  defp get_environment do
    Application.get_env(:deeper_hub, :environment, "development")
  end
end
