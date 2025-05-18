defmodule Deeper_Hub.Core.Data.DBConnection.Optimizer do
  @moduledoc """
  Otimizador de consultas SQL para o DBConnection.
  
  Este módulo fornece funções para otimizar consultas SQL, melhorando
  a performance do sistema e reduzindo o tempo de execução das consultas.
  """
  
  alias Deeper_Hub.Core.Logger
  
  @doc """
  Analisa uma consulta SQL e sugere otimizações.
  
  ## Parâmetros
  
    - `query`: A consulta SQL a ser analisada
  
  ## Retorno
  
    - `{:ok, suggestions}` com sugestões de otimização
    - `{:ok, []}` se não houver sugestões
  """
  @spec analyze(String.t()) :: {:ok, list(String.t())}
  def analyze(query) do
    Logger.debug("Analisando consulta SQL", %{
      module: __MODULE__,
      query: query
    })
    
    suggestions = []
    
    # Verifica se a consulta tem SELECT *
    suggestions = if String.match?(query, ~r/SELECT\s+\*/i) do
      ["Evite usar SELECT * e selecione apenas as colunas necessárias" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem LIMIT sem ORDER BY
    suggestions = if String.match?(query, ~r/LIMIT/i) && !String.match?(query, ~r/ORDER BY/i) do
      ["Use ORDER BY com LIMIT para garantir resultados consistentes" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem WHERE sem índice
    suggestions = if String.match?(query, ~r/WHERE/i) && !has_index_hint?(query) do
      ["Considere adicionar índices para as colunas usadas em condições WHERE" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem JOIN sem índice
    suggestions = if String.match?(query, ~r/JOIN/i) && !has_index_hint?(query) do
      ["Considere adicionar índices para as colunas usadas em JOIN" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem GROUP BY sem índice
    suggestions = if String.match?(query, ~r/GROUP BY/i) && !has_index_hint?(query) do
      ["Considere adicionar índices para as colunas usadas em GROUP BY" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem ORDER BY sem índice
    suggestions = if String.match?(query, ~r/ORDER BY/i) && !has_index_hint?(query) do
      ["Considere adicionar índices para as colunas usadas em ORDER BY" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem subconsultas
    suggestions = if String.match?(query, ~r/\(\s*SELECT/i) do
      ["Considere reescrever subconsultas como JOINs quando possível" | suggestions]
    else
      suggestions
    end
    
    # Verifica se a consulta tem funções em colunas indexadas
    suggestions = if String.match?(query, ~r/WHERE\s+\w+\s*\(/i) do
      ["Evite usar funções em colunas indexadas em condições WHERE" | suggestions]
    else
      suggestions
    end
    
    # Registra as sugestões
    if Enum.empty?(suggestions) do
      Logger.debug("Nenhuma sugestão de otimização para a consulta", %{
        module: __MODULE__,
        query: query
      })
    else
      Logger.info("Sugestões de otimização para a consulta", %{
        module: __MODULE__,
        query: query,
        suggestions: suggestions
      })
    end
    
    {:ok, suggestions}
  end
  
  @doc """
  Otimiza uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL a ser otimizada
  
  ## Retorno
  
    - `{:ok, optimized_query}` com a consulta otimizada
    - `{:ok, query}` se não for possível otimizar
  """
  @spec optimize(String.t()) :: {:ok, String.t()}
  def optimize(query) do
    Logger.debug("Otimizando consulta SQL", %{
      module: __MODULE__,
      query: query
    })
    
    # Aplica otimizações básicas
    optimized_query = query
    |> optimize_select()
    |> add_index_hints()
    |> optimize_joins()
    |> optimize_where()
    |> optimize_order_by()
    |> optimize_group_by()
    |> optimize_limit()
    
    # Registra o resultado da otimização
    if optimized_query == query do
      Logger.debug("Consulta já está otimizada", %{
        module: __MODULE__,
        query: query
      })
    else
      Logger.info("Consulta otimizada", %{
        module: __MODULE__,
        original_query: query,
        optimized_query: optimized_query
      })
    end
    
    {:ok, optimized_query}
  end
  
  @doc """
  Adiciona dicas de índice a uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `table`: A tabela para adicionar dicas de índice
    - `column`: A coluna para adicionar dicas de índice
  
  ## Retorno
  
    - A consulta SQL com dicas de índice
  """
  @spec add_index_hint(String.t(), String.t(), String.t()) :: String.t()
  def add_index_hint(query, table, column) do
    Logger.debug("Adicionando dica de índice", %{
      module: __MODULE__,
      query: query,
      table: table,
      column: column
    })
    
    # SQLite não suporta dicas de índice como MySQL ou PostgreSQL,
    # mas podemos adicionar um comentário para documentar
    "#{query} /* Use índice em #{table}(#{column}) */"
  end
  
  @doc """
  Verifica se uma consulta tem dicas de índice.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
  
  ## Retorno
  
    - `true` se a consulta tiver dicas de índice
    - `false` caso contrário
  """
  @spec has_index_hint?(String.t()) :: boolean()
  def has_index_hint?(query) do
    String.match?(query, ~r/\/\*\s*Use índice\s*/)
  end
  
  # Funções privadas para otimização
  
  # Otimiza a cláusula SELECT
  defp optimize_select(query) do
    # Substitui SELECT * por SELECT específico se possível
    # Isso é apenas um exemplo, na prática precisaríamos analisar o schema
    if String.match?(query, ~r/SELECT\s+\*/i) do
      # Como não temos informações sobre o schema, não podemos otimizar
      # completamente, mas podemos adicionar um comentário
      String.replace(query, ~r/SELECT\s+\*/i, "SELECT * /* Considere selecionar colunas específicas */")
    else
      query
    end
  end
  
  # Adiciona dicas de índice
  defp add_index_hints(query) do
    # Como não temos informações sobre os índices disponíveis,
    # não podemos adicionar dicas de índice automaticamente
    query
  end
  
  # Otimiza JOINs
  defp optimize_joins(query) do
    # Otimiza a ordem dos JOINs (tabelas menores primeiro)
    # Como não temos informações sobre o tamanho das tabelas,
    # não podemos otimizar completamente
    query
  end
  
  # Otimiza a cláusula WHERE
  defp optimize_where(query) do
    # Reordena as condições WHERE (condições mais seletivas primeiro)
    # Como não temos informações sobre a seletividade,
    # não podemos otimizar completamente
    query
  end
  
  # Otimiza a cláusula ORDER BY
  defp optimize_order_by(query) do
    # Verifica se ORDER BY usa índices
    # Como não temos informações sobre os índices disponíveis,
    # não podemos otimizar completamente
    query
  end
  
  # Otimiza a cláusula GROUP BY
  defp optimize_group_by(query) do
    # Verifica se GROUP BY usa índices
    # Como não temos informações sobre os índices disponíveis,
    # não podemos otimizar completamente
    query
  end
  
  # Otimiza a cláusula LIMIT
  defp optimize_limit(query) do
    # Adiciona ORDER BY se LIMIT estiver presente sem ORDER BY
    if String.match?(query, ~r/LIMIT/i) && !String.match?(query, ~r/ORDER BY/i) do
      # Como não sabemos qual coluna usar para ORDER BY,
      # adicionamos um comentário
      query <> " /* Considere adicionar ORDER BY para resultados consistentes */"
    else
      query
    end
  end
end
