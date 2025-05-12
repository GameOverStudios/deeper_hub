# Módulo: `DeeperHub.Shared.Utils.ListUtils` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Shared.Utils.ListUtils`

O módulo `DeeperHub.Shared.Utils.ListUtils` agrupa um conjunto de **funções utilitárias para manipulação e processamento de listas**. Sendo o Elixir uma linguagem funcional que faz uso extensivo de listas, este módulo visa fornecer helpers para operações comuns que podem não estar diretamente disponíveis no módulo `Enum` ou `List` padrão, ou para encapsular combinações comuns dessas funções de forma mais expressiva.

Estas funções são projetadas para serem genéricas, puras e eficientes, auxiliando em tarefas como divisão de listas, comparação, agrupamento, ordenação complexa e garantia de unicidade. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Divisão de Listas:**
    *   Dividir uma lista em sub-listas (chunks) de um tamanho específico (`chunk/2`).
    *   Particionar uma lista em duas com base em uma função predicado (`partition/2`).
*   **Comparação de Listas:**
    *   Calcular a diferença entre duas listas, opcionalmente usando uma função de chave para comparação de elementos (`diff/3`).
*   **Agrupamento de Elementos:**
    *   Agrupar elementos de uma lista com base no resultado de uma função de chave (`group_by/2`).
*   **Combinação de Listas:**
    *   Intercalar os elementos de duas listas (`interleave/2`).
*   **Paginação em Memória:**
    *   Simular paginação em uma lista, retornando uma fatia específica e metadados de paginação (`paginate/3`).
*   **Ordenação Avançada:**
    *   Ordenar uma lista de mapas ou structs com base em múltiplas chaves de ordenação, cada uma com sua própria direção (ascendente/descendente) (`sort_by_keys/2`).
*   **Garantia de Unicidade:**
    *   Remover elementos duplicados de uma lista, opcionalmente usando uma função de chave para determinar a unicidade (`unique/2`).
*   **Outras Operações Comuns:**
    *   (Potencialmente) Flattening de listas aninhadas, amostragem, rotação, etc.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

*   **`DeeperHub.Shared.Utils.ListUtils` (Módulo Funcional):**
    *   Contém todas as funções de utilidade para listas.
    *   Utiliza extensivamente os módulos `Enum` e `List` do Elixir como base para suas implementações.

### 3.2. Estrutura de Diretórios

