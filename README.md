# DeeperHub Elixir Application

Bem-vindo ao DeeperHub! Esta é uma aplicação Elixir projetada para fornecer uma base robusta para gerenciamento de dados, utilizando Mnesia como backend de banco de dados.

## Features Principais

*   **Banco de Dados Mnesia**:
    *   Utiliza Mnesia para persistência de dados, configurado para rodar em memória (com persistência em disco se configurado).
    *   Gerenciamento automático de criação de tabelas na inicialização.
*   **Repositório Dinâmico (`Deeper_Hub.Core.Data.Repository`)**:
    *   Fornece uma interface genérica para operações CRUD (Create, Read, Update, Delete) em qualquer tabela Mnesia.
    *   Lida dinamicamente com a estrutura dos registros da tabela (nome e aridade) para construir queries.
*   **Paginação (`Deeper_Hub.Core.Data.Pagination`)**:
    *   Funcionalidade para paginar listas de dados.
    *   Funcionalidade para paginar resultados diretamente de tabelas Mnesia, utilizando o `Repository.all/1` para buscar os dados.
*   **Logging Estruturado (`Deeper_Hub.Core.Logger`)**:
    *   Módulo de logging customizado com níveis (info, warning, error, debug) e formatação colorida para facilitar a visualização.
*   **Estrutura Modular**:
    *   Organizado em módulos com responsabilidades bem definidas, seguindo princípios de código limpo.

## Iniciando a Aplicação

1.  **Clone o repositório** (se aplicável).
2.  **Instale as dependências**:
    ```bash
    mix deps.get
    ```
3.  **Compile o projeto**:
    ```bash
    mix compile
    ```
4.  **Inicie o console interativo `iex` com a aplicação**:
    ```bash
    iex -S mix
    ```
    Ao iniciar, o sistema tentará criar as tabelas Mnesia definidas em `Deeper_Hub.Core.Data.Database` (ex: `:users`, `:sessions`).

## Comandos de Acesso ao Banco de Dados (via `iex -S mix`)

Os exemplos abaixo assumem uma tabela `:users` com a seguinte estrutura de registro:
`{:users, id :: integer(), username :: String.t(), email :: String.t(), password_hash :: String.t(), created_at :: DateTime.t()}`

Assegure-se que a tabela `:users` esteja definida em `Deeper_Hub.Core.Data.Database.schema/0` com os atributos correspondentes e os tipos `:set` ou `:ordered_set`, e `record_name: :users`.

