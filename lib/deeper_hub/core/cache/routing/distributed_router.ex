defmodule DeeperHub.Core.Cache.Routing.DistributedRouter do
  @moduledoc """
  Roteador para cache distribuído no DeeperHub.
  
  Este módulo implementa funcionalidades para gerenciar o roteamento
  de operações de cache em um ambiente distribuído, possibilitando que
  o sistema de cache funcione eficientemente em um cluster Erlang.
  
  Utilizamos o sistema de roteamento do Cachex para garantir que as
  operações sejam encaminhadas para o nó correto, mantendo a consistência
  dos dados em todo o cluster.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Cria um roteador para uso em cache distribuído.
  
  Este roteador utiliza o algoritmo de consistent hashing para
  distribuir as operações de cache entre os nós do cluster.
  
  ## Parâmetros
  
    * `type` - Tipo de roteador a ser utilizado (:jump, :ring, ou :local)
    * `opts` - Opções adicionais para o roteador
  
  ## Retorno
  
    * Uma especificação de roteador para ser usada na configuração do Cachex
  """
  @spec create_router(atom(), keyword()) :: tuple()
  def create_router(type \\ :ring, opts \\ []) do
    import Cachex.Spec
    
    # Seleciona o módulo correto com base no tipo
    module = case type do
      :jump -> Cachex.Router.Jump
      :ring -> Cachex.Router.Ring
      :local -> Cachex.Router.Local
      :mod -> Cachex.Router.Mod
      _ -> Cachex.Router.Local
    end
    
    Logger.info("Criando roteador de cache do tipo #{type}", module: __MODULE__)
    
    # Cria a especificação do roteador
    router(
      module: module,
      options: opts
    )
  end
  
  @doc """
  Determina se o sistema deve usar um roteador distribuído.
  
  Esta função verifica o ambiente de execução e a configuração
  do sistema para determinar se deve ser usado um roteador
  distribuído.
  
  ## Retorno
  
    * `true` se deve usar roteador distribuído
    * `false` caso contrário
  """
  @spec use_distributed_router?() :: boolean()
  def use_distributed_router? do
    # Verifica se há mais de um nó no cluster
    cluster_size = Node.list() |> length()
    cluster_size > 0 && distributed_enabled?()
  end
  
  @doc """
  Cria o roteador recomendado para o ambiente atual.
  
  Determina automaticamente o melhor tipo de roteador para
  o ambiente de execução atual.
  
  ## Retorno
  
    * Uma especificação de roteador para ser usada na configuração do Cachex
  """
  @spec create_recommended_router() :: tuple()
  def create_recommended_router do
    {type, opts} = if use_distributed_router?() do
      # Em um ambiente distribuído, usamos o roteador Ring
      # com hash consistente para melhor distribuição
      {:ring, [
        replicas: 128,      # Número de réplicas para o hash consistente
        nodes: Node.list() ++ [Node.self()]
      ]}
    else
      # Em um ambiente local, usamos o roteador Local
      # que é mais eficiente para um único nó
      {:local, []}
    end
    
    create_router(type, opts)
  end
  
  # Funções privadas
  
  # Verifica se o cache distribuído está habilitado nas configurações
  defp distributed_enabled? do
    Application.get_env(:deeper_hub, :cache, [])
    |> Keyword.get(:distributed, false)
  end
end
