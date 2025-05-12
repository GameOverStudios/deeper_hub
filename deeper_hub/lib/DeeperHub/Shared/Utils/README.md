# Módulo: `DeeperHub.Shared.Utils` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Shared.Utils`

O módulo (ou namespace) `DeeperHub.Shared.Utils` agrupa um conjunto de **módulos utilitários genéricos** que fornecem funções auxiliares para tarefas comuns em todo o sistema DeeperHub. Essas funções não pertencem a um domínio de negócio específico, mas oferecem funcionalidades reutilizáveis para manipulação de strings, datas, listas, mapas, arquivos, validações básicas e operações de segurança comuns.

O objetivo é evitar a duplicação de código, promover a consistência e fornecer um local centralizado para funcionalidades de baixo nível que são amplamente utilizadas. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave (por Submódulo)

Este namespace normalmente contém vários módulos menores, cada um com um foco específico:

*   **`DeeperHub.Shared.Utils.StringUtils`:**
    *   Manipulação de strings: conversão de case (camelCase, snake_case), truncamento, mascaramento de IDs, geração de IDs/tokens simples, formatação para logs.
*   **`DeeperHub.Shared.Utils.DateUtils`:**
    *   Manipulação de datas e horas: adição/subtração de tempo, cálculo de diferenças, formatação, verificação de intervalos.
*   **`DeeperHub.Shared.Utils.ListUtils`:**
    *   Operações em listas: chunking, diff, group_by, interleave, paginação em memória, particionamento, ordenação por múltiplas chaves, remoção de duplicatas.
*   **`DeeperHub.Shared.Utils.MapUtils`:**
    *   Operações em mapas: conversão de chaves (átomo/string), compactação (remoção de nils), mesclagem profunda, filtragem, acesso/atualização aninhada.
*   **`DeeperHub.Shared.Utils.FileUtils` (se a aplicação lida diretamente com o sistema de arquivos):**
    *   Operações de arquivo: verificação de existência, leitura, escrita, cópia, cálculo de hash, obtenção de MIME type.
*   **`DeeperHub.Shared.Utils.ValidationUtils`:**
    *   Funções de validação de formato para dados comuns: email, telefone, URL, data, número de documento, JSON.
    *   Validação de complexidade de senha (básica), presença de campos obrigatórios.
    *(Nota: Validações mais complexas ou específicas de domínio residiriam nos respectivos módulos ou em `Core.InputValidator`)*
*   **`DeeperHub.Shared.Utils.SecurityUtils`:**
    *   Utilitários de segurança genéricos e agnósticos de contexto: geração de tokens/IDs aleatórios seguros, hashing de senhas (se não centralizado em `Auth` ou `Core.EncryptionService`), avaliação de risco simples baseada em fatores.
    *(Nota: Funções criptográficas mais robustas e gerenciamento de chaves devem estar em `Core.EncryptionService`)*

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

Cada submódulo dentro de `DeeperHub.Shared.Utils` é tipicamente um **módulo funcional puro**, contendo apenas funções que recebem entradas e produzem saídas sem efeitos colaterais (ou com efeitos colaterais bem definidos, como no caso de `FileUtils`). Eles geralmente não mantêm estado nem são GenServers.

### 3.2. Estrutura de Diretórios (Proposta)

```
shared/utils/
├── string_utils.ex
├── date_utils.ex
├── list_utils.ex
├── map_utils.ex
├── file_utils.ex       # Se aplicável
├── validation_utils.ex
└── security_utils.ex
```
O arquivo `shared/utils.ex` poderia ser um arquivo vazio ou um módulo que simplesmente agrupa aliases ou documentação de alto nível para os submódulos.

### 3.3. Decisões de Design Importantes

*   **Sem Estado:** Os módulos utilitários devem ser, na medida do possível, stateless.
*   **Funções Puras:** Preferir funções puras para facilitar o teste e o raciocínio sobre o código.
*   **Sem Dependências de Domínio:** Utilitários não devem depender de módulos de domínio específicos (ex: `DeeperHub.Accounts`). Se uma função precisa de lógica de domínio, ela provavelmente pertence ao módulo de domínio.
*   **Generalidade:** As funções devem ser genéricas o suficiente para serem úteis em múltiplos contextos.
*   **Clareza vs. Performance:** Embora a performance seja importante, a clareza e a correção das funções utilitárias são primordiais. Otimizações podem ser feitas se um utilitário específico se tornar um gargalo.

## 🛠️ 4. Casos de Uso Principais (Exemplos de cada Submódulo)

*   **`StringUtils.camel_to_snake(\"myExampleVariable\")`** -> `\"my_example_variable\"`
*   **`DateUtils.add(~N[2023-01-01 10:00:00], 5, :day)`** -> `~N[2023-01-06 10:00:00]`
*   **`ListUtils.chunk([1,2,3,4,5], 2)`** -> `[[1,2], [3,4], [5]]`
*   **`MapUtils.deep_merge(%{a: 1, b: %{c: 2}}, %{b: %{d: 3}, e: 4})`** -> `%{a: 1, b: %{c: 2, d: 3}, e: 4}`
*   **`ValidationUtils.validate_email(\"test@example.com\")`** -> `true` (ou `{:ok, \"test@example.com\"}`)
*   **`SecurityUtils.generate_token(16, :hex)`** -> Uma string hexadecimal de 32 caracteres.

## 🌊 5. Fluxos Importantes

