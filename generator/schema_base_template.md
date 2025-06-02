defmodule DeeperHub.Core.Data.SchemaBase do
  @moduledoc """
  Módulo base para schemas que fornece funcionalidades comuns para todos os schemas.
  Implementa operações CRUD básicas e funções de consulta avançadas com paginação e ordenação.
  """

  defmacro __using__(opts) do
    quote do
      import Ecto.Query
      alias DeeperHub.Core.Data.Repo
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
        page = Keyword.get(opts, :page, 1)
        page_size = Keyword.get(opts, :page_size, 20)
        order_by_field = Keyword.get(opts, :order_by, @primary_key)
        order_direction = Keyword.get(opts, :order_direction, :asc)
        
        try do
          query = from(t in @table_name)
          
          # Aplicar ordenação
          query = from(t in query, order_by: [{^order_direction, ^order_by_field}])
          
          # Contar total de registros
          total_count = Repo.aggregate(query, :count, @primary_key)
          
          # Aplicar paginação
          query = from(t in query, 
                      limit: ^page_size, 
                      offset: ^((page - 1) * page_size))
          
          # Executar consulta
          records = Repo.all(query)
          
          # Calcular metadados de paginação
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
        rescue
          error ->
            Logger.error("Falha ao buscar registros de #{@table_name}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha ao buscar registros: #{inspect(error)}"}
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
        try do
          case Repo.get(@table_name, id) do
            nil ->
              Logger.info("#{@table_name} com ID #{id} não encontrado", module: @schema_module)
              {:error, :not_found}
            record ->
              {:ok, record}
          end
        rescue
          error ->
            Logger.error("Falha ao buscar #{@table_name} com ID: #{id}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha ao buscar registro: #{inspect(error)}"}
        end
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
        page = Keyword.get(opts, :page, 1)
        page_size = Keyword.get(opts, :page_size, 20)
        order_by_field = Keyword.get(opts, :order_by, @primary_key)
        order_direction = Keyword.get(opts, :order_direction, :asc)
        
        try do
          # Construir query base com o filtro
          query = from(t in @table_name, where: field(t, ^field) == ^value)
          
          # Contar total de registros
          total_count = Repo.aggregate(query, :count, @primary_key)
          
          # Aplicar ordenação
          query = from(t in query, order_by: [{^order_direction, ^order_by_field}])
          
          # Aplicar paginação
          query = from(t in query, 
                      limit: ^page_size, 
                      offset: ^((page - 1) * page_size))
          
          # Executar consulta
          records = Repo.all(query)
          
          # Calcular metadados de paginação
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
        rescue
          error ->
            Logger.error("Falha ao buscar #{@table_name} por #{field}: #{value}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha ao buscar registros: #{inspect(error)}"}
        end
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
        page = Keyword.get(opts, :page, 1)
        page_size = Keyword.get(opts, :page_size, 20)
        order_by_field = Keyword.get(opts, :order_by, @primary_key)
        order_direction = Keyword.get(opts, :order_direction, :asc)
        
        try do
          # Construir query base
          query = from(t in @table_name)
          
          # Aplicar filtros
          query = Enum.reduce(filters, query, fn {field, value}, query_acc ->
            from(t in query_acc, where: field(t, ^field) == ^value)
          end)
          
          # Contar total de registros
          total_count = Repo.aggregate(query, :count, @primary_key)
          
          # Aplicar ordenação
          query = from(t in query, order_by: [{^order_direction, ^order_by_field}])
          
          # Aplicar paginação
          query = from(t in query, 
                      limit: ^page_size, 
                      offset: ^((page - 1) * page_size))
          
          # Executar consulta
          records = Repo.all(query)
          
          # Calcular metadados de paginação
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
        rescue
          error ->
            Logger.error("Falha na busca avançada de #{@table_name}, filtros: #{inspect(filters)}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha na busca avançada: #{inspect(error)}"}
        end
      end

      @doc """
      Cria um novo registro.
      
      ## Parâmetros
      
        * `attrs` - Atributos para o novo registro
      
      ## Retorno
      
        * `{:ok, registro}` em caso de sucesso
        * `{:error, changeset}` em caso de erro de validação
        * `{:error, reason}` em caso de outro erro
      """
      def create(attrs) do
        try do
          Repo.insert(@table_name, attrs)
        rescue
          error ->
            Logger.error("Falha ao criar #{@table_name}, dados: #{inspect(attrs)}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha ao criar registro: #{inspect(error)}"}
        end
      end

      @doc """
      Atualiza um registro existente.
      
      ## Parâmetros
      
        * `id` - ID do registro a ser atualizado
        * `attrs` - Atributos a serem atualizados
      
      ## Retorno
      
        * `{:ok, registro}` em caso de sucesso
        * `{:error, :not_found}` se não encontrado
        * `{:error, changeset}` em caso de erro de validação
        * `{:error, reason}` em caso de outro erro
      """
      def update(id, attrs) do
        try do
          case Repo.get(@table_name, id) do
            nil ->
              Logger.info("#{@table_name} com ID #{id} não encontrado para atualização", module: @schema_module)
              {:error, :not_found}
            record ->
              Repo.update(@table_name, record, attrs)
          end
        rescue
          error ->
            Logger.error("Falha ao atualizar #{@table_name} com ID: #{id}, dados: #{inspect(attrs)}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha ao atualizar registro: #{inspect(error)}"}
        end
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
        try do
          case Repo.get(@table_name, id) do
            nil ->
              Logger.info("#{@table_name} com ID #{id} não encontrado para exclusão", module: @schema_module)
              {:error, :not_found}
            record ->
              Repo.delete(@table_name, record)
          end
        rescue
          error ->
            Logger.error("Falha ao excluir #{@table_name} com ID: #{id}, erro: #{inspect(error)}", module: @schema_module)
            {:error, "Falha ao excluir registro: #{inspect(error)}"}
        end
      end

      # Permitir que os módulos que usam esta base possam sobrescrever funções
      defoverridable [all: 1, get: 1, get_by: 3, search: 2, create: 1, update: 2, delete: 1]
    end
  end
end
