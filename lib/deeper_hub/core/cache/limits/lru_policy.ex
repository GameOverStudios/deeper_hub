defmodule DeeperHub.Core.Cache.Limits.LruPolicy do
  @moduledoc """
  Política de limite de cache baseada em LRU (Least Recently Used).
  
  Esta política utiliza o algoritmo LRU (Least Recently Used) para limitar o
  tamanho do cache, removendo automaticamente os itens menos utilizados quando
  o limite é atingido.
  
  Implementa a interface do Cachex.Policy.LRU para integração com o Cachex,
  permitindo o gerenciamento eficiente da memória utilizada pelo cache.
  """
  
  require DeeperHub.Core.Logger
  alias DeeperHub.Core.Logger
  
  @doc """
  Cria um novo hook para política LRU.
  
  ## Parâmetros
  
    * `max_size` - Tamanho máximo do cache em número de itens
    * `reclaim_percent` - Porcentagem de itens a remover quando atingir o limite
    
  ## Retorno
  
    * Um hook configurado para ser usado com Cachex
  """
  @spec create_hook(pos_integer(), float()) :: tuple()
  def create_hook(max_size \\ 10_000, reclaim_percent \\ 0.1) do
    limit = round(max_size * reclaim_percent)
    
    # Cria um hook LRU que remove os itens menos usados quando atingir o limite
    import Cachex.Spec
    
    hook(
      module: Cachex.Policy.LRU,
      name: :lru_policy,
      args: [
        # Limite máximo de itens no cache
        limit: max_size,
        # Quantidade a remover quando atingir o limite
        reclaim: limit
      ]
    )
  end
  
  @doc """
  Retorna as configurações recomendadas com base no ambiente.
  
  Retorna diferentes configurações de tamanho máximo do cache
  e porcentagem de reclamação com base no ambiente de execução.
  
  ## Parâmetros
  
    * `environment` - Ambiente de execução (:development, :test, :production)
  
  ## Retorno
  
    * `{max_size, reclaim_percent}` - Configurações recomendadas
  """
  @spec recommended_settings(atom()) :: {pos_integer(), float()}
  def recommended_settings(environment \\ nil) do
    environment = environment || Application.get_env(:deeper_hub, :environment, :development)
    
    case environment do
      :development -> {5_000, 0.2}     # 5 mil itens, 20% de reclamação
      :test        -> {1_000, 0.5}     # 1 mil itens, 50% de reclamação 
      :production  -> {100_000, 0.1}   # 100 mil itens, 10% de reclamação
      _            -> {10_000, 0.2}    # Padrão para ambientes desconhecidos
    end
  end
  
  @doc """
  Cria um hook com configurações recomendadas para o ambiente atual.
  
  ## Retorno
  
    * Um hook LRU configurado com base no ambiente atual
  """
  @spec create_recommended_hook() :: tuple()
  def create_recommended_hook do
    {max_size, reclaim_percent} = recommended_settings()
    
    Logger.info(
      "Criando política LRU para cache com limite de #{max_size} itens " <>
      "e #{reclaim_percent * 100}% de reclamação",
      module: __MODULE__
    )
    
    create_hook(max_size, reclaim_percent)
  end
end
