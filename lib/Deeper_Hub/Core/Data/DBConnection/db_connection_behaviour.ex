defmodule Deeper_Hub.Core.Data.DBConnection.DBConnectionBehaviour do
  @moduledoc """
  Comportamento que define a interface para operações de conexão com banco de dados.
  
  Este módulo define o contrato para adapters de conexão com banco de dados,
  permitindo operações como transações, preparação e execução de consultas,
  e gerenciamento do ciclo de vida das conexões.
  
  ## Funcionalidades
  
  * 🔄 Gerenciamento de conexões com banco de dados
  * 📝 Preparação e execução de consultas
  * 🔒 Suporte a transações
  * 📊 Métricas de conexão
  * 🛡️ Tratamento de erros de conexão
  """
  
  @doc """
  Inicia uma conexão com o banco de dados.
  
  ## Parâmetros
  
    * `conn_mod` - Módulo de conexão
    * `opts` - Opções de conexão
    
  ## Retorno
  
    * `{:ok, pid}` - Conexão iniciada com sucesso
    * `{:error, term()}` - Erro ao iniciar a conexão
  """
  @callback start_link(conn_mod :: module(), opts :: Keyword.t()) ::
              {:ok, pid()} | {:error, term()}
  
  @doc """
  Prepara uma consulta para execução.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `query` - Consulta a ser preparada
    * `opts` - Opções de preparação
    
  ## Retorno
  
    * `{:ok, prepared_query}` - Consulta preparada com sucesso
    * `{:error, exception}` - Erro ao preparar a consulta
  """
  @callback prepare(conn :: DBConnection.conn(), query :: term(), opts :: Keyword.t()) ::
              {:ok, prepared_query :: term()} | {:error, Exception.t()}
  
  @doc """
  Executa uma consulta preparada.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `query` - Consulta preparada
    * `params` - Parâmetros da consulta
    * `opts` - Opções de execução
    
  ## Retorno
  
    * `{:ok, result}` - Consulta executada com sucesso
    * `{:error, exception}` - Erro ao executar a consulta
  """
  @callback execute(
              conn :: DBConnection.conn(),
              query :: term(),
              params :: term(),
              opts :: Keyword.t()
            ) :: {:ok, result :: term()} | {:error, Exception.t()}
  
  @doc """
  Prepara e executa uma consulta em uma única operação.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `query` - Consulta a ser preparada e executada
    * `params` - Parâmetros da consulta
    * `opts` - Opções de preparação e execução
    
  ## Retorno
  
    * `{:ok, prepared_query, result}` - Consulta preparada e executada com sucesso
    * `{:error, exception}` - Erro ao preparar ou executar a consulta
  """
  @callback prepare_execute(
              conn :: DBConnection.conn(),
              query :: term(),
              params :: term(),
              opts :: Keyword.t()
            ) ::
              {:ok, prepared_query :: term(), result :: term()} | {:error, Exception.t()}
  
  @doc """
  Executa uma função dentro de uma transação.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `fun` - Função a ser executada dentro da transação
    * `opts` - Opções da transação
    
  ## Retorno
  
    * `{:ok, result}` - Transação concluída com sucesso
    * `{:error, reason}` - Erro na transação
  """
  @callback transaction(
              conn :: DBConnection.conn(),
              fun :: (DBConnection.conn() -> any()),
              opts :: Keyword.t()
            ) :: {:ok, any()} | {:error, term()}
  
  @doc """
  Desfaz uma transação.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `reason` - Motivo do rollback
    
  ## Retorno
  
    * `:ok` - Rollback realizado com sucesso
    * `{:error, term()}` - Erro ao realizar o rollback
  """
  @callback rollback(conn :: DBConnection.conn(), reason :: term()) :: no_return()
  
  @doc """
  Executa uma função com uma conexão.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `fun` - Função a ser executada
    * `opts` - Opções de execução
    
  ## Retorno
  
    * `result` - Resultado da função
  """
  @callback run(
              conn :: DBConnection.conn(),
              fun :: (DBConnection.conn() -> any()),
              opts :: Keyword.t()
            ) :: any()
  
  @doc """
  Obtém o status da conexão.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `opts` - Opções
    
  ## Retorno
  
    * `:idle` | `:busy` | `:closed` - Status da conexão
  """
  @callback status(conn :: DBConnection.conn(), opts :: Keyword.t()) ::
              :idle | :busy | :closed
  
  @doc """
  Fecha uma consulta preparada.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `query` - Consulta preparada
    * `opts` - Opções
    
  ## Retorno
  
    * `:ok` - Consulta fechada com sucesso
    * `{:error, exception}` - Erro ao fechar a consulta
  """
  @callback close(conn :: DBConnection.conn(), query :: term(), opts :: Keyword.t()) ::
              :ok | {:error, Exception.t()}
  
  @doc """
  Obtém métricas de conexão.
  
  ## Parâmetros
  
    * `conn` - Conexão com o banco de dados
    * `opts` - Opções
    
  ## Retorno
  
    * `map()` - Métricas da conexão
  """
  @callback get_connection_metrics(conn :: DBConnection.conn(), opts :: Keyword.t()) :: map()
end