```elixir
# Dentro da sessão iex:

# --- Configuração Inicial ---
# Inicie o console interativo com a aplicação
# $ iex -S mix

# Importe os módulos necessários
alias Deeper_Hub.Core.Data.Repository
alias Deeper_Hub.Core.Data.Pagination

# --- Inicialização do Banco de Dados ---
# O banco de dados Mnesia é inicializado automaticamente ao iniciar a aplicação
# As tabelas definidas em Deeper_Hub.Core.Data.Database.schema/0 são criadas se não existirem

# --- Operações CRUD (Create, Read, Update, Delete) ---

# 1. INSERT - Criar novos registros na tabela :users
# Sintaxe: Repository.insert(table_atom, record_tuple)
# Retorna: {:ok, record_tuple} ou {:error, reason}

# Inserir um usuário com ID 1
user1 = {:users, 1, "alice", "alice@example.com", "hash_alice", DateTime.utc_now()}
Repository.insert(:users, user1)

# Inserir um usuário com ID 2
user2 = {:users, 2, "bob", "bob@example.com", "hash_bob", DateTime.utc_now()}
Repository.insert(:users, user2)

# Inserir um usuário com ID 3
user3 = {:users, 3, "charlie", "charlie@example.com", "hash_charlie", DateTime.utc_now()}
Repository.insert(:users, user3)

# 2. FIND - Buscar um registro pela chave primária
# Sintaxe: Repository.find(table_atom, primary_key)
# Retorna: {:ok, record_tuple} ou {:error, :not_found}

# Buscar o usuário com ID 1
Repository.find(:users, 1)

# Buscar um usuário que não existe (deve retornar {:error, :not_found})
Repository.find(:users, 999)

# 3. ALL - Buscar todos os registros de uma tabela
# Sintaxe: Repository.all(table_atom)
# Retorna: {:ok, list_of_records} ou {:error, reason}

# Buscar todos os usuários
Repository.all(:users)

# 4. MATCH - Buscar registros que correspondem a um padrão
# Sintaxe: Repository.match(table_atom, [])
# A match_spec é gerada automaticamente com base na aridade da tabela
# Retorna: {:ok, list_of_matching_records} ou {:error, reason}

# Buscar todos os usuários (similar a all/1)
Repository.match(:users, [])

# 5. UPDATE - Atualizar um registro existente
# Sintaxe: Repository.update(table_atom, updated_record_tuple)
# Retorna: {:ok, updated_record_tuple} ou {:error, reason}

# Atualizar o usuário com ID 1
updated_user1 = {:users, 1, "alice_updated", "alice.new@example.com", "new_hash_alice", DateTime.utc_now()}
Repository.update(:users, updated_user1)

# Verificar a atualização
Repository.find(:users, 1)

# 6. DELETE - Remover um registro pela chave primária
# Sintaxe: Repository.delete(table_atom, primary_key)
# Retorna: {:ok, :deleted} ou {:error, reason}

# Deletar o usuário com ID 3
Repository.delete(:users, 3)

# Verificar que o usuário foi deletado
Repository.find(:users, 3)  # Deve retornar {:error, :not_found}

# Verificar quantos usuários restam
{:ok, remaining_users} = Repository.all(:users)
IO.puts("Usuários restantes: #{length(remaining_users)}")

# --- Operações de Paginação ---

# 1. Inserir mais alguns usuários para testar a paginação
for id <- 4..15 do
  user = {:users, id, "user#{id}", "user#{id}@example.com", "hash_user#{id}", DateTime.utc_now()}
  Repository.insert(:users, user)
end

# 2. PAGINATE_MNESIA - Paginar resultados de uma tabela Mnesia
# Sintaxe: Pagination.paginate_mnesia(table_atom, pagination_params_map)
# pagination_params_map: %{page: integer(), page_size: integer()}
# Retorna: %{entries: list, page_number: integer, page_size: integer, total_entries: integer, total_pages: integer}

# Paginar a tabela :users, página 1, 5 itens por página
page1 = Pagination.paginate_mnesia(:users, %{page: 1, page_size: 5})
IO.inspect(page1, label: "Página 1")

# Paginar a tabela :users, página 2, 5 itens por página
page2 = Pagination.paginate_mnesia(:users, %{page: 2, page_size: 5})
IO.inspect(page2, label: "Página 2")

# 3. PAGINATE_LIST - Paginar uma lista qualquer
# Sintaxe: Pagination.paginate_list(list_of_items, pagination_params_map)
# Retorna: Mesmo formato do paginate_mnesia/2

# Criar uma lista de números de 1 a 100
my_list = Enum.to_list(1..100)

# Paginar a lista, página 3, 10 itens por página
paginated_list = Pagination.paginate_list(my_list, %{page: 3, page_size: 10})
IO.inspect(paginated_list, label: "Lista Paginada")
```

## Resolução de Problemas Comuns

### Erro `:badarg` ao usar `Repository.all/1` ou `Repository.match/2`

Se você encontrar um erro `:badarg` ao chamar `Repository.all/1` ou `Repository.match/2`, isso pode ser devido a um problema com a match_spec usada internamente. A solução implementada no código atual é:

1. Usar uma match_head com apenas wildcards (`:_`) para todos os campos, sem especificar o nome da tabela no match_head
2. Construir a match_spec como `[{match_head, [], [:'$_']}]`

Exemplo de logs quando o erro ocorre:

```
[TRACE] :mnesia.select/2 CAUSOU EXCEÇÃO:
[TRACE]   Kind: :exit
[TRACE]   Reason: {:aborted, {:badarg, [:users, [{{{:users, :_, :_, :_, :_, :_}, [], [:\"$_\"]}}]]}}
```

### Verificação da Estrutura da Tabela

Para verificar a estrutura de uma tabela Mnesia, você pode usar os seguintes comandos:

```elixir
# Verificar o nome do registro da tabela
:mnesia.table_info(:users, :record_name)

# Verificar a aridade da tabela (número de campos + 1)
:mnesia.table_info(:users, :arity)

# Verificar os atributos da tabela
:mnesia.table_info(:users, :attributes)
```

### Limpeza do Banco de Dados

Se você precisar limpar o banco de dados Mnesia e recomeçar do zero:

```elixir
# Parar o Mnesia
:mnesia.stop()

# Deletar o schema (isso remove todos os dados!)
:mnesia.delete_schema([node()])

# Reiniciar o Mnesia e recriar as tabelas
:mnesia.start()
Deeper_Hub.Core.Data.Database.create_tables()
```
