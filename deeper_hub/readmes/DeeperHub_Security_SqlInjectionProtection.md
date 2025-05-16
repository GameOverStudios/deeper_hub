# Módulo: `DeeperHub.Security.SqlInjectionProtection` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Security.SqlInjectionProtection`

O módulo `DeeperHub.Security.SqlInjectionProtection` é dedicado a prevenir ataques de **Injeção de SQL** no sistema DeeperHub. A Injeção de SQL é uma técnica de ataque onde um invasor insere ou \"injeta\" código SQL malicioso em campos de entrada que são subsequentemente usados para construir consultas ao banco de dados. Se bem-sucedido, isso pode permitir que o invasor visualize, modifique ou exclua dados, ou até mesmo execute comandos no sistema operacional do servidor de banco de dados.

Este módulo foca em:
1.  **Uso de Consultas Parametrizadas (Prepared Statements):** A principal e mais eficaz defesa.
2.  **Validação e Sanitização de Entradas:** Como uma camada secundária, especialmente para entradas usadas em cláusulas `ORDER BY` ou outros contextos onde a parametrização pode ser mais difícil.
3.  **Detecção de Padrões Maliciosos:** Analisar strings de consulta ou fragmentos para identificar padrões típicos de injeção.

O objetivo é garantir que todas as interações com o banco de dados sejam seguras e que os dados fornecidos pelo usuário não possam ser usados para manipular consultas SQL de forma maliciosa. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Promover e Facilitar Consultas Parametrizadas:**
    *   Incentivar o uso de Ecto Changesets e `Ecto.Query` que geram consultas parametrizadas por padrão.
    *   Fornecer utilitários para construir consultas dinâmicas de forma segura, se absolutamente necessário (ex: `generate_safe_query/2`).
*   **Validação e Sanitização de Entradas Usadas em SQL:**
    *   Validar se os valores usados em cláusulas dinâmicas (ex: nomes de colunas para ordenação, direção de ordenação) pertencem a uma lista branca de valores permitidos.
    *   Sanitizar strings que *precisam* ser interpoladas diretamente em fragmentos SQL (uma prática a ser evitada ao máximo), escapando caracteres especiais.
*   **Detecção de Padrões de Injeção (`check_query/2`, `check_string/2`):**
    *   Analisar strings de consulta SQL completas (raramente construídas manualmente) ou fragmentos de strings para identificar padrões suspeitos (ex: comentários SQL, `UNION SELECT`, `OR 1=1`, múltiplas queries).
*   **Parametrização de Consultas (Helper) (`parameterize/3`):**
    *   (Menos comum com Ecto) Fornecer uma maneira de converter uma string de consulta com placeholders em uma consulta parametrizada e uma lista de parâmetros.
*   **Registro e Alerta de Tentativas de Injeção (`record_injection_attempt/3`):**
    *   Logar tentativas de injeção de SQL detectadas.
    *   Notificar administradores sobre tentativas significativas ou repetidas.
*   **Estatísticas de Tentativas (`get_statistics/1`):**
    *   Coletar métricas sobre tentativas de injeção detectadas e bloqueadas.
*   **Configurabilidade:**
    *   Listas brancas de identificadores SQL permitidos (nomes de tabelas/colunas para queries dinâmicas).
    *   Padrões de regex para detecção de SQLi.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

1.  **`DeeperHub.Security.SqlInjectionProtection` (Fachada Pública):**
    *   Ponto de entrada para as funcionalidades de proteção contra SQLi.
    *   Delega para o `SqlInjectionProtectionService`.
2.  **`DeeperHub.Security.SqlInjectionProtection.Services.SqlInjectionProtectionService` (Módulo Funcional ou GenServer):**
    *   **Responsabilidade:** Contém a lógica principal para verificação, sanitização e geração segura de fragmentos de consulta.
    *   **Interações:**
        *   Pode usar bibliotecas de parsing SQL (limitado) ou regex para detecção de padrões.
        *   Interage com `DeeperHub.Core.ConfigManager` para obter listas brancas e padrões de detecção.
        *   Interage com `DeeperHub.Audit` ou `DeeperHub.Security.Monitoring` para registrar tentativas.
