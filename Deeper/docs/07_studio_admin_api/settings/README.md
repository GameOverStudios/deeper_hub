# Documentação Deeper Studio API: Gerenciamento de Configurações (`sys_options`)

Este documento descreve os endpoints da API de Administração (\"Studio API\") para listar, visualizar e **modificar** as configurações do sistema armazenadas nas tabelas `sys_options`, `sys_options_categories`, e `sys_options_types`.

**Objetivo Principal:** Permitir que administradores alterem as configurações da plataforma \"Deeper\" através de uma interface de administração que consome esta API.

## Tabelas Relevantes (já definidas e migradas):

*   `sys_options_types`: Grupos principais de configurações.
*   `sys_options_categories`: Subcategorias dentro dos tipos.
*   `sys_options`: As configurações individuais com seus valores e metadados.
*   `sys_options_mixes`: Para gerenciamento de \"temas\" ou conjuntos de configurações pré-definidas (pode ser uma funcionalidade mais avançada para a API de admin).

## Módulo de Acesso a Dados (`Deeper.SystemCore.OptionsRepo`):

O `OptionsRepo` (já parcialmente definido para leitura em `01_system_core/sys_options/`) precisará ser estendido com funções para **atualizar** os valores das configurações.

**Funções Adicionais ou Modificadas no `OptionsRepo`:**

*   **`update_option_value(option_name :: String.t(), new_value :: any()) :: {:ok, updated_option :: map()} | {:error, :not_found | :validation_failed | any()}`**
    1.  Busca a definição da opção de `sys_options` por `option_name` (incluindo `type`, `check`, `check_params`, `check_error`).
    2.  **Validação:**
        *   Converte `new_value` (que pode vir como string de um formulário JSON) para o tipo esperado com base em `option_info[\"type\"]`.
        *   Aplica a validação definida por `option_info[\"check\"]` e `option_info[\"check_params\"]`. A lógica de validação do UNA PHP (ex: ` Preg`, `Xss`, `Avail`) precisará ser mapeada/replicada em Elixir. Se a validação falhar, retorna `{:error, :validation_failed, localized_error_message}`.
    3.  Converte `new_value` validado de volta para string para armazenamento em `sys_options.value` (a menos que o tipo da coluna `value` seja alterado no SQLite, o que não foi o caso até agora).
    4.  SQL: `UPDATE sys_options SET value = ? WHERE name = ? RETURNING *;`
    5.  Retorna os dados da opção atualizada (com o valor parseado/convertido).
    6.  **Invalidação de Cache:** Se as opções são cacheadas, esta função deve invalidar o cache da opção modificada (ou todo o cache de opções).

*   **`list_all_options_with_structure_for_admin() :: {:ok, structured_options :: map()} | {:error, any()}`**
    *   Similar a `get_all_options_structured()` mas pode incluir opções ocultas ou mais metadados úteis para o admin (como `check`, `check_params`).
    *   SQL (exemplo):

```json
        {
          \"data\": { // Estrutura aninhada por tipo e categoria
            \"general_type_name\": {
              \"type_id\": 1,
              \"caption\": \"General Settings\", // Traduzido
              \"categories\": {
                \"site_info_category_name\": {
                  \"category_id\": 10,
                  \"caption\": \"Site Information\", // Traduzido
                  \"is_hidden\": false,
                  \"options\": [ // Lista de opções para manter a ordem
                    {
                      \"name\": \"site_title\",
                      \"value\": \"My Deeper Site\",
                      \"type\": \"text\", // text, digit, checkbox, select, textarea, etc.
                      \"caption\": \"Site Title\", // Traduzido
                      \"info\": \"The main title of your website.\", // Traduzido
                      \"extra\": null, // Para selects, conteria as opções
                      \"validation\": { // Informações de validação para o frontend
                        \"check_func\": \"Length\",
                        \"check_params\": \"3,100\",
                        \"error_message_key\": \"_sys_option_error_site_title_length\"
                      }
                    },
                    // ... outras opções na categoria ...
                  ]
                }
                // ... outras categorias ...
              }
            }
            // ... outros tipos de configuração ...
          }
        }
```

```json
        {
          \"value\": \"My Awesome Deeper Site\" // O novo valor para a opção
        }
```

```json
        {
          \"data\": { // A opção atualizada
            \"name\": \"site_title\",
            \"value\": \"My Awesome Deeper Site\",
            \"type\": \"text\",
            \"caption\": \"Site Title\",
            // ...
          },
          \"message\": \"Setting updated successfully.\"
        }
```

```json
        {
          \"options\": [
            {\"name\": \"site_title\", \"value\": \"New Title\"},
            {\"name\": \"maintenance_mode\", \"value\": \"on\"}, // Para checkbox
            {\"name\": \"items_per_page\", \"value\": \"25\"} // Para digit
          ]
        }
```

```json
        {
          \"data\": {
            \"updated_count\": 3,
            \"errors_count\": 0,
            \"errors\": [] // Lista de erros se alguma falhar
          },
          \"message\": \"Settings updated.\"
        }
```

```sql
        SELECT
            sot.name AS type_name, sot.caption AS type_caption, sot.id AS type_id,
            soc.name AS category_name, soc.caption AS category_caption, soc.id AS category_id, soc.hidden AS category_hidden,
            so.name AS option_name, so.value AS option_value, so.type AS option_type,
            so.caption AS option_caption, so.info AS option_info, so.extra AS option_extra,
            so.\"check\" AS option_check_func, so.check_params AS option_check_params, so.check_error AS option_check_error
        FROM sys_options_types sot
        LEFT JOIN sys_options_categories soc ON sot.id = soc.type_id
        LEFT JOIN sys_options so ON soc.id = so.category_id
        ORDER BY sot.\"order\", soc.\"order\", so.\"order\";
```

    *   A API processaria isso em uma estrutura aninhada para fácil renderização em um painel de admin.

## Endpoints da API de Administração para Configurações (`/api/v1/admin/settings`):

*   **Listar Todas as Configurações Estruturadas para Administração:**
    *   **Endpoint:** `GET /api/v1/admin/settings/options`
    *   **Autenticação:** Requer JWT de Admin.
    *   **Query Parameters:** `lang` (para traduções de legendas, etc.).
    *   **Resposta de Sucesso (200 OK):**

*   **Obter uma Configuração Específica (com metadados de admin):**
    *   **Endpoint:** `GET /api/v1/admin/settings/options/{option_name}`
    *   **Autenticação:** Requer JWT de Admin.
    *   **Resposta de Sucesso (200 OK):** Similar a um item na lista acima.

*   **Atualizar o Valor de uma Configuração Específica:**
    *   **Endpoint:** `PUT /api/v1/admin/settings/options/{option_name}`
    *   **Autenticação:** Requer JWT de Admin.
    *   **Corpo da Requisição (JSON):**

    *   **Resposta de Sucesso (200 OK):**

    *   **Respostas de Erro:**
        *   `400 Bad Request`: `value` não fornecido.
        *   `404 Not Found`: `option_name` não existe.
        *   `422 Unprocessable Entity`: Falha na validação do `value` (com detalhes do erro).
        *   `500 Internal Server Error`: Falha ao salvar no DB.

*   **(Opcional) Atualizar Múltiplas Configurações em Lote:**
    *   **Endpoint:** `PUT /api/v1/admin/settings/options/batch`
    *   **Autenticação:** Requer JWT de Admin.
    *   **Corpo da Requisição (JSON):**

    *   **Resposta de Sucesso (200 OK):**

    *   **Lógica do Backend:** Itera sobre cada opção, chama `OptionsRepo.update_option_value`. Agrupa resultados e erros. Idealmente, seria transacional se possível para todas as atualizações.

## Considerações para a API de Admin de Configurações:

*   **Validação e Sanitização:** A replicação da lógica de `check` e `db_pass` do UNA PHP em Elixir é crucial para manter a integridade e segurança dos dados de configuração.
*   **Tipos de Dados:** A API deve lidar corretamente com a conversão entre os tipos de dados da UI (strings, booleanos da UI) e os tipos esperados pela validação e armazenamento (ex: `value` em `sys_options` é `TEXT`).
*   **Interface do Usuário Admin:** A resposta de `GET /options` deve ser rica o suficiente para que uma UI de administração possa renderizar os campos de configuração apropriados (input text, checkbox, select com opções, etc.) e exibir informações de validação.
*   **Impacto das Alterações:** Algumas configurações podem ter impacto imediato e amplo no sistema. A UI de admin deve alertar sobre isso.
*   **Cache:** Após atualizar uma configuração, o cache de opções no backend \"Deeper\" deve ser invalidado. O cliente também pode ser instruído a recarregar as configurações.

Esta API de configurações permitirá um gerenciamento robusto das opções do sistema \"Deeper\" através de uma interface de administração.