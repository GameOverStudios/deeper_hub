defmodule DeeperHub.Core.Data.SchemaBase do
  @moduledoc """
  Módulo base para schemas que fornece funcionalidades comuns para todos os schemas.
  Implementa operações CRUD básicas e funções de consulta avançadas com paginação e ordenação.
  Utiliza DeeperHub.Core.Data.Crud para operações de banco de dados diretas com db_connection.
  """

  defmacro __using__(opts) do
    quote do
      alias DeeperHub.Core.Data.Crud
      alias DeeperHub.Core.Logger
      require DeeperHub.Core.Logger

      @table_name unquote(opts[:table_name] || raise "É necessário fornecer :table_name")
      @primary_key unquote(opts[:primary_key] || :id)
      @schema_module __MODULE__

      @doc """
      Retorna todos os registros com suporte a paginação e ordenação.
      
      ## Parâmetros
      
        * `opts` - Opções de consulta:
          * `:page` - Número da página (padrão: 1)
          * `:page_size` - Tamanho da página (padrão: 20)
          * `:order_by` - Campo para ordenação (padrão: primary_key)
          * `:order_direction` - Direção da ordenação (:asc ou :desc, padrão: :asc)
      
      ## Retorno
      
        * `{:ok, %{data: [registros], metadata: metadata}}` em caso de sucesso
        * `{:error, reason}` em caso de erro
      """
      def all(opts \\ []) do
        case Crud.list(@table_name, %{}, opts) do
          {:ok, records} ->
            page = Keyword.get(opts, :page, 1)
            page_size = Keyword.get(opts, :page_size, 20)
            order_by_field = Keyword.get(opts, :order_by, @primary_key)
            order_direction = Keyword.get(opts, :order_direction, :asc)
            
            # Calcular metadados de paginação
            total_count = length(records)
            total_pages = ceil(total_count / page_size)
            
            metadata = %{
              page: page,
              page_size: page_size,
              total_count: total_count,
              total_pages: total_pages,
              order_by: order_by_field,
              order_direction: order_direction
            }
            
            {:ok, %{data: records, metadata: metadata}}
            
          {:error, reason} ->
            Logger.error("Falha ao buscar registros de #{@table_name}, erro: #{inspect(reason)}", 
              module: @schema_module
            )
            {:error, reason}
        end
      end

      @doc """
      Busca um registro específico pelo ID.
      
      ## Parâmetros
      
        * `id` - ID do registro a ser buscado
      
      ## Retorno
      
        * `{:ok, registro}` em caso de sucesso
        * `{:error, :not_found}` se não encontrado
        * `{:error, reason}` em caso de erro
      """
      def get(id) do
        Crud.get(@table_name, id)
      end

      @doc """
      Busca registros com base em um campo específico.
      
      ## Parâmetros
      
        * `field` - Campo a ser usado na busca
        * `value` - Valor a ser buscado
        * `opts` - Opções de consulta (mesmas da função all/1)
      
      ## Retorno
      
        * `{:ok, %{data: [registros], metadata: metadata}}` em caso de sucesso
        * `{:error, reason}` em caso de erro
      """
      def get_by(field, value, opts \\ []) do
        # Criar um mapa de condições para o campo específico
        conditions = %{field => value}
        
        # Usar a função search com o mapa de condições
        search(conditions, opts)
      end

      @doc """
      Busca avançada com múltiplos filtros, paginação e ordenação.
      
      ## Parâmetros
      
        * `filters` - Mapa de filtros no formato %{field => value}
        * `opts` - Opções de consulta (mesmas da função all/1)
      
      ## Retorno
      
        * `{:ok, %{data: [registros], metadata: metadata}}` em caso de sucesso
        * `{:error, reason}` em caso de erro
      """
      def search(filters \\ %{}, opts \\ []) do
        # Implementação simplificada que passa os filtros para o Crud.list
        # O módulo Crud.list deve ser capaz de lidar com os filtros
        case Crud.list(@table_name, filters, opts) do
          {:ok, records} ->
            page = Keyword.get(opts, :page, 1)
            page_size = Keyword.get(opts, :page_size, 20)
            order_by_field = Keyword.get(opts, :order_by, @primary_key)
            order_direction = Keyword.get(opts, :order_direction, :asc)
            
            # Calcular metadados de paginação
            total_count = length(records)
            total_pages = ceil(total_count / page_size)
            
            metadata = %{
              page: page,
              page_size: page_size,
              total_count: total_count,
              total_pages: total_pages,
              order_by: order_by_field,
              order_direction: order_direction
            }
            
            {:ok, %{data: records, metadata: metadata}}
            
          {:error, reason} ->
            Logger.error("Falha na busca avançada de #{@table_name}, filtros: #{inspect(filters)}, erro: #{inspect(reason)}", 
              module: @schema_module
            )
            {:error, reason}
        end
      end

      @doc """
      Cria um novo registro.
      
      ## Parâmetros
      
        * `attrs` - Atributos para o novo registro
      
      ## Retorno
      
        * `{:ok, registro}` em caso de sucesso
        * `{:error, reason}` em caso de erro
      """
      def create(attrs) do
        Crud.create(@table_name, attrs)
      end

      @doc """
      Atualiza um registro existente.
      
      ## Parâmetros
      
        * `id` - ID do registro a ser atualizado
        * `attrs` - Atributos a serem atualizados
      
      ## Retorno
      
        * `{:ok, registro}` em caso de sucesso
        * `{:error, :not_found}` se não encontrado
        * `{:error, reason}` em caso de outro erro
      """
      def update(id, attrs) do
        Crud.update(@table_name, id, attrs)
      end

      @doc """
      Remove um registro.
      
      ## Parâmetros
      
        * `id` - ID do registro a ser removido
      
      ## Retorno
      
        * `{:ok, registro}` em caso de sucesso
        * `{:error, :not_found}` se não encontrado
        * `{:error, reason}` em caso de erro
      """
      def delete(id) do
        Crud.delete(@table_name, id)
      end

      # Permitir que os módulos que usam esta base possam sobrescrever funções
      defoverridable [all: 1, get: 1, get_by: 3, search: 2, create: 1, update: 2, delete: 1]
    end
  end
end
