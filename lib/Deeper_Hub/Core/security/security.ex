defmodule DeeperHub.Core.Security do
  @moduledoc """
  Módulo principal para gerenciamento de segurança do DeeperHub.
  
  Este módulo coordena as diversas funcionalidades de segurança do sistema,
  incluindo proteção contra ataques, configurações de segurança e
  inicialização de componentes de segurança.
  
  Funcionalidades principais:
  - Gerenciamento de IPs bloqueados
  - Configuração de limites de taxa de requisições
  - Inicialização do subsistema de segurança
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  # Nome da tabela ETS usada pelo módulo Attack
  # Definido aqui apenas para documentação
  # A tabela real é gerenciada pelo módulo DeeperHub.Core.Security.Attack
  
  @doc """
  Inicializa o subsistema de segurança.
  
  Esta função deve ser chamada durante a inicialização da aplicação
  para garantir que todas as medidas de segurança estejam ativas.
  
  ## Retorno
  
  - `:ok` - Se a inicialização for bem-sucedida
  """
  @spec init() :: :ok
  def init do
    Logger.info("Inicializando subsistema de segurança...", module: __MODULE__)
    
    # Carrega configurações de segurança
    load_security_config()
    
    # Inicializa o armazenamento ETS para proteção contra ataques
    DeeperHub.Core.Security.AuthAttack.init()
    
    Logger.info("Subsistema de segurança inicializado com sucesso.", module: __MODULE__)
    :ok
  end
  
  @doc """
  Verifica se um IP está na lista de bloqueio.
  
  ## Parâmetros
  
  - `ip` - Endereço IP a ser verificado
  
  ## Retorno
  
  - `true` - Se o IP estiver bloqueado
  - `false` - Se o IP não estiver bloqueado
  """
  @spec ip_blocked?(String.t()) :: boolean()
  def ip_blocked?(ip) when is_binary(ip) do
    blocked_ips = get_blocked_ips()
    Enum.member?(blocked_ips, ip)
  end
  
  @doc """
  Adiciona um IP à lista de bloqueio.
  
  ## Parâmetros
  
  - `ip` - Endereço IP a ser bloqueado
  - `reason` - Motivo opcional do bloqueio
  
  ## Retorno
  
  - `:ok` - Se o IP for adicionado com sucesso
  """
  @spec block_ip(String.t(), String.t() | nil) :: :ok
  def block_ip(ip, reason \\ nil) when is_binary(ip) do
    Logger.info("Adicionando IP à lista de bloqueio: #{ip}", 
                module: __MODULE__, 
                reason: reason || "manual")
    
    # Obtém a lista atual
    current_config = Application.get_env(:deeper_hub, :security, [])
    blocked_ips = current_config[:blocked_ips] || []
    
    # Adiciona o novo IP se ainda não estiver na lista
    if !Enum.member?(blocked_ips, ip) do
      new_blocked_ips = [ip | blocked_ips]
      new_config = Keyword.put(current_config, :blocked_ips, new_blocked_ips)
      
      # Atualiza a configuração
      Application.put_env(:deeper_hub, :security, new_config)
      
      # Registra o bloqueio em um log de auditoria
      log_ip_action(ip, :block, reason)
    end
    
    :ok
  end
  
  @doc """
  Remove um IP da lista de bloqueio.
  
  ## Parâmetros
  
  - `ip` - Endereço IP a ser desbloqueado
  - `reason` - Motivo opcional do desbloqueio
  
  ## Retorno
  
  - `:ok` - Se o IP for removido com sucesso
  """
  @spec unblock_ip(String.t(), String.t() | nil) :: :ok
  def unblock_ip(ip, reason \\ nil) when is_binary(ip) do
    Logger.info("Removendo IP da lista de bloqueio: #{ip}", 
                module: __MODULE__, 
                reason: reason || "manual")
    
    # Obtém a lista atual
    current_config = Application.get_env(:deeper_hub, :security, [])
    blocked_ips = current_config[:blocked_ips] || []
    
    # Remove o IP da lista
    new_blocked_ips = Enum.reject(blocked_ips, fn blocked_ip -> blocked_ip == ip end)
    new_config = Keyword.put(current_config, :blocked_ips, new_blocked_ips)
    
    # Atualiza a configuração
    Application.put_env(:deeper_hub, :security, new_config)
    
    # Registra o desbloqueio em um log de auditoria
    log_ip_action(ip, :unblock, reason)
    
    :ok
  end
  
  @doc """
  Obtém a lista atual de IPs bloqueados.
  
  ## Retorno
  
  - Lista de IPs bloqueados
  """
  @spec get_blocked_ips() :: [String.t()]
  def get_blocked_ips do
    Application.get_env(:deeper_hub, :security, [])[:blocked_ips] || []
  end
  
  @doc """
  Obtém os limites de taxa configurados.
  
  ## Retorno
  
  - Mapa com os limites de taxa para diferentes tipos de requisições
  """
  @spec get_rate_limits() :: Keyword.t()
  def get_rate_limits do
    Application.get_env(:deeper_hub, :security, [])[:rate_limits] || [
      authentication: 10,
      api: 300,
      websocket: 300
    ]
  end
  
  # Carrega configurações de segurança
  defp load_security_config do
    # Configurações padrão
    default_config = [
      blocked_ips: [],
      rate_limits: [
        authentication: 10,  # 10 requisições por minuto
        api: 300,            # 300 requisições por minuto
        websocket: 300       # 300 requisições por minuto
      ],
      security_headers: [
        enabled: true,
        strict_transport_security: "max-age=31536000; includeSubDomains",
        content_security_policy: true
      ]
    ]
    
    # Obtém configurações do ambiente
    env_config = Application.get_env(:deeper_hub, :security, [])
    
    # Mescla as configurações, com prioridade para as do ambiente
    config = Keyword.merge(default_config, env_config)
    
    # Atualiza a configuração da aplicação
    Application.put_env(:deeper_hub, :security, config)
    
    Logger.debug("Configurações de segurança carregadas", 
                 module: __MODULE__, 
                 blocked_ips_count: length(config[:blocked_ips]))
  end
  
  # Registra ações de bloqueio/desbloqueio em um log de auditoria
  defp log_ip_action(ip, action, reason) do
    timestamp = DateTime.utc_now() |> DateTime.to_iso8601()
    
    Logger.info("Ação de segurança: #{action} para IP #{ip}", 
                module: __MODULE__, 
                action: action, 
                ip: ip, 
                reason: reason || "não especificado", 
                timestamp: timestamp)
  end
end
