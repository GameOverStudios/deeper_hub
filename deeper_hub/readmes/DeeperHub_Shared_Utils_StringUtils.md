# Módulo: `Deeper_Hub.Shared.Utils.StringUtils` 🚀

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Shared.Utils.StringUtils`

O módulo `Deeper_Hub.Shared.Utils.StringUtils` fornece um conjunto de funções utilitárias para **manipulação e formatação de strings**. Estas funções são genéricas e projetadas para serem usadas em várias partes do sistema Deeper_Hub para tarefas comuns como conversão de case, truncamento, mascaramento de IDs, e geração de identificadores simples. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Conversão de Case:**
    *   Converter strings entre `snake_case` e `camelCase` (`camel_to_snake/1`, `snake_to_camel/1`).
*   **Truncamento de Texto:**
    *   Limitar o comprimento de uma string, adicionando um sufixo se truncada (`truncate/3`).
*   **Mascaramento de IDs/Dados Sensíveis:**
    *   Ocultar parcialmente uma string (ex: um ID ou número), deixando apenas alguns caracteres visíveis (`mask_id/3`).
*   **Geração de Identificadores Simples:**
    *   Gerar strings de ID aleatórias, possivelmente com um prefixo (`generate_id/1`). (Nota: Para IDs criptograficamente seguros ou UUIDs, usar `Deeper_Hub.Shared.Utils.SecurityUtils` ou `UUID`).
*   **Formatação para Logs:**
    *   Formatar/truncar texto para exibição segura e concisa em logs (`format_for_log/2`).
*   **Outras Manipulações Comuns:**
    *   Remoção de acentos.
    *   Geração de \"slugs\" a partir de títulos.
    *   Capitalização.

## 🏗️ 3. Arquitetura e Design

Este é um módulo puramente funcional, não gerenciando estado.

### 3.1. Componentes Principais

*   **`Deeper_Hub.Shared.Utils.StringUtils` (Módulo Funcional):** Contém todas as funções de utilidade para strings.

### 3.2. Estrutura de Diretórios

```
shared/utils/string_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Imutabilidade:** Todas as funções retornam novas strings, não modificando as originais.
*   **Tratamento de `nil`:** Funções devem lidar graciosamente com entradas `nil` (ex: retornando `nil`, string vazia, ou levantando `ArgumentError` conforme documentado).
*   **Unicode:** As funções devem ser seguras para uso com strings UTF-8.

## 🛠️ 4. Casos de Uso Principais

*   Converter chaves de API de `snake_case` (Elixir) para `camelCase` (JSON) e vice-versa.
*   Exibir uma prévia de um texto longo em uma UI, usando `truncate/3`.
*   Mostrar um ID de transação parcialmente mascarado em um extrato: `mask_id(\"txn_abcdef123456\", 4)`.
*   Gerar um ID de referência simples para um log: `generate_id(\"logref_\")`.

## 🌊 5. Fluxos Importantes

Não aplicável (módulo funcional).

## 📡 6. API (Funções Públicas do Módulo)

### 6.1. `Deeper_Hub.Shared.Utils.StringUtils.camel_to_snake(string :: String.t()) :: String.t()`

*   **Descrição:** Converte uma string em `camelCase` ou `PascalCase` para `snake_case`.
*   **Exemplo:** `camel_to_snake(\"UserProfile\")` -> `\"user_profile\"`

### 6.2. `Deeper_Hub.Shared.Utils.StringUtils.snake_to_camel(string :: String.t(), capitalize_first_letter :: boolean() \\\\ false) :: String.t()`

*   **Descrição:** Converte uma string em `snake_case` para `camelCase`. Se `capitalize_first_letter` for `true`, converte para `PascalCase`.
*   **Exemplo:** `snake_to_camel(\"user_profile_id\")` -> `\"userProfileId\"`, `snake_to_camel(\"user_profile\", true)` -> `\"UserProfile\"`

### 6.3. `Deeper_Hub.Shared.Utils.StringUtils.truncate(string :: String.t() | nil, max_length :: non_neg_integer(), suffix :: String.t() \\\\ \"...\") :: String.t() | nil`

*   **Descrição:** Trunca `string` para `max_length` se for maior, anexando `suffix`. Retorna `nil` se a entrada for `nil`.
*   **Exemplo:** `truncate(\"Texto muito longo\", 10)` -> `\"Texto m...\"`

### 6.4. `Deeper_Hub.Shared.Utils.StringUtils.mask_id(id_string :: String.t() | nil, visible_end_chars :: non_neg_integer(), mask_char :: String.t() \\\\ \"*\") :: String.t() | nil`

*   **Descrição:** Mascara o início de `id_string`, deixando `visible_end_chars` visíveis no final.
*   **Exemplo:** `mask_id(\"abcdef123456\", 4)` -> `\"********3456\"`

