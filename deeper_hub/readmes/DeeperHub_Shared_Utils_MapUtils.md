# Módulo: `DeeperHub.Shared.Utils.MapUtils` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Shared.Utils.MapUtils`

O módulo `DeeperHub.Shared.Utils.MapUtils` fornece um conjunto de **funções utilitárias para manipulação e transformação de mapas (maps)** e, por extensão, de structs Elixir (que são baseados em mapas). Estas funções são projetadas para simplificar operações comuns em mapas, como conversão de tipos de chave, mesclagem profunda, filtragem de entradas, e acesso seguro a valores aninhados.

Sendo um módulo puramente funcional, ele não gerencia estado e suas funções visam ser robustas e reutilizáveis em diversas partes do sistema DeeperHub. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Conversão de Tipos de Chave:**
    *   Converter chaves de átomo para string em um mapa (`atom_keys_to_strings/2`).
    *   Converter chaves de string para átomo em um mapa (`string_keys_to_atoms/2`).
    *   Suporte para conversão recursiva em mapas aninhados.
*   **Manipulação de Valores `nil`:**
    *   Remover todas as chaves de um mapa cujos valores são `nil` (`compact/2`), opcionalmente de forma recursiva.
*   **Mesclagem de Mapas:**
    *   Mesclar dois mapas recursivamente (`deep_merge/2`), onde as chaves do segundo mapa têm precedência em caso de conflito.
*   **Filtragem de Entradas:**
    *   Filtrar as entradas de um mapa com base em uma função predicado que opera sobre a chave e/o valor (`filter_map/2`).
*   **Acesso a Dados Aninhados:**
    *   Obter um valor de um caminho de chaves aninhadas dentro de um mapa, com um valor padrão se o caminho não existir (`get_in_path/3`).
    *   Atualizar um valor em um caminho de chaves aninhadas dentro de um mapa (`update_in_path/3`).
*   **Transformação de Valores:**
    *   Aplicar uma função a todos os valores de um mapa, opcionalmente de forma recursiva (`map_values/3`).
*   **Conversão de Estrutura:**
    *   Converter um mapa em uma lista de mapas chave-valor (`to_key_value_list/3`).

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

*   **`DeeperHub.Shared.Utils.MapUtils` (Módulo Funcional):**
    *   Contém todas as funções de utilidade para mapas.
    *   Utiliza principalmente funções dos módulos `Map`, `Enum` e `Kernel` do Elixir.

### 3.2. Estrutura de Diretórios

