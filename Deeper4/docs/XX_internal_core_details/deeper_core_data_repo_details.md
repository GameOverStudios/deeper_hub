# Documentação Deeper: `Deeper.Core.Data.Repo` - Detalhes do Repositório de Dados

O módulo `Deeper.Core.Data.Repo` é o principal ponto de interface para todas as interações com o banco de dados SQLite no backend \"Deeper\". Ele abstrai o uso direto da biblioteca `DBConnection` e fornece um conjunto de funções convenientes para executar queries SQL, gerenciar transações e mapear resultados.

**Localização do Código:** `lib/deeper/core/data/repo.ex`

## 1. Responsabilidades Principais

*   **Gerenciamento de Conexões:**
    *   Iniciar e supervisionar um pool de conexões com o banco de dados SQLite usando `DBConnection` (provavelmente via `Postgrex. কিন্তু SQLite` ou `Ecto.Adapters.SQLite3` se usarmos o adapter do Ecto apenas para `DBConnection` sem o Ecto.Repo completo, ou uma biblioteca SQLite específica como `exqlite`).
    *   Fornecer conexões do pool para a execução de queries.
*   **Execução de Queries SQL:**
    *   Oferecer funções para executar queries DDL (Data Definition Language, ex: `CREATE TABLE` nas migrações) e DML (Data Manipulation Language, ex: `SELECT`, `INSERT`, `UPDATE`, `DELETE`).
    *   Lidar com a passagem segura de parâmetros para as queries (prevenindo SQL injection).
*   **Mapeamento de Resultados:**
    *   Converter os resultados brutos das queries (geralmente listas de tuplas ou listas de listas) em formatos mais utilizáveis em Elixir, como listas de mapas ou listas de structs.
*   **Gerenciamento de Transações:**
    *   Fornecer uma maneira de executar um conjunto de operações de banco de dados dentro de uma transação atômica.

## 2. Configuração e Inicialização

*   O `Deeper.Core.Data.Repo` será provavelmente iniciado como parte da árvore de supervisão da aplicação \"Deeper\".
*   A configuração do banco de dados (ex: caminho para o arquivo SQLite) será lida do arquivo de configuração da aplicação (ex: `config/config.exs`).

**Exemplo de Configuração (em `config/config.exs`):**

```elixir
config :deeper, Deeper.Core.Data.Repo,
  adapter: Ecto.Adapters.SQLite3, # Ou o adapter DBConnection apropriado para SQLite
  database: \"deeper_dev.db\",
  pool_size: 10
```

```elixir
# lib/deeper/application.ex
children = [
  Deeper.Core.Data.Repo,
  // ... outros workers e supervisors
]
```

```elixir
    sql = \"CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT);\"
    Deeper.Core.Data.Repo.execute(sql, [])
```

```elixir
    sql = \"SELECT id, name FROM users WHERE status = ?;\"
    case Deeper.Core.Data.Repo.query(sql, [\"active\"]) do
      {:ok, %{rows: user_rows, columns: user_columns}} ->
        # Processar user_rows e user_columns
      {:error, reason} -> # Tratar erro
    end
```

```elixir
    sql = \"SELECT id, name FROM users WHERE id = ? LIMIT 1;\"
    Deeper.Core.Data.Repo.one(sql, [1])
```

```elixir
    Deeper.Core.Data.Repo.transaction(fn ->
      with {:ok, user} <- Deeper.Core.Data.Repo.insert_user_sql(params1), // Função hipotética que usa Repo.execute
           {:ok, _profile} <- Deeper.Core.Data.Repo.insert_profile_sql(user.id, params2) do
        {:ok, user}
      else
        {:error, reason} -> {:rollback, reason} // ou apenas :rollback
      end
    end)
```

