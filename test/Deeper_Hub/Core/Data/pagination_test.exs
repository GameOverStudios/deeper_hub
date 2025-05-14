defmodule Deeper_Hub.Core.Data.PaginationTest do
  @moduledoc """
  Testes para o módulo Pagination.
  
  Este módulo testa as funcionalidades de paginação de resultados,
  garantindo que a paginação funcione corretamente.
  """
  
  use ExUnit.Case
  
  alias Deeper_Hub.Core.Data.Pagination
  alias Deeper_Hub.Core.Data.Repository
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
    end
  end
end
