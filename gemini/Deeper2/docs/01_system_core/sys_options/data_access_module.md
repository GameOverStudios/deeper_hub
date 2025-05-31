# Documentação Deeper: Módulo de Acesso a Dados para Configurações (`OptionsRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.OptionsRepo`, responsável por encapsular a lógica de consulta às tabelas de configurações do sistema UNA (`sys_options`, `sys_options_categories`, `sys_options_types`, `sys_options_mixes`, `sys_options_mixes2options`).

O `OptionsRepo` fornecerá funções para ler os valores das configurações, considerando o sistema de \"mixes\" (temas) para determinar o valor efetivo de uma opção.

**Localização do Código:** `lib/deeper/system_core/options_repo.ex`

## Funções Principais (Exemplos):

O foco inicial é na leitura das opções. A modificação de opções será tratada na API de Administração.

### 1. Obter Valor de uma Opção Específica

*   **`get_option_value(option_name :: String.t(), active_mix_name :: String.t() | nil) :: {:ok, any()} | {:error, :not_found | any()}`**
    *   Busca o valor efetivo de uma opção pelo seu nome.
    *   **Argumentos:**
        *   `option_name`: O nome da opção (de `sys_options.name`).
        *   `active_mix_name`: (Opcional) O nome do \"mix\" ativo (ex: nome do tema). Se `nil`, busca apenas o valor base.
    *   **Retorno:**
        *   `{:ok, valor_convertido}`: O valor da opção, convertido para um tipo Elixir apropriado (boolean, integer, string) com base em `sys_options.type`.
        *   `{:error, :not_found}`: Opção não encontrada.
        *   `{:error, reason}`: Outro erro de banco de dados.
    *   **Lógica Interna Detalhada:**
        1.  **Buscar a opção base e seu tipo:**
            *   SQL: `SELECT value, type FROM sys_options WHERE name = ? LIMIT 1;`
            *   Parâmetros: `option_name`.
            *   Se não encontrar, retorna `{:error, :not_found}`.
            *   Armazena `base_value` e `option_type`.
        2.  **Se `active_mix_name` for fornecido, buscar valor do mix:**
            *   SQL:

```sql
                SELECT m2o.value
                FROM sys_options_mixes2options m2o
                JOIN sys_options_mixes mix ON m2o.mix_id = mix.id
                WHERE m2o.option_name = ? AND mix.name = ? AND mix.active = 1 -- Adicionar mix.active = 1 se quiser garantir que o mix referenciado está ativo
                LIMIT 1;
```

```sql
            SELECT name, value, type FROM sys_options WHERE category_id = ?;
```

```sql
            SELECT m2o.option_name, m2o.value
            FROM sys_options_mixes2options m2o
            JOIN sys_options_mixes mix ON m2o.mix_id = mix.id
            JOIN sys_options opt ON m2o.option_name = opt.name -- Para pegar apenas opções da categoria
            WHERE opt.category_id = ? AND mix.name = ? AND mix.active = 1;
```

```sql
        SELECT
            sopt.name,
            sopt.type,
            COALESCE(sm2o.value, sopt.value) AS effective_value
        FROM sys_options sopt
        LEFT JOIN sys_options_mixes sm ON sm.name = ? AND sm.active = 1 -- active_mix_name
        LEFT JOIN sys_options_mixes2options sm2o ON sm2o.mix_id = sm.id AND sm2o.option_name = sopt.name
        WHERE sopt.name = ?; -- option_name
```

```elixir
        defp convert_option_value(value_str, \"checkbox\") do
          case String.downcase(value_str) do
            \"on\" -> true
            \"1\" -> true
            _ -> false
          end
        end
        defp convert_option_value(value_str, \"digit\"), do: String.to_integer(value_str)
        defp convert_option_value(value_str, _type), do: value_str # Default to string
```

            *   Parâmetros: `option_name`, `active_mix_name`.
            *   Se um valor for encontrado (`mix_value`), ele sobrescreve `base_value`.
        3.  **Converter o valor final:**
            *   Com base no `option_type` obtido no passo 1, converter o `final_value` (que é texto do DB):
                *   `checkbox`: `\"on\"` ou `1` -> `true`, outros -> `false`.
                *   `digit`: `String.to_integer/1`.
                *   `text`, `value`, `code`, `select`, `combobox`, `file`, `image`, `list`, `rlist`, `rgb`, `rgba`, `datetime`: manter como string ou aplicar conversões específicas se necessário (ex: `datetime` para uma struct DateTime Elixir).
            *   Retornar `{:ok, valor_convertido}`.

