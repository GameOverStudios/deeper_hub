defmodule Deeper_Hub.Core.Data.PaginationTest do
<<<<<<< HEAD
  @moduledoc """
  Testes para o módulo Pagination.
  
  Este módulo testa as funcionalidades de paginação de resultados,
  garantindo que a paginação funcione corretamente.
  """
  
=======
>>>>>>> a7eaa30fe0070442f8e291be40ec02441ff2483a
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Pagination
  alias Deeper_Hub.Core.Data.Repository
<<<<<<< HEAD
  alias Deeper_Hub.Core.Data.Repo
  alias Deeper_Hub.Core.Schemas.User
  
  # Configuração para cada teste
  setup do
    # Inicia uma transação para cada teste
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Repo)
    
    # Permite o uso de transações aninhadas
    Ecto.Adapters.SQL.Sandbox.mode(Repo, {:shared, self()})
    
    # Limpa a tabela para garantir um estado conhecido
    Repo.delete_all(User)
    
    # Insere vários usuários para testar a paginação
    for i <- 1..20 do
      {:ok, _} = Repository.insert(User, %{
        username: "user#{i}",
        email: "user#{i}@example.com",
        password: "password"
      })
    end
    
    :ok
  end
  
  describe "paginate/5" do
    test "pagina resultados corretamente" do
      # Testa a primeira página com 5 itens por página
      assert {:ok, result} = Pagination.paginate(User, 1, 5)
      assert result.page == 1
      assert result.page_size == 5
      assert result.total == 20
      assert result.total_pages == 4
      assert length(result.items) == 5
      
      # Verifica se os itens são os esperados
      assert Enum.all?(result.items, fn item -> 
        String.match?(item.username, ~r/user\d+/)
      end)
    end
    
    test "pagina resultados com filtros" do
      # Insere alguns usuários com username específico para testar filtros
      for i <- 1..5 do
        {:ok, _} = Repository.insert(User, %{
          username: "admin#{i}",
          email: "admin#{i}@example.com",
          password: "password"
        })
      end
      
      # Testa paginação com filtro
      assert {:ok, result} = Pagination.paginate(User, 1, 10, %{})
      assert result.total == 25  # 20 usuários normais + 5 admins
      
      # Testa paginação com filtro específico
      assert {:ok, filtered_result} = Pagination.paginate(User, 1, 10, %{username: "admin1"})
      assert filtered_result.total == 1
      assert hd(filtered_result.items).username == "admin1"
    end
    
    test "lida com páginas vazias" do
      # Testa uma página que não existe (além do total de páginas)
      assert {:ok, result} = Pagination.paginate(User, 10, 5)
      assert result.page == 10
      assert result.page_size == 5
      assert result.total == 20
      assert result.total_pages == 4
      assert result.items == []
    end
    
    test "lida com valores de página inválidos" do
      # Testa com número de página negativo (deve usar 1)
      assert {:ok, result} = Pagination.paginate(User, -1, 5)
      assert result.page == 1
      assert length(result.items) == 5
      
      # Testa com tamanho de página negativo (deve usar 1)
      assert {:ok, result} = Pagination.paginate(User, 1, -5)
      assert result.page_size == 1
      assert length(result.items) == 1
      
      # Testa com tamanho de página muito grande (deve limitar a 100)
      assert {:ok, result} = Pagination.paginate(User, 1, 500)
      assert result.page_size == 100
    end
    
    test "aplica ordenação corretamente" do
      # Testa ordenação por username em ordem ascendente
      assert {:ok, result_asc} = Pagination.paginate(User, 1, 20, %{}, order_by: [asc: :username])
      usernames_asc = Enum.map(result_asc.items, & &1.username)
      assert usernames_asc == Enum.sort(usernames_asc)
      
      # Testa ordenação por username em ordem descendente
      assert {:ok, result_desc} = Pagination.paginate(User, 1, 20, %{}, order_by: [desc: :username])
      usernames_desc = Enum.map(result_desc.items, & &1.username)
      assert usernames_desc == Enum.sort(usernames_desc, :desc)
    end
    
    test "lida com erros de banco de dados" do
      # Simula um erro de banco de dados usando um esquema inexistente
      # Cria um módulo temporário para o teste
      defmodule TempSchema do
        use Ecto.Schema
        
        @primary_key {:id, :binary_id, autogenerate: true}
        schema "nonexistent_table" do
          field :name, :string
        end
      end
      
      # Tenta paginar uma tabela que não existe
      assert {:error, _} = Pagination.paginate(TempSchema, 1, 10)