3.  **Ecto e `DeeperHub.Core.Repo` (Principal Mecanismo de Defesa):**
    *   A maior parte da proteção contra SQLi vem do uso correto do Ecto, que por padrão utiliza consultas parametrizadas. Este módulo `SqlInjectionProtection` serve mais como um conjunto de ferramentas para casos específicos e para análise de entradas que *poderiam* ser usadas em contextos SQL.
4.  **`DeeperHub.Shared.Utils.ValidationUtils` (para validação de tipos de dados):**
    *   Garantir que os dados passados para as queries Ecto tenham os tipos corretos antes de serem usados.

### 3.2. Estrutura de Diretórios (Proposta)

```
security/sql_injection_protection/
├── sql_injection_protection.ex                 # Fachada Pública
│
├── services/
│   └── sql_injection_protection_service.ex     # Lógica principal
│
└── supervisor.ex                     # Supervisor (se o serviço for GenServer, menos provável aqui)
```
*(Os módulos `SqlInjectionProtectionAdapter` e `SqlInjectionProtectionBehaviour` da documentação original podem ser simplificados se o `SqlInjectionProtectionService` for a implementação principal e a fachada o chamar diretamente, dado que muitas funções são puras ou baseadas em config.)*

### 3.3. Decisões de Design Importantes

*   **Priorizar Consultas Parametrizadas:** A primeira e mais importante linha de defesa é usar Ecto Changesets e `Ecto.Query` com parâmetros, em vez de construir strings SQL manualmente.
*   **Validação de Lista Branca para Dinamismo:** Se nomes de colunas ou tabelas precisarem ser dinâmicos (ex: ordenação por coluna clicada pelo usuário), validar esses nomes contra uma lista branca de valores permitidos. Nunca interpolar diretamente a entrada do usuário.
*   **Sanitização como Último Recurso:** A sanitização de strings (escapar apóstrofos, etc.) deve ser um último recurso e feita com extremo cuidado, apenas quando a parametrização não for viável.
*   **Contexto do Banco de Dados:** Algumas técnicas de sanitização ou detecção podem ser específicas do dialeto SQL do banco de dados (PostgreSQL, MySQL, etc.).

## 🛠️ 4. Casos de Uso Principais

*   **Construção de Query Ecto com Ordenação Dinâmica:**
    *   Usuário clica em um cabeçalho de tabela para ordenar por uma coluna.
    *   O nome da coluna (`sort_field`) e a direção (`sort_direction`) vêm da requisição.
    *   **Antes de usar no Ecto `order_by`:**
        ```elixir
        allowed_sort_fields = [\"name\", \"created_at\", \"status\"]
        allowed_directions = [:asc, :desc]

        if sort_field_from_user in allowed_sort_fields and sort_direction_from_user in allowed_directions do
          from(q in query, order_by: [{^sort_direction_from_user, field(q, ^String.to_atom(sort_field_from_user))}])
        else
          # Ordenação padrão ou erro
        end
        ```
    *   `SqlInjectionProtection.check_string/2` poderia ser usado no `sort_field_from_user` como uma verificação adicional, mas a validação de lista branca é mais robusta.
*   **Log de Query Suspeita:**
    *   Um sistema de monitoramento de banco de dados detecta uma query longa ou com sintaxe incomum.
    *   A query é enviada para `SqlInjectionProtection.check_query(suspicious_query_string)`.
    *   Se retornar `{:ok, :suspicious}`, um alerta é gerado.
*   **Sanitização de Termo de Busca para `ILIKE` (se não parametrizável diretamente):**
    *   (Nota: Ecto geralmente lida bem com `like` parametrizado)
    *   Se um termo de busca precisasse ser interpolado diretamente (EVITAR), ele seria sanitizado: `SqlInjectionProtection.sanitize_string(search_term, %{context: :sql_like_value})`.

## 🌊 5. Fluxos Importantes

### Fluxo de Verificação de Entrada para Cláusula de Ordenação Dinâmica

1.  **Entrada do Usuário:** Controller recebe `params = %{\"sort_by\" => \"name'; DROP TABLE users; --\", \"order\" => \"ASC\"}`.
2.  **Validação de Lista Branca (Lógica no Controller/Serviço):**
    *   `sort_field = params[\"sort_by\"]`
    *   `sort_order = params[\"order\"] |> String.downcase() |> String.to_atom()`
    *   `is_valid_field = sort_field in @allowed_sort_fields`
    *   `is_valid_order = sort_order in [:asc, :desc]`
