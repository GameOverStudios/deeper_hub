defmodule Deeper_Hub.Core.Data.DBConnection.Facade do
  @moduledoc """
  Fachada para a camada de acesso a banco de dados usando DBConnection.
  
  Este módulo fornece uma interface simplificada para as operações de banco de dados,
  facilitando a migração do Repo para o DBConnection.
  """
  
  alias Deeper_Hub.Core.Data.DBConnection.Pool
  alias Deeper_Hub.Core.Data.DBConnection.SchemaAdapter
  alias Deeper_Hub.Core.Data.DBConnection.Query
  
  @doc """
  Especificação para supervisores.
  
  ## Parâmetros
  
    - `opts`: Opções para inicialização
  
  ## Retorno
  
    - Mapa de especificação do child
  """
  def child_spec(_opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, []},
      type: :worker,
      restart: :permanent,
      shutdown: 500
    }
  end
  
  @doc """
  Inicia o módulo Facade.
  
  Este módulo não mantém estado, apenas delega para o Pool.
  
  ## Retorno
  
    - `{:ok, pid}` em caso de sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_link do
    # Como este módulo é apenas uma fachada sem estado,
    # iniciamos um processo gen_server simples que não faz nada
    Task.start_link(fn -> 
      Process.flag(:trap_exit, true)
      receive do
        {:EXIT, _, _} -> :ok
      end
    end)
  end
  
  @doc """
  Inicia o pool de conexões.
  
  ## Parâmetros
  
    - `opts`: Opções para o pool de conexões
  
  ## Retorno
  
    - `{:ok, pid}` se o pool for iniciado com sucesso
    - `{:error, reason}` em caso de falha
  """
  def start_pool(opts \\ []) do
    Pool.start_link(opts)
  end
  
  @doc """
  Executa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - `{:ok, result}` se a consulta for executada com sucesso
    - `{:error, reason}` em caso de falha
  """
  defdelegate query(query, params \\ [], opts \\ []), to: Pool
  
  @doc """
  Executa uma consulta SQL e retorna o primeiro resultado.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - `{:ok, row}` se a consulta for executada com sucesso e retornar resultados
    - `{:ok, nil}` se a consulta for executada com sucesso mas não retornar resultados
    - `{:error, reason}` em caso de falha
  """
  defdelegate query_one(query, params \\ [], opts \\ []), to: Pool
  
  @doc """
  Executa uma consulta SQL dentro de uma transação.
  
  ## Parâmetros
  
    - `fun`: Função que recebe a conexão e executa operações dentro da transação
    - `opts`: Opções da transação
  
  ## Retorno
  
    - `{:ok, result}` se a transação for executada com sucesso
    - `{:error, reason}` em caso de falha
  """
  defdelegate transaction(fun, opts \\ []), to: Pool
  
  @doc """
  Prepara uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `opts`: Opções de preparação
  
  ## Retorno
  
    - `{:ok, prepared_query}` se a consulta for preparada com sucesso
    - `{:error, reason}` em caso de falha
  """
  defdelegate prepare(query, opts \\ []), to: Pool
  
  @doc """
  Prepara e executa uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - `{:ok, prepared_query, result}` se a consulta for preparada e executada com sucesso
    - `{:error, reason}` em caso de falha
  """
  defdelegate prepare_execute(query, params \\ [], opts \\ []), to: Pool
  
  @doc """
  Cria um stream para uma consulta SQL.
  
  ## Parâmetros
  
    - `query`: A consulta SQL
    - `params`: Parâmetros da consulta
    - `opts`: Opções de execução
  
  ## Retorno
  
    - Um stream para a consulta
  """
  defdelegate stream(query, params \\ [], opts \\ []), to: Pool
  
  @doc """
  Verifica o status da conexão.
  
  ## Parâmetros
  
    - `opts`: Opções da verificação
  
  ## Retorno
  
    - `{:ok, status}` com o status da conexão
    - `{:error, reason}` em caso de falha
  """
  defdelegate status(opts \\ []), to: Pool
  
  @doc """
  Cria uma nova consulta SQL estruturada.
  
  ## Parâmetros
  
    - `statement`: A consulta SQL
    - `params`: Parâmetros da consulta (opcional)
  
  ## Retorno
  
    - Uma struct %Query{} representando a consulta
  """
  defdelegate new_query(statement, params \\ []), to: Query, as: :new
  
  # Operações de schema
  
  @doc """
  Insere um novo registro no banco de dados.
  
  ## Parâmetros
  
    - `schema`: O módulo do schema Ecto
    - `attrs`: Atributos para o novo registro
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, struct}` se o registro for inserido com sucesso
    - `{:error, changeset}` em caso de falha na validação
    - `{:error, reason}` em caso de falha no banco de dados
  """
  defdelegate insert(schema, attrs, opts \\ []), to: SchemaAdapter
  
  @doc """
  Busca um registro pelo ID.
  
  ## Parâmetros
  
    - `schema`: O módulo do schema Ecto
    - `id`: O ID do registro a ser buscado
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, struct}` se o registro for encontrado
    - `{:error, :not_found}` se o registro não for encontrado
    - `{:error, reason}` em caso de falha no banco de dados
  """
  defdelegate get(schema, id, opts \\ []), to: SchemaAdapter
  
  @doc """
  Atualiza um registro existente.
  
  ## Parâmetros
  
    - `struct`: A struct Ecto a ser atualizada
    - `attrs`: Novos atributos para o registro
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, struct}` se o registro for atualizado com sucesso
    - `{:error, changeset}` em caso de falha na validação
    - `{:error, reason}` em caso de falha no banco de dados
  """
  defdelegate update(struct, attrs, opts \\ []), to: SchemaAdapter
  
  @doc """
  Deleta um registro.
  
  ## Parâmetros
  
    - `struct`: A struct Ecto a ser deletada
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, struct}` se o registro for deletado com sucesso
    - `{:error, reason}` em caso de falha no banco de dados
  """
  defdelegate delete(struct, opts \\ []), to: SchemaAdapter
  
  @doc """
  Lista todos os registros de um schema, com opções de filtro e paginação.
  
  ## Parâmetros
  
    - `schema`: O módulo do schema Ecto
    - `filters`: Condições de filtro (ex: `[name: "John", age: 30]`)
    - `opts`: Opções de paginação (`:limit`, `:offset`)
  
  ## Retorno
  
    - `{:ok, list_of_structs}` contendo a lista de registros
    - `{:error, reason}` em caso de falha no banco de dados
  """
  defdelegate list(schema, filters \\ [], opts \\ []), to: SchemaAdapter
  
  @doc """
  Conta o número de registros de um schema, com opções de filtro.
  
  ## Parâmetros
  
    - `schema`: O módulo do schema Ecto
    - `filters`: Condições de filtro (ex: `[name: "John", age: 30]`)
    - `opts`: Opções adicionais
  
  ## Retorno
  
    - `{:ok, count}` contendo o número de registros
    - `{:error, reason}` em caso de falha no banco de dados
  """
  defdelegate count(schema, filters \\ [], opts \\ []), to: SchemaAdapter
end