### 6.5. `Deeper_Hub.Shared.Utils.StringUtils.generate_id(prefix :: String.t() \\\\ \"\", length :: non_neg_integer() \\\\ 16) :: String.t()` (Nova Sugestão - para IDs não cripto)

*   **Descrição:** Gera uma string alfanumérica aleatória de `length` caracteres, prefixada por `prefix`. *Não usar para segredos ou tokens de segurança.*
*   **Exemplo:** `generate_id(\"ref_\", 8)` -> `\"ref_aB3x7pQk\"`

### 6.6. `Deeper_Hub.Shared.Utils.StringUtils.format_for_log(text :: String.t() | nil, max_length :: non_neg_integer() \\\\ 200) :: String.t() | nil`

*   **Descrição:** Trunca `text` para `max_length` (para logs) e substitui múltiplos espaços/novas linhas por um único espaço.
*   **Exemplo:** `format_for_log(\"Log \\n com \\t muitas \\s\\s linhas\", 50)` -> `\"Log com muitas linhas\"`

### 6.7. `Deeper_Hub.Shared.Utils.StringUtils.slugify(string :: String.t(), separator :: String.t() \\\\ \"-\") :: String.t()` (Nova Sugestão)

*   **Descrição:** Converte uma string em um \"slug\" amigável para URL (minúsculas, remove acentos, substitui espaços e caracteres especiais por `separator`).
*   **Exemplo:** `slugify(\"Título do Meu Post!\")` -> `\"titulo-do-meu-post\"`

### 6.8. `Deeper_Hub.Shared.Utils.StringUtils.humanize(string :: String.t()) :: String.t()` (Nova Sugestão)

*   **Descrição:** Converte uma string `snake_case` ou `camelCase` em uma frase legível por humanos (capitaliza a primeira letra, substitui `_` por espaço).
*   **Exemplo:** `humanize(\"user_profile_updated\")` -> `\"User profile updated\"`

## ⚙️ 7. Configuração

Este módulo geralmente não requer configurações externas, mas alguns padrões poderiam ser configuráveis se necessário:
*   Default `max_length` ou `suffix` para `truncate/3`.
*   Default `mask_char` para `mask_id/3`.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   Nenhuma.

### 8.2. Bibliotecas Externas

*   Pode usar `Slugify` se a função `slugify/2` for complexa.
*   Pode usar `Unaccent` para remoção de acentos.
*   Geralmente, usa apenas funções do módulo `String` e `:binary` do Elixir/Erlang.

## 🤝 9. Como Usar / Integração

Simplesmente chame as funções do módulo onde a manipulação de string for necessária.
```elixir
alias Deeper_Hub.Shared.Utils.StringUtils

short_desc = StringUtils.truncate(long_description, 150)
api_key_masked = StringUtils.mask_id(api_key, 6)
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários para cada função com uma variedade de entradas, incluindo strings vazias, `nil`, strings com caracteres Unicode, e casos de borda para `truncate` e `mask_id`.
*   Localização: `test/deeper_hub/shared/utils/string_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Não aplicável para um módulo de utilitários puros.

## ❌ 11. Tratamento de Erros

*   Funções devem ser claras sobre como lidam com `nil` ou entradas inválidas (retornar `nil`, string vazia, ou levantar `ArgumentError`). Isso deve ser documentado por função.
*   Para `truncate` e `mask_id`, se `max_length` ou `visible_end_chars` for maior que o comprimento da string, a string original deve ser retornada.

## 🛡️ 12. Considerações de Segurança

*   As funções de mascaramento (`mask_id`) são para exibição e não devem ser consideradas uma forma de criptografia ou hashing seguro.
*   A função `generate_id` não é para tokens de segurança; use `:crypto.strong_rand_bytes/1` e codificação (ou `SecurityUtils`) para isso.
*   A função `slugify` deve garantir que o resultado não contenha caracteres que possam ser problemáticos em URLs ou nomes de arquivo.

## 🧑‍💻 13. Contribuição

*   Adicione novas funções apenas se forem verdadeiramente genéricas e reutilizáveis.
*   Mantenha as funções focadas e com comportamento previsível.
*   Adicione testes para todas as novas funções e para casos de borda de funções existentes.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar mais funções de manipulação de string comuns (ex: `strip_tags` mais robusto, `word_wrap`).
*   [ ] Melhorar o suporte Unicode em todas as funções, especialmente `slugify` e `humanize`.
*   [ ] Considerar a performance para funções que podem ser chamadas em loops com strings grandes.

---

*Última atualização: 2025-05-12*

---

Este detalha o `StringUtils`. Podemos seguir com outro módulo `Utils` como `DateUtils` ou `MapUtils`, ou voltar para um módulo Core ou de Segurança?"""),
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
                types.Part.from_text(text="""Ótimo! Vamos continuar com os utilitários e detalhar o `Deeper_Hub.Shared.Utils.DateUtils`. A manipulação de datas e horas é uma necessidade comum em muitas partes de um sistema.

---