```
shared/utils/map_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Imutabilidade:** Todas as funções retornam novos mapas, não modificando os mapas de entrada.
*   **Tratamento de Entradas:** Funções devem lidar de forma previsível com diferentes tipos de entrada (ex: mapas vazios, chaves não existentes).
*   **Recursividade Opcional:** Para funções como conversão de chaves ou compactação, a opção de aplicar a transformação recursivamente a mapas aninhados é importante.
*   **Clareza e Previsibilidade:** As funções devem ter um comportamento claro e bem documentado.

## 🛠️ 4. Casos de Uso Principais

*   **Preparar Dados para API JSON:**
    *   Antes de serializar um struct Elixir (com chaves de átomo) para JSON, usar `MapUtils.atom_keys_to_strings(data, true)` para converter todas as chaves para strings.
*   **Limpar Parâmetros de Requisição:**
    *   Receber `params` de uma requisição web e usar `MapUtils.compact(params)` para remover quaisquer chaves com valores `nil` antes de passá-los para um serviço.
*   **Configuração de Mesclagem:**
    *   Mesclar configurações padrão com configurações específicas do usuário: `MapUtils.deep_merge(default_config, user_config)`.
*   **Extrair Configurações Específicas:**
    *   De um grande mapa de configuração, extrair apenas as configurações relevantes: `MapUtils.filter_map(all_configs, fn key, _value -> String.starts_with?(Atom.to_string(key), \"email_\") end)`.
*   **Acessar Preferência Aninhada:**
    *   `MapUtils.get_in_path(user_settings, [:notifications, :email, :marketing_opt_in], false)`.

## 🌊 5. Fluxos Importantes

Não aplicável no mesmo sentido que módulos com estado. O fluxo é a execução da função com os dados de entrada e o retorno do mapa transformado.

## 📡 6. API (Funções Públicas do Módulo)

*(Baseado na documentação original e mantendo a consistência)*

### 6.1. `DeeperHub.Shared.Utils.MapUtils.atom_keys_to_strings(map_data :: map(), recursive :: boolean() \\\\ false) :: map()`

*   **Descrição:** Converte todas as chaves de átomo em `map_data` para strings.
*   **`recursive`:** Se `true`, aplica a conversão a todos os mapas aninhados.

### 6.2. `DeeperHub.Shared.Utils.MapUtils.string_keys_to_atoms(map_data :: map(), recursive :: boolean() \\\\ false) :: map()`

*   **Descrição:** Converte todas as chaves de string em `map_data` para átomos.
*   **`recursive`:** Se `true`, aplica a conversão a todos os mapas aninhados.
*   **Cuidado:** Usar com cautela, pois a criação excessiva de átomos pode levar ao esgotamento da tabela de átomos do Erlang. Preferível para chaves conhecidas.

### 6.3. `DeeperHub.Shared.Utils.MapUtils.compact(map_data :: map(), recursive :: boolean() \\\\ false) :: map()`

*   **Descrição:** Remove todas as chaves de `map_data` cujos valores são `nil`.
*   **`recursive`:** Se `true`, aplica a compactação a todos os mapas aninhados.

### 6.4. `DeeperHub.Shared.Utils.MapUtils.deep_merge(map1 :: map(), map2 :: map()) :: map()`

*   **Descrição:** Mescla `map2` em `map1`. Se uma chave existir em ambos, o valor de `map2` é usado. Se os valores para uma chave comum forem ambos mapas, eles são mesclados recursivamente.
*   **Exemplo:**
    ```elixir
    map_a = %{a: 1, b: %{c: 2, d: 3}}
    map_b = %{b: %{d: 4, e: 5}, f: 6}
    MapUtils.deep_merge(map_a, map_b)
    #=> %{a: 1, b: %{c: 2, d: 4, e: 5}, f: 6}
    ```

### 6.5. `DeeperHub.Shared.Utils.MapUtils.filter_map(map_data :: map(), predicate_fun :: ((key :: term(), value :: term()) -> boolean())) :: map()`

*   **Descrição:** Retorna um novo mapa contendo apenas as entradas de `map_data` para as quais `predicate_fun` retorna `true`.

### 6.6. `DeeperHub.Shared.Utils.MapUtils.get_in_path(map_data :: map(), path :: list(atom() | String.t()), default_value :: term() \\\\ nil) :: term()`

*   **Descrição:** Acessa um valor aninhado em `map_data` usando uma `path` (lista de chaves). Retorna `default_value` se qualquer parte do caminho não existir. (Similar a `get_in/2` do Kernel, mas com um `default_value` explícito e talvez mais flexibilidade nos tipos de chave no path).

### 6.7. `DeeperHub.Shared.Utils.MapUtils.update_in_path(map_data :: map(), path :: list(atom() | String.t()), new_value :: term()) :: map()`

*   **Descrição:** Atualiza um valor em um caminho aninhado. Se o caminho não existir completamente, ele pode ser criado (dependendo da implementação exata, ou pode falhar). (Similar a `put_in/3` ou `update_in/3` do Kernel).

### 6.8. `DeeperHub.Shared.Utils.MapUtils.map_values(map_data :: map(), transform_fun :: ((value :: term()) -> term()), recursive :: boolean() \\\\ false) :: map()`

*   **Descrição:** Cria um novo mapa aplicando `transform_fun` a cada valor do `map_data` original.
*   **`recursive`:** Se `true`, e um valor for um mapa, aplica `map_values` a esse mapa aninhado.

### 6.9. `DeeperHub.Shared.Utils.MapUtils.to_key_value_list(map_data :: map(), key_field_name :: atom() \\\\ :key, value_field_name :: atom() \\\\ :value) :: list(map())`

*   **Descrição:** Converte um mapa em uma lista de mapas, onde cada mapa na lista tem duas chaves: `key_field_name` (contendo a chave original) e `value_field_name` (contendo o valor original).
*   **Exemplo:**
    ```elixir
    MapUtils.to_key_value_list(%{name: \"Alice\", age: 30})
    #=> [%{key: :name, value: \"Alice\"}, %{key: :age, value: 30}]
    ```

## ⚙️ 7. Configuração

Este módulo, sendo puramente funcional e genérico, geralmente não requer configurações externas. Comportamentos padrão (ex: para `compact` recursivo) são definidos por argumentos de função.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   Nenhuma.

### 8.2. Bibliotecas Externas

*   Utiliza principalmente os módulos `Map` e `Enum` do Elixir padrão.

## 🤝 9. Como Usar / Integração

Importar ou usar alias e chamar as funções diretamente.

```elixir
alias DeeperHub.Shared.Utils.MapUtils

def process_user_input(params) do
  string_keyed_params = MapUtils.atom_keys_to_strings(params)
  compacted_params = MapUtils.compact(string_keyed_params, true)
  # ...
end

def get_notification_setting(user_prefs, type, channel) do
  MapUtils.get_in_path(user_prefs, [:notifications, type, channel], true) # Default to true
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários extensivos para cada função, cobrindo:
    *   Mapas vazios.
    *   Mapas com diferentes tipos de chaves e valores.
    *   Comportamento recursivo vs. não recursivo.
    *   Casos de borda (ex: `get_in_path` com caminho parcialmente existente).
    *   Tratamento de `nil` como entrada.
*   Localização: `test/deeper_hub/shared/utils/map_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Não aplicável para um módulo de utilitários puros. A instrumentação ocorreria nos módulos que utilizam essas funções, se uma chamada específica a uma função de `MapUtils` se mostrar um gargalo.

## ❌ 11. Tratamento de Erros

*   Funções devem ser claras sobre como lidam com entradas inválidas (ex: passar uma lista para uma função que espera um mapa). Geralmente, devem levantar `ArgumentError` ou `FunctionClauseError`.
*   `string_keys_to_atoms` deve ser usado com cautela, pois a criação desenfreada de átomos pode levar ao esgotamento da tabela de átomos. Idealmente, usar apenas para um conjunto conhecido de chaves string.

## 🛡️ 12. Considerações de Segurança

*   Geralmente baixo risco de segurança direto, pois são funções de manipulação de dados.
*   A segurança se torna relevante no contexto de como os mapas resultantes são usados (ex: se um mapa com chaves de átomo convertidas de strings de usuário for usado em `apply/3` de forma insegura, mas isso é um problema do chamador, não do `MapUtils`).

## 🧑‍💻 13. Contribuição

*   Adicione novas funções apenas se forem utilidades de mapa genéricas e amplamente aplicáveis.
*   Mantenha a pureza funcional e a imutabilidade.
*   Documente claramente o comportamento, especialmente para casos de borda e tratamento de `nil`.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar `deep_atomize_keys/1` e `deep_stringify_keys/1` como atalhos para as versões recursivas.
*   [ ] Considerar funções para transformações mais complexas, como `rename_keys/2` ou `transform_keys_and_values/2`.
*   [ ] Otimizar funções para performance em mapas muito grandes, se necessário, embora as implementações baseadas em `Enum` e `Map` do Elixir já sejam bastante eficientes.

---

*Última atualização: 2025-05-12*

---

Utilitários de mapa são sempre bem-vindos para manter o código limpo!

Próximo? Podemos fazer `DeeperHub.Shared.Utils.ListUtils` ou `ValidationUtils` para continuar com os utilitários, ou saltar para um módulo de domínio ou outro Core?"""),
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
                types.Part.from_text(text="""Ótimo! Vamos continuar com os utilitários e detalhar o `DeeperHub.Shared.Utils.ListUtils`. Manipular listas é uma tarefa onipresente em Elixir.

---