=======
  alias Deeper_Hub.Core.Data.Database
  
  # Configuração para executar uma vez antes de todos os testes deste módulo
  setup_all do
    # Inicializar o banco de dados para os testes
    :mnesia.stop()
    # Configura um diretório específico para testes
    test_mnesia_dir = Path.join(System.tmp_dir!(), "mnesia_test_#{:rand.uniform(1000000)}")
    File.mkdir_p!(test_mnesia_dir)
    :application.set_env(:mnesia, :dir, String.to_charlist(test_mnesia_dir))
    # Limpa o schema anterior
    :mnesia.delete_schema([node()])
    :mnesia.start()
    # Registra o diretório para limpeza após o teste
    on_exit(fn -> File.rm_rf!(test_mnesia_dir) end)
    
    # Inicializa o sistema de métricas
    alias Deeper_Hub.Core.Metrics
    Metrics.initialize()
    
    # Criar as tabelas necessárias em modo de teste (apenas em memória)
    result = Database.create_tables(test_mode: true)
    
    # Verificar se as tabelas foram criadas corretamente
    tables = :mnesia.system_info(:tables)
    IO.puts("\nInicializando banco de dados para testes de paginação...")
    IO.puts("Resultado da criação de tabelas: #{inspect(result)}")
    IO.puts("Tabelas existentes: #{inspect(tables)}")
    
    # Verificar se a tabela :users existe
    if Enum.member?(tables, :users) do
      # Verificar as propriedades da tabela
      record_name = :mnesia.table_info(:users, :record_name)
      attributes = :mnesia.table_info(:users, :attributes)
      IO.puts("Tabela :users - record_name: #{inspect(record_name)}, attributes: #{inspect(attributes)}")
      
      # Retornar o contexto para os testes
      %{tables: tables}
    else
      IO.puts("ERRO: Tabela :users não foi criada! Os testes podem falhar.")
      # Mesmo com erro, retornamos um mapa válido para o ExUnit não invalidar os testes
      # Os testes individuais irão falhar de forma mais informativa
      %{tables: [], error: :table_not_created}
    end
  end
  
  # Configuração para executar antes de cada teste
  setup context do
    # Verificar se as tabelas existem antes de tentar limpar
    tables = :mnesia.system_info(:tables)
    
    # Criar uma lista de teste para paginate_list (independente das tabelas)
    test_list = Enum.to_list(1..100)
    context = Map.put(context, :test_list, test_list)
    
    if Enum.member?(tables, :users) and Enum.member?(tables, :sessions) do
      # Limpar os dados das tabelas existentes
      :mnesia.clear_table(:users)
      :mnesia.clear_table(:sessions)
      
      # Inserir dados de teste para paginação
      insert_results = for id <- 1..20 do
        user = {:users, id, "user#{id}", "user#{id}@example.com", "hash#{id}", DateTime.utc_now()}
        Repository.insert(:users, user)
      end
      
      # Verificar se todas as inserções foram bem-sucedidas
      if Enum.all?(insert_results, fn result -> match?({:ok, _}, result) end) do
        {:ok, context}
      else
        failed_inserts = Enum.filter(insert_results, fn result -> not match?({:ok, _}, result) end)
        IO.puts("AVISO: Algumas inserções falharam: #{inspect(failed_inserts)}")
        {:ok, Map.put(context, :insert_errors, failed_inserts)}
      end
    else
      IO.puts("AVISO: Tabelas necessárias não existem, pulando inserção de dados de teste")
      {:ok, Map.put(context, :setup_error, :tables_not_found)}
    end
  end
  
  describe "paginate_list/2" do
    test "pagina uma lista corretamente - primeira página", %{test_list: list} do
      result = Pagination.paginate_list(list, %{page: 1, page_size: 10})
      
      assert result.page_number == 1
      assert result.page_size == 10
      assert result.total_entries == 100
      assert result.total_pages == 10
      assert length(result.entries) == 10
      assert hd(result.entries) == 1
      assert List.last(result.entries) == 10
    end
    
    test "pagina uma lista corretamente - página do meio", %{test_list: list} do
      result = Pagination.paginate_list(list, %{page: 5, page_size: 10})
      
      assert result.page_number == 5
      assert result.page_size == 10
      assert result.total_entries == 100
      assert result.total_pages == 10
      assert length(result.entries) == 10
      assert hd(result.entries) == 41
      assert List.last(result.entries) == 50
    end
    
    test "pagina uma lista corretamente - última página", %{test_list: list} do
      result = Pagination.paginate_list(list, %{page: 10, page_size: 10})
      
      assert result.page_number == 10
      assert result.page_size == 10
      assert result.total_entries == 100
      assert result.total_pages == 10
      assert length(result.entries) == 10
      assert hd(result.entries) == 91
      assert List.last(result.entries) == 100
    end
    
    test "pagina uma lista corretamente com tamanho de página personalizado", %{test_list: list} do
      result = Pagination.paginate_list(list, %{page: 2, page_size: 25})
      
      assert result.page_number == 2
      assert result.page_size == 25
      assert result.total_entries == 100
      assert result.total_pages == 4
      assert length(result.entries) == 25
      assert hd(result.entries) == 26
      assert List.last(result.entries) == 50
    end
    
    test "lida com página vazia (página além do total)", %{test_list: list} do
      result = Pagination.paginate_list(list, %{page: 11, page_size: 10})
      
      assert result.page_number == 11
      assert result.page_size == 10
      assert result.total_entries == 100
      assert result.total_pages == 10
      assert result.entries == []
    end
    
    test "lida com lista vazia" do
      result = Pagination.paginate_list([], %{page: 1, page_size: 10})
      
      assert result.page_number == 1
      assert result.page_size == 10
      assert result.total_entries == 0
      assert result.total_pages == 0
      assert result.entries == []
    end
    
    test "lida com tamanho de página zero ou negativo", %{test_list: list} do
      result_zero = Pagination.paginate_list(list, %{page: 1, page_size: 0})
      result_negative = Pagination.paginate_list(list, %{page: 1, page_size: -5})
      
      # Ambos devem ter comportamento similar
      assert result_zero.page_number == 1
      assert result_zero.page_size == 0
      assert result_zero.total_entries == 100
      assert result_zero.total_pages == 0
      assert result_zero.entries == []
      
      assert result_negative.page_number == 1
      assert result_negative.page_size == -5
      assert result_negative.total_entries == 100
      assert result_negative.total_pages == 0
      assert result_negative.entries == []
    end
    
    test "usa valores padrão quando não especificados", %{test_list: list} do
      result = Pagination.paginate_list(list, %{})
      
      # Valores padrão devem ser page: 1, page_size: 10
      assert result.page_number == 1
      assert result.page_size == 10
      assert result.total_entries == 100
      assert result.total_pages == 10
      assert length(result.entries) == 10
    end
  end
  
  describe "paginate_mnesia/2" do
    test "pagina resultados de uma tabela Mnesia - primeira página" do
      result = Pagination.paginate_mnesia(:users, %{page: 1, page_size: 5})
      
      assert result.page_number == 1
      assert result.page_size == 5
      assert result.total_entries == 20
      assert result.total_pages == 4
      assert length(result.entries) == 5
      
      # Verificar se todos os registros têm a estrutura correta
      Enum.each(result.entries, fn record ->
        assert match?({:users, _, _, _, _, _}, record)
      end)
      
      # Verificar se todos os registros têm ids válidos (não precisamos verificar a ordenação já que Mnesia não garante ordem)
      ids = Enum.map(result.entries, fn {_, id, _, _, _, _} -> id end)
      assert Enum.all?(ids, fn id -> is_integer(id) and id > 0 end)
    end
    
    test "pagina resultados de uma tabela Mnesia - última página" do
      result = Pagination.paginate_mnesia(:users, %{page: 4, page_size: 5})
      
      assert result.page_number == 4
      assert result.page_size == 5
      assert result.total_entries == 20
      assert result.total_pages == 4
      assert length(result.entries) == 5
      
      # Verificar se todos os registros têm a estrutura correta
      Enum.each(result.entries, fn record ->
        assert match?({:users, _, _, _, _, _}, record)
      end)
    end
    
    test "lida com página além do total" do
      result = Pagination.paginate_mnesia(:users, %{page: 5, page_size: 5})
      
      assert result.page_number == 5
      assert result.page_size == 5
      assert result.total_entries == 20
      assert result.total_pages == 4
      assert result.entries == []
    end
    
    test "lida com tabela vazia" do
      # Remover todos os registros da tabela users
      {:ok, records} = Repository.all(:users)
      Enum.each(records, fn record ->
        {_, id, _, _, _, _} = record
        Repository.delete(:users, id)
      end)
      
      result = Pagination.paginate_mnesia(:users, %{page: 1, page_size: 5})
      
      assert result.page_number == 1
      assert result.page_size == 5
      assert result.total_entries == 0
      assert result.total_pages == 0
      assert result.entries == []
    end
    
    test "lida com tabela inexistente" do
      result = Pagination.paginate_mnesia(:tabela_inexistente, %{page: 1, page_size: 5})
      
      # Deve retornar uma estrutura de paginação vazia, mesmo para tabela inexistente
      assert result.page_number == 1
      assert result.page_size == 5
      assert result.total_entries == 0
      assert result.total_pages == 0
      assert result.entries == []
    end
    
    test "lida com erro interno do Repository.all/1" do
      # Simular um erro interno no Repository.all/1 usando um mock
      # Como não temos uma biblioteca de mock disponível, vamos testar com uma tabela que sabemos que causará erro
      result = Pagination.paginate_mnesia(:schema, %{page: 1, page_size: 5})
      
      # Mesmo com erro interno, deve retornar uma estrutura de paginação vazia
      assert result.page_number == 1
      assert result.page_size == 5
      assert result.total_entries == 0
      assert result.total_pages == 0
      assert result.entries == []
    end
    
    test "usa valores padrão quando não especificados" do
      result = Pagination.paginate_mnesia(:users, %{})
      
      # Valores padrão devem ser page: 1, page_size: 10
      assert result.page_number == 1
      assert result.page_size == 10
      assert result.total_entries == 20
      assert result.total_pages == 2
      assert length(result.entries) == 10
>>>>>>> a7eaa30fe0070442f8e291be40ec02441ff2483a
    end
  end
end