### 2. Obter Múltiplas Opções por Categoria

*   **`get_options_by_category(category_name :: String.t(), active_mix_name :: String.t() | nil) :: {:ok, map()} | {:error, :category_not_found | any()}`**
    *   Busca todos os valores de opções para uma categoria específica.
    *   **Retorno:**
        *   `{:ok, %{option_name1 => valor1, option_name2 => valor2, ...}}`
    *   **Lógica Interna:**
        1.  Buscar `category_id` de `sys_options_categories` pelo `category_name`.
        2.  SQL para buscar todas as opções base da categoria:

        3.  Se `active_mix_name` fornecido, buscar todos os valores sobrescritos para essas opções no mix ativo:

        4.  Combinar os valores (valores do mix têm precedência).
        5.  Converter cada valor com base em seu `type`.
        6.  Retornar o mapa de resultados.

### 3. Obter Todas as Opções (com ressalvas para performance)

*   **`get_all_options(active_mix_name :: String.t() | nil) :: {:ok, map()} | {:error, any()}`**
    *   Busca todos os valores de todas as opções.
    *   **Retorno:** `{:ok, %{\"categoria1\" => %{option1 => val1}, \"categoria2\" => ...}}` ou um mapa plano.
    *   **Lógica Interna:** Similar a `get_options_by_category` mas sem filtrar por categoria.
    *   **Atenção:** Esta função pode ser pesada e retornar muitos dados. Deve ser usada com cautela e considerar caching agressivo.

### 4. Obter o Nome do Mix Ativo para um Tipo (ex: \"template\")

*   **`get_active_mix_name_for_type(mix_type :: String.t()) :: {:ok, String.t() | nil} | {:error, any()}`**
    *   Utilizada internamente ou por outros serviços para determinar qual mix está ativo.
    *   SQL: `SELECT name FROM sys_options_mixes WHERE type = ? AND active = 1 LIMIT 1;`
    *   Parâmetros: `mix_type` (ex: \"template\").
    *   Retorna `{:ok, \"nome_do_mix\"}` ou `{:ok, nil}` se nenhum mix ativo para o tipo.

### Funções Auxiliares de Conversão de Tipo:

*   **`convert_option_value(value_string :: String.t(), option_type :: String.t()) :: any()`**
    *   Função privada para converter o valor string do banco de dados para o tipo Elixir apropriado.
    *   Exemplo:

### Estrutura de Dados de Retorno:

*   Os valores das opções devem ser retornados já convertidos para os tipos Elixir mais apropriados.
*   Para listas de opções, um mapa onde a chave é o `option_name` e o valor é o valor convertido é geralmente útil.

### Considerações de Performance e Caching:

*   **Caching:** As opções do sistema são candidatas ideais para caching (ex: usando `Cachex` ou ETS).
    *   Uma estratégia poderia ser carregar todas as opções (ou por categoria) no cache na inicialização da aplicação ou na primeira solicitação.
    *   O cache precisaria ser invalidado se as opções forem alteradas através da API de Administração.
*   **Queries Otimizadas:**
    *   Para `get_option_value`, usar `JOIN` para buscar o valor base e o valor do mix em uma única query, se possível, para reduzir a latência, embora duas queries separadas possam ser mais simples de gerenciar.

        (Esta query assume que `active_mix_name` é o nome do mix. Ajustar se for o ID do mix.)
    *   Índices em `sys_options.name`, `sys_options_categories.name`, `sys_options_mixes.name`, `sys_options_mixes.type`, `sys_options_mixes2options.option_name`, e `sys_options_mixes2options.mix_id` são cruciais.