3.  **(Opcional) Verificação Adicional com `SqlInjectionProtection`:**
    *   `{:ok, status} = SqlInjectionProtection.check_string(sort_field)`
    *   Se `status == :suspicious`, logar/alertar, mesmo que a lista branca o negue.
4.  **Decisão:**
    *   Se `is_valid_field` e `is_valid_order` forem `true`, usar os valores na query Ecto.
    *   Senão, usar ordenação padrão ou retornar erro. **Nunca interpolar `sort_field` diretamente na query Ecto sem validação.**
    ```elixir
    # Exemplo seguro com Ecto
    dynamic_order_by =
      if is_valid_field and is_valid_order do
        [{sort_order, String.to_atom(sort_field)}]
      else
        # Ordenação padrão
        [asc: :id]
      end
    from(p in Post, order_by: ^dynamic_order_by)
    ```

## 📡 6. API (Funções Públicas da Fachada)

### 6.1. `DeeperHub.Security.SqlInjectionProtection.check_string(input :: String.t(), opts :: keyword()) :: {:ok, :safe | :suspicious} | {:error, term()}`

*   **Descrição:** Analisa uma string de entrada para detectar padrões comuns de SQL Injection. Não modifica a string.
*   **`opts`:**
    *   `:db_type` (atom): Tipo de banco de dados (ex: `:postgres`, `:mysql`) para detecção específica de dialeto. (Padrão: `:generic`)
    *   `:sensitivity` (atom): Nível de sensibilidade da detecção (`:low`, `:medium`, `:high`). (Padrão: `:medium`)
*   **Retorno:** `:safe` se nenhum padrão óbvio for encontrado, `:suspicious` se padrões forem detectados.

### 6.2. `DeeperHub.Security.SqlInjectionProtection.check_query(query_string :: String.t(), opts :: keyword()) :: {:ok, :safe | :suspicious, list(String.t())} | {:error, term()}`

*   **Descrição:** Analisa uma string de consulta SQL completa para detectar vulnerabilidades.
*   **`opts`:** Similar a `check_string/2`.
*   **Retorno:** `{:ok, :safe | :suspicious, threats_found :: list(String.t())}`. A lista `threats_found` detalha os tipos de ameaças.

### 6.3. `DeeperHub.Security.SqlInjectionProtection.sanitize_string(input :: String.t(), opts :: keyword()) :: {:ok, String.t()} | {:error, term()}`

*   **Descrição:** Tenta sanitizar uma string escapando caracteres especiais relevantes para SQL. **Deve ser usado como último recurso quando a parametrização não é possível.**
*   **`opts`:**
    *   `:db_type` (atom): Para escaping específico do dialeto. (Padrão: `:generic`, que pode escapar apóstrofos).
    *   `:context` (atom): Contexto onde a string será usada (ex: `:string_literal`, `:identifier`). Para identifiers, idealmente usar listas brancas.
*   **Exemplo:**
    ```elixir
    {:ok, safe_name} = SqlInjectionProtection.sanitize_string(\"O'Reilly\") 
    # safe_name pode ser \"O''Reilly\" para PostgreSQL
    ```

### 6.4. `DeeperHub.Security.SqlInjectionProtection.generate_safe_query(spec :: map(), opts :: keyword()) :: {:ok, Ecto.Query.t() | {String.t(), list()}} | {:error, term()}` (Mais Complexo)

*   **Descrição:** (Funcionalidade avançada e potencialmente complexa de implementar de forma genérica e segura). Tenta gerar uma query Ecto ou uma string SQL parametrizada a partir de uma especificação de alto nível, validando todos os identificadores contra listas brancas.
*   **`spec`:** Um mapa descrevendo a query (tabelas, colunas, joins, where, order by, limit).
*   **`opts`:**
    *   `:allowed_tables` (list(String.t))
    *   `:allowed_columns_for_table` (mapa `%{table_name => list(String.t)}`)
*   **Retorno:** Uma query Ecto ou uma tupla `{sql_string, params}`.

