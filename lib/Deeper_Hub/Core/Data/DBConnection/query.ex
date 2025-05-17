defmodule Deeper_Hub.Core.Data.DBConnection.Query do
  @moduledoc """
  Implementação do protocolo DBConnection.Query para consultas SQL.
  
  Este módulo permite que strings SQL sejam usadas diretamente com o DBConnection.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Estrutura para representar uma consulta SQL.
  """
  defstruct [:statement, :params]
  
  @type t :: %__MODULE__{
    statement: String.t(),
    params: list()
  }
  
  @doc """
  Cria uma nova consulta SQL.
  
  ## Parâmetros
  
    - `statement`: A consulta SQL
    - `params`: Parâmetros da consulta (opcional)
  
  ## Retorno
  
    - Uma struct %Query{} representando a consulta
  """
  def new(statement, params \\ []) do
    %__MODULE__{statement: statement, params: params}
  end
end

defimpl DBConnection.Query, for: BitString do
  @moduledoc """
  Implementação do protocolo DBConnection.Query para strings SQL.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Analisa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções de análise
  
  ## Retorno
  
    - A consulta SQL analisada
  """
  def parse(query, _opts) do
    Logger.debug("Analisando consulta SQL", %{
      module: __MODULE__,
      query: query
    })
    
    query
  end
  
  @doc """
  Descreve uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções de descrição
  
  ## Retorno
  
    - A consulta SQL
  """
  def describe(query, _opts) do
    Logger.debug("Descrevendo consulta SQL", %{
      module: __MODULE__,
      query: query
    })
    
    query
  end
  
  @doc """
  Codifica parâmetros para uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de codificação
  
  ## Retorno
  
    - Os parâmetros codificados
  """
  def encode(query, params, _opts) do
    # Reduzimos o nível de log para diminuir mensagens duplicadas
    # Usamos o nível trace para informações muito detalhadas que só são úteis em depuração profunda
    Logger.debug("Codificando parâmetros para consulta SQL", %{
      query: query
    })
    
    # Verifica se os parâmetros são válidos
    validate_params!(params)
    
    params
  end
  
  @doc """
  Decodifica o resultado de uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `result`: Resultado da consulta
    - `opts`: Opções de decodificação
  
  ## Retorno
  
    - O resultado decodificado
  """
  def decode(_query, result, _opts) do
    result
  end
  
  # Funções privadas
  
  defp validate_params!(params) when is_list(params) do
    Enum.each(params, &validate_param!/1)
    params
  end
  
  defp validate_params!(params) do
    raise DBConnection.EncodeError, "parâmetros devem ser uma lista, recebido: #{inspect(params)}"
  end
  
  defp validate_param!(param) when is_binary(param), do: :ok
  defp validate_param!(param) when is_number(param), do: :ok
  defp validate_param!(param) when is_boolean(param), do: :ok
  defp validate_param!(nil), do: :ok
  defp validate_param!(param) do
    raise DBConnection.EncodeError, "parâmetro inválido: #{inspect(param)}"
  end
end

defimpl DBConnection.Query, for: Deeper_Hub.Core.Data.DBConnection.Query do
  @moduledoc """
  Implementação do protocolo DBConnection.Query para %Query{}.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Analisa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções de análise
  
  ## Retorno
  
    - A consulta SQL analisada
  """
  def parse(query, _opts) do
    Logger.debug("Analisando consulta SQL estruturada", %{
      module: __MODULE__,
      query: query.statement
    })
    
    query
  end
  
  @doc """
  Descreve uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções de descrição
  
  ## Retorno
  
    - A consulta SQL
  """
  def describe(query, _opts) do
    Logger.debug("Descrevendo consulta SQL estruturada", %{
      module: __MODULE__,
      query: query.statement
    })
    
    query
  end
  
  @doc """
  Codifica parâmetros para uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de codificação
  
  ## Retorno
  
    - Os parâmetros codificados
  """
  def encode(query, params, _opts) do
    # Reduzimos o nível de log para diminuir mensagens duplicadas
    Logger.debug("Codificando parâmetros para consulta estruturada", %{
      query: query.statement
    })
    
    # Combina os parâmetros da consulta com os parâmetros fornecidos
    combined_params = query.params ++ params
    
    # Verifica se os parâmetros são válidos
    validate_params!(combined_params)
    
    combined_params
  end
  
  @doc """
  Decodifica o resultado de uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `result`: Resultado da consulta
    - `opts`: Opções de decodificação
  
  ## Retorno
  
    - O resultado decodificado
  """
  def decode(_query, result, _opts) do
    result
  end
  
  # Funções privadas
  
  defp validate_params!(params) when is_list(params) do
    Enum.each(params, &validate_param!/1)
    params
  end
  
  defp validate_params!(params) do
    raise DBConnection.EncodeError, "parâmetros devem ser uma lista, recebido: #{inspect(params)}"
  end
  
  defp validate_param!(param) when is_binary(param), do: :ok
  defp validate_param!(param) when is_number(param), do: :ok
  defp validate_param!(param) when is_boolean(param), do: :ok
  defp validate_param!(nil), do: :ok
  defp validate_param!(param) do
    raise DBConnection.EncodeError, "parâmetro inválido: #{inspect(param)}"
  end
end
