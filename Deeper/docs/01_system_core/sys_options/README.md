# Documentação Deeper: Configurações do Sistema (`sys_options`)

Este documento descreve como a API \"Deeper\" fornecerá acesso às configurações globais e de módulos armazenadas nas tabelas `sys_options`, `sys_options_categories`, e `sys_options_types` do sistema UNA.

**Objetivo Principal:** Permitir que o cliente remoto (e o próprio backend \"Deeper\") obtenham valores de configuração necessários para renderizar a interface, habilitar/desabilitar funcionalidades ou ajustar comportamentos.

**Nota:** Esta seção foca em *ler* as configurações. A API para *modificar* as configurações será parte da \"API do Studio/Admin\" (`07_studio_admin_api/`).

## Tabelas Relevantes do UNA (e sua adaptação para \"Deeper\"):

1.  **`sys_options_types`**:
    *   Define os grandes grupos de configurações (ex: \"General\", \"Performance\", \"Security\").
    *   Campos: `id`, `group`, `name`, `caption`, `icon`, `order`.

2.  **`sys_options_categories`**:
    *   Subdivide os `types` em categorias mais específicas (ex: dentro de \"General\", pode haver \"Site Info\", \"Emails\").
    *   Campos: `id`, `type_id` (FK para `sys_options_types.id`), `name`, `caption`, `hidden`, `order`.

3.  **`sys_options`**:
    *   Armazena as configurações individuais.
    *   Campos: `id`, `category_id` (FK para `sys_options_categories.id`), `name` (nome único da opção, ex: `site_title`), `caption`, `info`, `value` (o valor da configuração), `type` (tipo de dado da opção: digit, text, checkbox, select, etc.), `extra` (para selects, etc.), `check`, `check_params`, `check_error`, `order`.

## Estratégia da API \"Deeper\" para Configurações:

A API \"Deeper\" fornecerá endpoints para buscar configurações de forma granular ou agrupada.

### Módulo de Acesso a Dados (`Deeper.SystemCore.OptionsRepo`):

Um módulo como `Deeper.SystemCore.OptionsRepo` encapsulará as queries SQL para as tabelas `sys_options*`.

**Funções Principais e SQLs Esperados:**

*   **`get_option(name :: String.t()) :: {:ok, option_value :: any()} | {:error, :not_found | any()}`**
    *   Busca o valor de uma configuração específica pelo seu nome único.
    *   SQL: `SELECT value, type FROM sys_options WHERE name = ? LIMIT 1;`
    *   A função precisará converter o `value` (que é texto no DB) para o tipo Elixir apropriado com base na coluna `type` (ex: \"checkbox\" para booleano, \"digit\" para inteiro).

*   **`get_options_by_category_name(category_name :: String.t()) :: {:ok, list(map())} | {:error, any()}`**
    *   Busca todas as opções de uma categoria específica.
    *   SQL:

```json
        {
          \"data\": {
            \"name\": \"site_title\",
            \"value\": \"My Deeper Site\",
            \"type\": \"text\",
            \"caption\": \"Site Title\"
          }
        }
```

```json
        {
          \"data\": [
            { \"name\": \"site_title\", \"value\": \"My Deeper Site\", \"type\": \"text\", ... },
            { \"name\": \"maintenance_mode\", \"value\": false, \"type\": \"checkbox\", ... }
          ],
          \"category_info\": {
            \"name\": \"site_info\",
            \"caption\": \"Site Information\"
          }
        }
```

```json
        {
          \"data\": {
            \"general_settings\": { // Corresponde a sys_options_types.name
              \"caption\": \"General Settings\",
              \"categories\": {
                \"site_information\": { // Corresponde a sys_options_categories.name
                  \"caption\": \"Site Information\",
                  \"options\": {
                    \"site_title\": { \"value\": \"My Deeper Site\", \"type\": \"text\", \"caption\": \"...\" },
                    \"maintenance_mode\": { \"value\": false, \"type\": \"checkbox\", \"caption\": \"...\" }
                  }
                },
                // ... outras categorias ...
              }
            },
            // ... outros tipos de configuração ...
          }
        }
```

```sql
        SELECT so.name, so.value, so.type, so.caption, so.info, so.extra
        FROM sys_options so
        JOIN sys_options_categories soc ON so.category_id = soc.id
        WHERE soc.name = ?;
```

```sql
            SELECT
                sot.name AS type_name, sot.caption AS type_caption,
                soc.name AS category_name, soc.caption AS category_caption,
                so.name AS option_name, so.value AS option_value, so.type AS option_type,
                so.caption AS option_caption, so.info AS option_info, so.extra AS option_extra
            FROM sys_options_types sot
            JOIN sys_options_categories soc ON sot.id = soc.type_id
            JOIN sys_options so ON soc.id = so.category_id
            WHERE soc.hidden = 0 OR soc.hidden IS NULL -- Ou o equivalente para booleano
            ORDER BY sot.\"order\", soc.\"order\", so.\"order\";
```

```sql
CREATE TABLE IF NOT EXISTS sys_options (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category_id INTEGER NOT NULL, -- FK para sys_options_categories.id
  name TEXT NOT NULL UNIQUE,
  caption TEXT NOT NULL,
  info TEXT,
  value TEXT NOT NULL, -- Armazena o valor como string
  type TEXT NOT NULL DEFAULT 'text' CHECK(type IN ('value','digit','text','code','checkbox','select','combobox','file','image','list','rlist','rgb','rgba','datetime')),
  extra TEXT, -- Para 'select', 'list', etc., pode conter valores possíveis (JSON ou CSV)
  \"check\" TEXT, -- Nome da função de validação (lógica no UNA PHP)
  check_params TEXT,
  check_error TEXT,
  \"order\" INTEGER DEFAULT 0,
  FOREIGN KEY (category_id) REFERENCES sys_options_categories(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_sys_options_name ON sys_options(name);
CREATE INDEX IF NOT EXISTS idx_sys_options_category_id ON sys_options(category_id);
```

```elixir
        %{
          \"general_type\" => %{
            \"type_caption\" => \"General Settings\",
            \"categories\" => %{
              \"site_info_category\" => %{
                \"category_caption\" => \"Site Information\",
                \"options\" => %{
                  \"site_title\" => %{value: \"My Deeper Site\", type: \"text\", caption: \"Site Title\", ...},
                  \"maintenance_mode\" => %{value: false, type: \"checkbox\", caption: \"Maintenance Mode\", ...}
                }
              }
            }
          }
        }
```

    *   Retorna uma lista de mapas, onde cada mapa representa uma opção com seu nome, valor (convertido), tipo, legenda, etc.

*   **`get_all_options_structured() :: {:ok, structured_options :: map()} | {:error, any()}`**
    *   Busca todas as opções e as retorna em uma estrutura aninhada por tipo e categoria. Isso pode ser útil para o cliente obter todas as configurações de uma vez.
    *   SQL (requer múltiplas queries ou um JOIN complexo e processamento em Elixir):
        1.  Buscar todos os tipos.
        2.  Para cada tipo, buscar suas categorias.
        3.  Para cada categoria, buscar suas opções.
        *   Alternativa com JOIN:

    *   O resultado seria processado em Elixir para criar um mapa como:

*   **`parse_option_value(value_string :: String.t(), type_string :: String.t()) :: any()`** (Função auxiliar privada)
    *   Converte o valor da string do banco de dados para o tipo Elixir correto.
    *   Ex:
        *   `\"checkbox\"`: \"on\" ou \"1\" -> `true`, outros -> `false`.
        *   `\"digit\"`: `String.to_integer/1`.
        *   `\"text\"`: `value_string`.
        *   `\"select\"` (com `extra` contendo `possible_values`): o valor da string.
        *   `\"list\"`, `\"rlist\"`: pode precisar de parsing se `value` for uma string delimitada.

### Endpoints da API (`/api/v1/system/options`):

*   **Obter Valor de uma Opção Específica:**
    *   **Endpoint:** `GET /api/v1/system/options/{option_name}`
    *   **Descrição:** Retorna o valor (e possivelmente metadados) de uma única opção de configuração.
    *   **Autenticação:** Opcional. Algumas configurações podem ser públicas, outras podem exigir autenticação/autorização.
    *   **Resposta de Sucesso (200 OK):**

    *   **Respostas de Erro:** `404 Not Found`.

*   **Obter Opções de uma Categoria:**
    *   **Endpoint:** `GET /api/v1/system/options/category/{category_name}`
    *   **Descrição:** Retorna todas as opções de uma categoria específica.
    *   **Autenticação:** Opcional.
    *   **Resposta de Sucesso (200 OK):**

*   **Obter Todas as Configurações Estruturadas (para Cliente Inicializar):**
    *   **Endpoint:** `GET /api/v1/system/options/all`
    *   **Descrição:** Retorna todas as configurações visíveis, estruturadas por tipo e categoria. Ideal para o cliente buscar uma vez e cachear.
    *   **Autenticação:** Opcional.
    *   **Resposta de Sucesso (200 OK):**

## Tabelas de Configuração (Esquema SQLite):

Os `CREATE TABLE` statements para `sys_options_types`, `sys_options_categories`, e `sys_options` precisarão ser definidos no `docs/00_core_concepts/database_schema_sqlite.md` e ter suas respectivas migrações Elixir.

**Exemplo `sys_options` (SQLite):**

*(As tabelas `sys_options_types` e `sys_options_categories` seguiriam um padrão similar de adaptação para SQLite).*

## Considerações:

*   **Sensibilidade das Configurações:** Nem todas as configurações devem ser expostas publicamente. A API precisará de uma lógica (possivelmente baseada em uma flag na tabela `sys_options` ou por categoria/tipo) para determinar quais opções são seguras para retornar a clientes não autenticados ou com níveis de permissão mais baixos. Por padrão, pode-se assumir que a maioria das configurações é para uso interno do backend ou para clientes autenticados com privilégios adequados.
*   **Cache:** Configurações geralmente não mudam com frequência. O backend \"Deeper\" pode cachear os valores de `sys_options` na memória (ex: usando um Agente ou ETS) para evitar acessos repetidos ao banco de dados. O cliente também pode cachear as configurações obtidas.

Com esta API, o cliente pode obter as configurações necessárias para adaptar seu comportamento e interface, como o título do site, se o modo de manutenção está ativo, etc.