```elixir
# lib/deeper/content/market_repo.ex
defmodule Deeper.Content.MarketRepo do
  alias Deeper.Core.Data.Repo
  alias Deeper.Content.Market.Entry

  def get_entry_by_id(id) do
    sql = \"SELECT * FROM bx_market_entries WHERE id = ? LIMIT 1;\"
    case Repo.one(sql, [id]) do
      {:ok, nil} -> {:error, :not_found}
      {:ok, entry_map} -> {:ok, struct(Entry, entry_map)} // Ou um mapeamento mais explícito
      {:error, reason} -> {:error, reason}
    end
  end

  # Função auxiliar para mapear colunas para chaves de struct/mapa se os nomes diferirem
  # ou para converter tipos (ex: booleanos de 0/1 para true/false)
  defp map_row_to_entry_struct(row_map) do
    # Exemplo:
    # %Entry{
    #   id: row_map[\"id\"],
    #   title: row_map[\"title\"],
    #   active: row_map[\"active\"] == 1, # Conversão de int para boolean
    #   added: NaiveDateTime.from_unix!(row_map[\"added\"], :second) # Se armazenado como Unix timestamp
    #   ...
    # }
    struct(Entry, row_map) # Simples se os nomes das colunas e chaves do struct coincidirem
  end
end
```

**Exemplo de Inicialização no Supervisor da Aplicação:**

## 3. Interface de Funções (API do Módulo `Repo`)

A interface pública do `Deeper.Core.Data.Repo` poderia ser semelhante a:

### `Repo.execute(sql_statement :: String.t(), params :: list(), opts :: Keyword.t()) :: {:ok, DBConnection.result_t()} | {:error, any()}`
*   **Descrição:** Executa uma declaração SQL que não se espera que retorne um conjunto de resultados significativo (ex: DDL, `INSERT`, `UPDATE`, `DELETE` sem cláusula `RETURNING` complexa, ou quando o número de linhas afetadas é o principal interesse).
*   **`sql_statement`:** A string SQL.
*   **`params`:** Lista de parâmetros para os placeholders (`?`) na string SQL.
*   **`opts`:** Opções para `DBConnection` (ex: `:timeout`).
*   **Retorno:**
    *   `{:ok, %DBConnection.Result{num_rows: count, ...}}`: Em sucesso, retorna uma struct de resultado da `DBConnection`, onde `num_rows` pode indicar o número de linhas afetadas.
    *   `{:error, reason}`: Em caso de falha.
*   **Uso Típico:** Migrações, `INSERT`s simples, `UPDATE`s, `DELETE`s.

    **Exemplo (dentro de uma migração):**

### `Repo.query(sql_query :: String.t(), params :: list(), opts :: Keyword.t()) :: {:ok, %{columns: [String.t()], rows: [[any()]]}} | {:ok, %{num_rows: integer(), ...}} | {:error, any()}`
*   **Descrição:** Executa uma query SQL (tipicamente `SELECT`) que retorna um conjunto de resultados.
*   **`sql_query`:** A string SQL da query.
*   **`params`:** Lista de parâmetros.
*   **`opts`:** Opções.
*   **Retorno:**
    *   `{:ok, %DBConnection.Result{columns: [\"id\", \"name\"], rows: [[1, \"Alice\"], [2, \"Bob\"]]}}`: Em sucesso para `SELECT`, retorna uma struct com os nomes das colunas e uma lista de listas representando as linhas.
    *   `{:ok, %DBConnection.Result{num_rows: count, ...}}`: Para queries como `INSERT ... RETURNING ...` ou outras que podem retornar dados de forma diferente.
    *   `{:error, reason}`: Em caso de falha.
*   **Uso Típico:** Buscas de dados (SELECTs).

    **Exemplo:**

