defmodule DeeperHub.Inspector.Behaviours.InspectorBehaviour do
  @moduledoc """
  Define o comportamento padrão para inspetores do sistema 🔍

  Este módulo estabelece a interface que todos os inspetores devem implementar,
  permitindo análise e inspeção de diferentes tipos de elementos do sistema.
  """

  @doc """
  Inspeciona um elemento e retorna informações detalhadas sobre ele 🔎

  ## Parâmetros

    * `element` - O elemento a ser inspecionado
    * `options` - Opções para personalizar a inspeção

  ## Retorno

  Retorna um mapa com informações detalhadas sobre o elemento inspecionado.
  """
  @callback inspect(element :: any(), options :: keyword()) :: map()

  @doc """
  Verifica se o elemento é suportado por este inspetor ✅

  ## Parâmetros

    * `element` - O elemento a ser verificado

  ## Retorno

  Retorna `true` se o elemento for suportado, ou `false` caso contrário.
  """
  @callback supported?(element :: any()) :: boolean()

  @doc """
  Retorna o tipo de elemento que este inspetor suporta 📋

  ## Retorno

  Retorna um átomo representando o tipo de elemento suportado.
  """
  @callback element_type() :: atom()

  @doc """
  Extrai metadados específicos do elemento inspecionado 📊

  ## Parâmetros

    * `element` - O elemento do qual extrair metadados
    * `options` - Opções para personalizar a extração

  ## Retorno

  Retorna um mapa com metadados do elemento.
  """
  @callback extract_metadata(element :: any(), options :: keyword()) :: map()

  @doc """
  Formata o resultado da inspeção para exibição 🖥️

  ## Parâmetros

    * `inspection_result` - O resultado da inspeção
    * `format` - O formato desejado para a saída (:text, :json, :html)

  ## Retorno

  Retorna uma string formatada com o resultado da inspeção.
  """
  @callback format_result(inspection_result :: map(), format :: atom()) :: String.t()

  @optional_callbacks [format_result: 2]
end
