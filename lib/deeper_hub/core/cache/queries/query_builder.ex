defmodule DeeperHub.Core.Cache.Queries.QueryBuilder do
  @moduledoc """
  Construtor de consultas para o sistema de cache.
  
  Este módulo fornece funções para criar consultas compatíveis com o Cachex,
  substituindo o uso direto de `Cachex.Query.create/1` que é uma função privada.
  """

  @doc """
  Cria uma estrutura de consulta para o Cachex.
  
  Esta função encapsula a criação de consultas para o Cachex, garantindo compatibilidade
  com a API pública do Cachex e evitando o uso direto de funções privadas.
  
  ## Parâmetros
  
    * `opts` - Opções da consulta. Suporta:
      * `:where` - Função de filtro que recebe `{key, value}` e retorna um booleano
  
  ## Retorno
  
    * Estrutura de consulta compatível com Cachex
  
  ## Exemplos
  
      iex> filter = fn {key, _} -> String.starts_with?(key, "user:") end
      iex> query = DeeperHub.Core.Cache.Queries.QueryBuilder.create(where: filter)
      iex> Cachex.stream(:my_cache, query)
  """
  def create(opts \\ []) do
    condition = Keyword.get(opts, :where, fn _ -> true end)
    
    # Criamos uma estrutura que o Cachex reconhece para streaming/consulta
    # Isso evita o uso de Cachex.Query.create/1 que é privado
    %{
      execute: nil,
      limit: nil, 
      select: nil,
      start: nil,
      stream: true,
      where: condition
    }
  end
end