### `Repo.one(sql_query :: String.t(), params :: list(), opts :: Keyword.t()) :: {:ok, map() | nil} | {:error, any()}`
*   **Descrição:** Executa uma query `SELECT` e espera no máximo uma linha. Retorna a linha como um mapa (coluna -> valor) ou `nil` se nenhuma linha for encontrada.
*   **SQL:** A query deve ser escrita para retornar no máximo uma linha (ex: `LIMIT 1`).
*   **Retorno:**
    *   `{:ok, %{\"id\" => 1, \"name\" => \"Alice\"}}`: Se uma linha for encontrada.
    *   `{:ok, nil}`: Se nenhuma linha for encontrada.
    *   `{:error, reason}`: Em caso de falha ou se mais de uma linha for retornada (pode ser uma decisão de design lançar um erro neste caso).
*   **Implementação Interna:** Usaria `Repo.query/3` e depois mapearia a primeira linha (se existir) para um mapa.

    **Exemplo:**

### `Repo.all(sql_query :: String.t(), params :: list(), opts :: Keyword.t()) :: {:ok, [map()]} | {:error, any()}`
*   **Descrição:** Executa uma query `SELECT` e retorna todas as linhas como uma lista de mapas (coluna -> valor).
*   **Retorno:**
    *   `{:ok, [%{\"id\" => 1, \"name\" => \"Alice\"}, %{\"id\" => 2, \"name\" => \"Bob\"}]}`: Lista de mapas.
    *   `{:ok, []}`: Se nenhuma linha for encontrada.
    *   `{:error, reason}`: Em caso de falha.
*   **Implementação Interna:** Usaria `Repo.query/3` e depois mapearia cada linha para um mapa.

### `Repo.transaction(fun :: (() -> {:ok, any()} | {:error, any() | :rollback} | :rollback), opts :: Keyword.t()) :: {:ok, result :: any()} | {:error, reason :: any()}`
*   **Descrição:** Executa uma função dentro de uma transação de banco de dados.
*   **`fun`:** Uma função anônima que recebe a conexão da transação (ou opera implicitamente nela).
    *   Se a função retornar `{:ok, value}`, a transação é commitada e `{:ok, value}` é retornado por `Repo.transaction`.
    *   Se a função retornar `{:error, reason}` ou `:rollback` (ou um valor explícito como `{:rollback, reason}`), a transação é desfeita (rollback) e `{:error, reason}` é retornado.
    *   Qualquer exceção dentro da função também causará um rollback.
*   **`opts`:** Opções para `DBConnection.transaction`.
*   **Implementação Interna:** Usaria `DBConnection.transaction/3` ou uma função similar do adapter SQLite.

    **Exemplo:**

## 4. Mapeamento de Resultados (Interno ou por Quem Chama)

O `Repo.query/3` retorna dados brutos (`%{columns: [...], rows: [...]}`). O mapeamento para structs ou mapas mais amigáveis pode ocorrer:

*   **Dentro de funções de conveniência no próprio `Repo`:** Como `Repo.one/3` e `Repo.all/3` que retornam mapas.
*   **Nos módulos de Repositório específicos do contexto (Recomendado):** Ex: `Deeper.Content.MarketRepo` teria funções como `get_entry_struct(id)` que chamam `Repo.one/3` e depois mapeiam o resultado para `%Deeper.Content.Market.Entry{}`.

**Exemplo de Mapeamento em um Repo de Contexto:**

## 5. Considerações de Performance e Segurança

*   **Pool de Conexões:** O uso correto do pool de `DBConnection` é fundamental para a performance.
*   **Prevenção de SQL Injection:** Sempre usar parâmetros vinculados (`?`) e nunca interpolar diretamente dados do usuário em strings SQL. O `DBConnection` lida com a sanitização de parâmetros vinculados.
*   **Queries Eficientes:** O `Repo` apenas executa o SQL fornecido. A responsabilidade de escrever SQL otimizado recai sobre os desenvolvedores que usam o `Repo` (ver `sql_optimization_notes.md`).

Este módulo `Deeper.Core.Data.Repo` atuará como uma camada fina, mas essencial, sobre `DBConnection`, fornecendo uma API consistente e um pouco mais de alto nível para interações com o banco de dados SQLite no projeto \"Deeper\".