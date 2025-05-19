defmodule DeeperHub.Core.Security do
  @moduledoc """
  Módulo principal para gerenciamento de segurança do DeeperHub.
  
  Este módulo coordena as diversas funcionalidades de segurança do sistema,
  incluindo proteção contra ataques, configurações de segurança e
  inicialização de componentes de segurança.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Inicializa o subsistema de segurança.
  
  Esta função deve ser chamada durante a inicialização da aplicação
  para garantir que todas as medidas de segurança estejam ativas.
  
  ## Retorno
  
  - `:ok` - Se a inicialização for bem-sucedida
  """
  def init do
    Logger.info("Inicializando subsistema de segurança...", module: __MODULE__)
    
    # Inicializa o armazenamento ETS para o Plug.Attack
    :ets.new(:deeper_hub_attack_storage, [:named_table, :public, :set])
    
    # Carrega configurações de segurança
    load_security_config()
    
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
  def ip_blocked?(ip) when is_binary(ip) do
    blocked_ips = Application.get_env(:deeper_hub, :security, [])[:blocked_ips] || []
    Enum.member?(blocked_ips, ip)
  end
  
  @doc """
  Adiciona um IP à lista de bloqueio.
  
  ## Parâmetros
  
  - `ip` - Endereço IP a ser bloqueado
  
  ## Retorno
  
  - `:ok` - Se o IP for adicionado com sucesso
  """
  def block_ip(ip) when is_binary(ip) do
    Logger.info("Adicionando IP à lista de bloqueio: #{ip}", module: __MODULE__)
    
    # Obtém a lista atual
    current_config = Application.get_env(:deeper_hub, :security, [])
    blocked_ips = current_config[:blocked_ips] || []
    
    # Adiciona o novo IP se ainda não estiver na lista
    if !Enum.member?(blocked_ips, ip) do
      new_blocked_ips = [ip | blocked_ips]
      new_config = Keyword.put(current_config, :blocked_ips, new_blocked_ips)
      
      # Atualiza a configuração
      Application.put_env(:deeper_hub, :security, new_config)
    end
    
    :ok
  end
  
  @doc """
  Remove um IP da lista de bloqueio.
  
  ## Parâmetros
  
  - `ip` - Endereço IP a ser desbloqueado
  
  ## Retorno
  
  - `:ok` - Se o IP for removido com sucesso
  """
  def unblock_ip(ip) when is_binary(ip) do
    Logger.info("Removendo IP da lista de bloqueio: #{ip}", module: __MODULE__)
    
    # Obtém a lista atual
    current_config = Application.get_env(:deeper_hub, :security, [])
    blocked_ips = current_config[:blocked_ips] || []
    
    # Remove o IP da lista
    new_blocked_ips = Enum.reject(blocked_ips, fn blocked_ip -> blocked_ip == ip end)
    new_config = Keyword.put(current_config, :blocked_ips, new_blocked_ips)
    
    # Atualiza a configuração
    Application.put_env(:deeper_hub, :security, new_config)
    
    :ok
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
      ]
    ]
    
    # Obtém configurações do ambiente
    env_config = Application.get_env(:deeper_hub, :security, [])
    
    # Mescla as configurações, com prioridade para as do ambiente
    config = Keyword.merge(default_config, env_config)
    
    # Atualiza a configuração da aplicação
    Application.put_env(:deeper_hub, :security, config)
  end
end