```
lib/deeper_hub/shared/utils/list_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Imutabilidade:** Todas as funções operam sobre listas e retornam novas listas, sem modificar as listas de entrada.
*   **Lazy Evaluation vs. Eager Evaluation:** Para operações em listas potencialmente muito grandes, considerar se uma implementação lazy (usando `Stream`) seria mais apropriada para algumas funções, embora a maioria dos utilitários tende a ser eager.
*   **Consistência com API `Enum` e `List`:** Onde possível, manter a semântica e os nomes de argumentos consistentes com as funções padrão do Elixir.
*   **Performance:** Para operações que podem ser custosas (ex: ordenação complexa, diff em listas grandes), considerar a eficiência algorítmica.

## 🛠️ 4. Casos de Uso Principais

*   **Exibir Itens em Lotes:**
    *   `ListUtils.chunk(all_items, 10)` para processar ou exibir itens em páginas de 10.
*   **Encontrar Novos Usuários em uma Lista:**
    *   `ListUtils.diff(current_users, previous_users, &(&1.id))` para identificar usuários recém-adicionados.
*   **Organizar Tarefas por Prioridade:**
    *   `ListUtils.group_by(tasks, &(&1.priority))` para obter um mapa de prioridade para listas de tarefas.
*   **Renderizar uma Tabela Paginada:**
    *   `ListUtils.paginate(all_table_rows, current_page, 20)`.
*   **Ordenar uma Lista de Produtos por Preço e Depois por Nome:**
    *   `ListUtils.sort_by_keys(products, [{:price, :asc}, {:name, :asc}])`.
*   **Obter uma Lista de Tags Únicas de Múltiplas Fontes:**
    *   `ListUtils.unique(list_of_all_tags_from_servers, &(&1.name |> String.downcase()))`.

## 🌊 5. Fluxos Importantes

Não aplicável no mesmo sentido que módulos com estado. O fluxo é a execução da função com a lista de entrada e o retorno da lista transformada ou do resultado calculado.

## 📡 6. API (Funções Públicas do Módulo)

*(Baseado na documentação original, com algumas clarificações)*

### 6.1. `DeeperHub.Shared.Utils.ListUtils.chunk(list :: list(), chunk_size :: pos_integer()) :: list(list())`

*   **Descrição:** Divide `list` em sub-listas, cada uma com no máximo `chunk_size` elementos.
*   **Exemplo:** `ListUtils.chunk([1,2,3,4,5], 2)` -> `[[1,2], [3,4], [5]]`

### 6.2. `DeeperHub.Shared.Utils.ListUtils.partition(list :: list(), predicate_fun :: (element :: term() -> boolean())) :: {list(), list()}`

*   **Descrição:** Divide `list` em duas listas: a primeira com elementos para os quais `predicate_fun` retorna `true`, e a segunda com os restantes.
*   **Exemplo:** `ListUtils.partition([1,2,3,4], &Integer.is_even/1)` -> `{[2,4], [1,3]}`

### 6.3. `DeeperHub.Shared.Utils.ListUtils.diff(list1 :: list(), list2 :: list(), key_fun :: (element :: term() -> term()) | nil \\\\ nil) :: list()`

*   **Descrição:** Retorna os elementos que estão em `list1` mas não em `list2`. Se `key_fun` for fornecida, a comparação é baseada no resultado da aplicação de `key_fun` a cada elemento.
*   **Exemplo:** `ListUtils.diff([%{id: 1}, %{id: 2}], [%{id: 2}, %{id: 3}], &(&1.id))` -> `[%{id: 1}]`

### 6.4. `DeeperHub.Shared.Utils.ListUtils.group_by(list :: list(), key_fun :: (element :: term() -> group_key :: term())) :: map()`

*   **Descrição:** Agrupa elementos de `list` em um mapa, onde as chaves são o resultado de `key_fun` e os valores são listas dos elementos correspondentes.
*   **Exemplo:** `ListUtils.group_by([%{type: \"A\"}, %{type: \"B\"}, %{type: \"A\"}], &(&1.type))` -> `%{ \"A\" => [%{type: \"A\"}, %{type: \"A\"}], \"B\" => [%{type: \"B\"}]}`

### 6.5. `DeeperHub.Shared.Utils.ListUtils.interleave(list1 :: list(), list2 :: list()) :: list()`

*   **Descrição:** Cria uma nova lista intercalando os elementos de `list1` e `list2`. Se uma lista for mais longa, seus elementos restantes são anexados no final.
*   **Exemplo:** `ListUtils.interleave([1,3], [2,4,5])` -> `[1,2,3,4,5]`

### 6.6. `DeeperHub.Shared.Utils.ListUtils.paginate(list :: list(), page_number :: pos_integer(), per_page :: pos_integer()) :: %{items: list(), page: pos_integer(), per_page: pos_integer(), total_items: non_neg_integer(), total_pages: non_neg_integer()}`

*   **Descrição:** Retorna uma \"página\" de itens da `list` e metadados de paginação.
*   **Exemplo:** `ListUtils.paginate(Enum.to_list(1..10), 2, 3)` -> `%{items: [4,5,6], page: 2, per_page: 3, total_items: 10, total_pages: 4}`

### 6.7. `DeeperHub.Shared.Utils.ListUtils.sort_by_keys(list_of_maps_or_structs :: list(), sort_definitions :: list({key_path :: atom() | list(), direction :: :asc | :desc})) :: list()`

*   **Descrição:** Ordena uma lista de mapas/structs. `sort_definitions` é uma lista de tuplas onde `key_path` pode ser um átomo para acesso direto ou uma lista para acesso aninhado (ex: `[:user, :name]`).
*   **Exemplo:** `ListUtils.sort_by_keys([%{a:2,b:1}, %{a:1,b:2}], [{:a, :asc}])` -> `[%{a:1,b:2}, %{a:2,b:1}]`

### 6.8. `DeeperHub.Shared.Utils.ListUtils.unique(list :: list(), key_fun :: (element :: term() -> unique_key :: term()) | nil \\\\ nil) :: list()`

*   **Descrição:** Remove elementos duplicados da `list`. Se `key_fun` for fornecida, a unicidade é baseada no resultado de `key_fun`. A ordem dos elementos restantes é preservada com base na primeira ocorrência.
*   **Exemplo:** `ListUtils.unique([%{id:1, v:1}, %{id:2,v:2}, %{id:1,v:3}], &(&1.id))` -> `[%{id:1, v:1}, %{id:2,v:2}]`

### 6.9. `DeeperHub.Shared.Utils.ListUtils.safe_nth(list :: list(), index :: integer(), default_value :: term() \\\\ nil) :: term()` (Nova Sugestão)

*   **Descrição:** Retorna o elemento no `index` (base 0) da lista, ou `default_value` se o índice estiver fora dos limites.
*   **Exemplo:** `ListUtils.safe_nth([10,20,30], 1)` -> `20`, `ListUtils.safe_nth([10], 5, :not_found)` -> `:not_found`

### 6.10. `DeeperHub.Shared.Utils.ListUtils.transpose(list_of_lists :: list(list())) :: list(list()) | {:error, :uneven_lists}` (Nova Sugestão)

*   **Descrição:** Transpõe as linhas e colunas de uma lista de listas. Retorna erro se as listas internas tiverem tamanhos diferentes.
*   **Exemplo:** `ListUtils.transpose([[1,2,3],[4,5,6]])` -> `[[1,4],[2,5],[3,6]]`

## ⚙️ 7. Configuração

Este módulo, sendo puramente funcional e genérico, geralmente não requer configurações externas via `ConfigManager`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   Nenhuma.

### 8.2. Bibliotecas Externas

*   Utiliza primariamente os módulos `Enum` e `List` do Elixir padrão.

## 🤝 9. Como Usar / Integração

Importar ou usar alias e chamar as funções diretamente onde a manipulação de listas for necessária.
```elixir
alias DeeperHub.Shared.Utils.ListUtils

def process_batched_users(all_users) do
  Enum.each(ListUtils.chunk(all_users, 100), fn user_batch ->
    # Processar o lote de usuários
  end)
end

def find_unique_emails(user_list) do
  ListUtils.unique(user_list, &(&1.email))
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários para cada função com uma variedade de entradas:
    *   Listas vazias.
    *   Listas com um único elemento.
    *   Listas com elementos duplicados (para `unique`, `diff`).
    *   Listas com diferentes tipos de dados.
    *   Casos de borda para `chunk`, `paginate`.
    *   Diferentes `key_fun` para `diff`, `group_by`, `unique`, `sort_by_keys`.
*   Localização: `test/deeper_hub/shared/utils/list_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Não aplicável para um módulo de utilitários puros.

## ❌ 11. Tratamento de Erros

*   Funções devem levantar `ArgumentError` ou `FunctionClauseError` para tipos de entrada inválidos (ex: passar um mapa para uma função que espera uma lista, `chunk_size` não positivo).
*   Funções como `paginate` devem lidar graciosamente com números de página ou `per_page` inválidos (ex: retornar uma lista vazia ou a primeira página).
*   A documentação de cada função deve ser clara sobre seu comportamento em caso de erro.

## 🛡️ 12. Considerações de Segurança

*   Geralmente baixo risco de segurança direto, pois são funções de manipulação de dados.
*   Se as listas contiverem dados sensíveis, as funções não os modificarão ou exporão, apenas os reorganizarão ou filtrarão. A segurança dos dados em si é responsabilidade do chamador.

## 🧑‍💻 13. Contribuição

*   Adicione novas funções apenas se forem utilidades de lista genéricas e amplamente aplicáveis.
*   Priorize a clareza e a consistência com as APIs `Enum` e `List` existentes.
*   Considere a performance de funções que operam em listas potencialmente grandes.
*   Adicione testes unitários completos.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar mais funções utilitárias (ex: `rotate_list/2`, `weighted_sample/2`, `power_set/1`).
*   [ ] Para algumas funções que podem operar em listas muito grandes (ex: `group_by`, `unique` complexo), considerar oferecer uma variante baseada em `Stream` para processamento lazy.
*   [ ] Melhorar `sort_by_keys` para lidar com `nil` valores de forma configurável (ex: nils primeiro, nils por último).

---

*Última atualização: 2025-05-12*

---

Com isso, cobrimos os utilitários de lista.

Para o próximo, podemos fazer `DeeperHub.Shared.Utils.ValidationUtils` ou `DeeperHub.Shared.Utils.SecurityUtils` para continuar nos utilitários, ou mudar para um módulo de domínio ou Core mais específico?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Entendido! Vamos continuar com os utilitários e detalhar o `DeeperHub.Shared.Utils.ValidationUtils`. Este módulo é essencial para garantir a integridade dos dados que entram no sistema.

---