### 6.5. `DeeperHub.Security.SqlInjectionProtection.record_injection_attempt(input_string :: String.t(), source_info :: map(), context :: map() | nil) :: :ok`

*   **Descrição:** Registra uma tentativa de SQL Injection detectada.
*   **`source_info`:** `%{ip_address: \"...\", user_id: \"...\", path: \"...\"}`.
*   **`context`:** `%{field_name: \"...\", query_type: \"...\"}`.

## ⚙️ 7. Configuração

Via `DeeperHub.Core.ConfigManager` e/ou `DeeperHub.Security.Policy.SecurityPolicyManager`:

*   **`[:security, :sql_injection_protection, :enabled]`** (Boolean): Habilita/desabilita as verificações. (Padrão: `true`)
*   **`[:security, :sql_injection_protection, :detection_patterns]`** (List de Regex): Lista de padrões regex usados por `check_string/2` e `check_query/2`.
*   **`[:security, :sql_injection_protection, :allowed_sort_columns, <context_key>]`** (List de Strings): Lista branca de colunas permitidas para ordenação dinâmica em diferentes contextos (ex: `user_list`, `server_list`).
*   **`[:security, :sql_injection_protection, :log_suspicious_attempts]`** (Boolean): Se tentativas detectadas devem ser logadas. (Padrão: `true`)
*   **`[:security, :sql_injection_protection, :block_on_suspicious_input]`** (Boolean): Se deve bloquear requisições que contenham entradas suspeitas (ação agressiva). (Padrão: `false`, geralmente apenas loga/alerta).

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager`: Para configurações.
*   `DeeperHub.Core.Logger`: Para logging de tentativas e erros.
*   `DeeperHub.Core.Metrics`: Para métricas.
*   `DeeperHub.Audit`: Para registrar tentativas bloqueadas.
*   `Ecto`: Indiretamente, pois o objetivo é proteger as queries Ecto.

### 8.2. Bibliotecas Externas

*   Nenhuma específica para a lógica de detecção baseada em regex ou validação de lista branca. Bibliotecas de parsing SQL poderiam ser usadas para análises mais profundas, mas adicionam complexidade.

## 🤝 9. Como Usar / Integração

*   **Priorizar Ecto:** A principal estratégia é usar `Ecto.Query` e changesets corretamente.
    ```elixir
    # SEGURO
    def get_user_by_name(name_param) do
      from(u in User, where: u.name == ^name_param) |> Repo.one()
    end
    ```
*   **Validação de Lista Branca para Identificadores Dinâmicos:**
    ```elixir
    def list_products(sort_field_param, sort_order_param) do
      valid_fields = ~w(name price created_at)a
      valid_orders = ~w(asc desc)a

      sort_field = if Enum.member?(valid_fields, String.to_atom(sort_field_param)), do: String.to_atom(sort_field_param), else: :name
      sort_order = if Enum.member?(valid_orders, String.to_atom(sort_order_param)), do: String.to_atom(sort_order_param), else: :asc
      
      # Adicionalmente, pode-se chamar check_string/2 para logar se a entrada original era suspeita
      DeeperHub.Security.SqlInjectionProtection.check_string(sort_field_param)
      DeeperHub.Security.SqlInjectionProtection.check_string(sort_order_param)

      from(p in Product, order_by: [{^sort_order, ^sort_field}]) |> Repo.all()
    end
    ```
*   **Verificar Entradas Suspeitas (ex: em um Plug de Segurança Genérico):**
    ```elixir
    # Plug para verificar todos os parâmetros de uma requisição
    Enum.each(conn.params, fn {key, value} ->
      if is_binary(value) do
        case DeeperHub.Security.SqlInjectionProtection.check_string(value, %{source_field: key}) do
          {:ok, :suspicious} ->
            DeeperHub.Security.SqlInjectionProtection.record_injection_attempt(value, %{ip: ..., path: ...}, %{field: key})
            # Pode-se decidir bloquear a requisição aqui se a política for agressiva
          _ -> :ok
        end
      end
    end)
    ```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar `check_string/2` e `check_query/2` com vários vetores de SQL Injection conhecidos para diferentes dialetos SQL.
*   Testar `sanitize_string/2` para garantir que ele escape corretamente os caracteres perigosos.
*   Verificar a lógica de validação de lista branca para identificadores dinâmicos.
*   Localização: `test/deeper_hub/security/sql_injection_protection/`.

### 10.2. Métricas

*   `deeper_hub.security.sqli.input_checked.count` (tags: `context`, `result` (`safe`, `suspicious`))
*   `deeper_hub.security.sqli.suspicious_pattern_detected.count` (tags: `pattern_type`, `context`)
*   `deeper_hub.security.sqli.attempts_recorded.count`

### 10.3. Logs

*   **Nível WARNING:** `check_string/2` ou `check_query/2` detecta um padrão suspeito.
*   **Nível ERROR:** Tentativa de SQL Injection confirmada e bloqueada (se configurado para bloquear).

### 10.4. Telemetria

*   `[:deeper_hub, :security, :sqli, :check_string, :stop]`
    *   Metadados: `%{input_sample: String.slice(input, 0, 50), result: :safe | :suspicious, threats: list_of_threats}`
*   `[:deeper_hub, :security, :sqli, :sanitize_string, :stop]`
    *   Metadados: `%{input_changed: boolean}`

## ❌ 11. Tratamento de Erros

*   A detecção de um padrão suspeito por `check_string/2` ou `check_query/2` deve, no mínimo, gerar um log/alerta. A decisão de bloquear a requisição depende da política (`:block_on_suspicious_input`).
*   Erros no próprio serviço de proteção (ex: regex malformada na configuração) devem ser logados criticamente.

## 🛡️ 12. Considerações de Segurança (do próprio Módulo)

*   **Regexes de Detecção:** As expressões regulares usadas para detectar padrões de SQLi devem ser cuidadosamente elaboradas para evitar falsos positivos excessivos e para cobrir uma ampla gama de vetores de ataque. Elas também podem ser um gargalo de performance se forem muito complexas e aplicadas a muitas entradas.
*   **Escaping Insuficiente:** A sanitização por escaping é inerentemente mais frágil do que a parametrização. Diferentes bancos de dados têm diferentes necessidades de escaping.
*   **Contexto é Importante:** Um \"padrão suspeito\" em um campo de texto livre pode ser diferente de um padrão suspeito em um campo que se espera ser um número.

## 🧑‍💻 13. Contribuição

*   **NÃO CONSTRUA QUERIES SQL CONCATENANDO STRINGS DE ENTRADA DO USUÁRIO.** Use Ecto e consultas parametrizadas.
*   Use este módulo principalmente para:
    *   Validar identificadores (nomes de colunas/tabelas) contra listas brancas se eles precisarem ser dinâmicos.
    *   Como uma camada de verificação adicional para logar/alertar sobre entradas suspeitas, mesmo que a query principal seja parametrizada.
*   Mantenha os padrões de detecção (regexes) atualizados com base em novas técnicas de SQLi.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Integrar com bibliotecas de parsing SQL mais robustas para uma análise sintática e semântica das queries, em vez de depender apenas de regex.
*   [ ] Desenvolver uma \"API de query segura\" mais elaborada (`generate_safe_query/2`) que abstraia a construção de queries Ecto dinâmicas comuns de forma segura.
*   [ ] Adicionar aprendizado de máquina para identificar queries SQL anômalas com base no tráfego normal do banco de dados.
*   [ ] Fornecer mais contexto para as funções `check_string` e `sanitize_string` sobre onde a string será usada (ex: dentro de um literal string, como um identificador, em uma cláusula numérica) para aplicar regras de sanitização/validação mais precisas.

---

*Última atualização: 2025-05-12*

---

Proteção contra SQL Injection é um clássico da segurança web!

O próximo poderia ser `DeeperHub.Security.XssProtection` (que já documentamos) ou `DeeperHub.Security.PathTraversalProtection` ou `DeeperHub.Security.DdosProtection`. Qual prefere?"""),
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
                types.Part.from_text(text="""Já documentamos o `DeeperHub.Security.XssProtection`.

Que tal seguirmos com o `DeeperHub.Security.PathTraversalProtection`? É outra vulnerabilidade comum relacionada ao acesso a arquivos.

---