Não aplicável no mesmo sentido que módulos com estado ou processos. O fluxo é simplesmente a chamada de uma função e o retorno de seu resultado.

## 📡 6. API (Funções Públicas dos Submódulos)

A API consiste nas funções públicas exportadas por cada submódulo utilitário (ex: `StringUtils.truncate/3`, `MapUtils.get_in_path/3`). A documentação específica de cada API residiria nos arquivos README de seus respectivos submódulos ou diretamente como documentação de função `@doc` / `@spec`.

## ⚙️ 7. Configuração

Geralmente, módulos utilitários puros não requerem muita configuração externa via `ConfigManager`, a menos que tenham comportamentos padrão que precisem ser ajustáveis (ex: o caractere de mascaramento padrão em `StringUtils.mask_id/3`).

## 🔗 8. Dependências

### 8.1. Módulos Internos

Idealmente, os módulos em `Shared.Utils` têm poucas ou nenhuma dependência de outros módulos `DeeperHub`, exceto talvez `Core.ConfigManager` para padrões configuráveis. Eles são blocos de construção.

### 8.2. Bibliotecas Externas

Podem usar bibliotecas Elixir/Erlang padrão para suas funcionalidades (ex: `String`, `Enum`, `Map`, `DateTime`, `:crypto`). Em alguns casos, uma pequena biblioteca de terceiros altamente focada pode ser usada se fornecer uma funcionalidade utilitária robusta que não valha a pena reinventar (ex: uma biblioteca para parsing de User-Agent mais avançado, se isso for colocado em `Utils` em vez de um serviço dedicado).

## 🤝 9. Como Usar / Integração

Os módulos utilitários são importados ou aliasados e suas funções são chamadas diretamente onde necessário.

```elixir
defmodule MyApp.SomeService do
  alias DeeperHub.Shared.Utils.StringUtils
  alias DeeperHub.Shared.Utils.DateUtils

  def process_text(text) do
    truncated = StringUtils.truncate(text, 100)
    # ...
  end

  def get_expiry_date(start_date) do
    DateUtils.add(start_date, 30, :day)
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Cada função utilitária deve ter testes unitários abrangentes cobrindo casos de borda, entradas válidas e inválidas.
*   Testes baseados em propriedades (Property-based testing com StreamData) podem ser muito úteis para funções utilitárias que processam dados.
*   Localização: `test/deeper_hub/shared/utils/<submodule_name>_test.exs`.

### 10.2. Métricas

Geralmente, funções utilitárias puras não emitem métricas por si mesmas. Se uma função utilitária for identificada como um gargalo de performance em um caminho crítico, o chamador dessa função seria responsável por adicionar métricas de timing ao redor da chamada.

### 10.3. Logs

Funções utilitárias puras geralmente não devem fazer logging. Se ocorrer um erro inesperado dentro de uma função utilitária (o que deveria ser raro se as entradas forem validadas pelos chamadores ou pela própria função), ela pode levantar uma exceção que será capturada e logada pelo chamador.

### 10.4. Telemetria

Similar às métricas, funções utilitárias puras não emitem eventos Telemetry. A instrumentação Telemetry ocorreria no código que as utiliza.

## ❌ 11. Tratamento de Erros

*   Funções utilitárias devem ter um contrato claro sobre como lidam com entradas inválidas:
    *   Algumas podem levantar exceções (ex: `ArgumentError`).
    *   Outras podem retornar tuplas de erro (ex: `{:error, :invalid_format}`).
    *   Outras podem retornar um valor padrão ou `nil`.
*   A documentação de cada função deve ser clara sobre seu comportamento em caso de erro.

## 🛡️ 12. Considerações de Segurança

*   **`SecurityUtils`:** As funções aqui devem ser revisadas cuidadosamente para garantir que sejam criptograficamente seguras (ex: uso correto de `:crypto.strong_rand_bytes/1`).
*   **`ValidationUtils` e `StringUtils` (Sanitização):** Se alguma função aqui realizar sanitização, ela deve ser robusta contra bypass. No entanto, a sanitização principal para XSS, SQLi, etc., reside nos módulos de segurança dedicados (`XssProtection`, `SqlInjectionProtection`). Os utilitários podem fornecer blocos de construção básicos para essas operações.
*   **`FileUtils`:** Se interagir com o sistema de arquivos, deve ser extremamente cuidadoso para não introduzir vulnerabilidades de Path Traversal (essa proteção principal estaria em `PathTraversalProtection`, mas `FileUtils` deve ser consciente).

## 🧑‍💻 13. Contribuição

*   Ao adicionar uma nova função utilitária, certifique-se de que ela seja genérica e reutilizável.
*   Adicione documentação clara (`@doc`, `@spec`) e testes unitários completos.
*   Evite adicionar dependências desnecessárias a outros módulos do DeeperHub.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Para cada submódulo (`StringUtils`, `DateUtils`, etc.), criar um arquivo README.md específico detalhando sua API.
*   [ ] Avaliar se alguma funcionalidade em `Utils` se tornou complexa o suficiente para justificar seu próprio serviço/módulo Core.
*   [ ] Adicionar mais utilitários conforme a necessidade surgir (ex: `NumberUtils` para formatação de moeda, `EnumUtils` para operações avançadas em enumerações).

---

*Última atualização: 2025-05-12*

---

Agora, vamos detalhar um desses submódulos. Que tal o `DeeperHub.Shared.Utils.StringUtils`?

---

