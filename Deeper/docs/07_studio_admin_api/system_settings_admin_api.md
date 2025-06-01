# Documentação Deeper: API de Administração - Configurações do Sistema

Este documento descreve os endpoints da API \"Deeper\" para gerenciar as configurações do sistema, que são armazenadas nas tabelas `sys_options_types`, `sys_options_categories`, e principalmente `sys_options`.

## Escopo e Funcionalidades:

*   Listar todos os tipos de opções.
*   Listar todas as categorias de opções (opcionalmente filtradas por tipo).
*   Listar todas as opções (configurações) com seus valores atuais, opcionalmente filtradas por categoria.
*   Obter o valor de uma opção específica pelo seu nome.
*   Atualizar o valor de uma ou mais opções.

**Nota:** A criação de novos tipos, categorias ou definições de opções (a estrutura em si) geralmente é feita via migrações ou diretamente no banco de dados durante o desenvolvimento do módulo, e não dinamicamente pela API de administração. Esta API foca em gerenciar os *valores* das opções existentes.

## Tabelas Relevantes (Já Definidas em `docs/01_system_core/sys_options/`):

*   `sys_options_types`
*   `sys_options_categories`
*   `sys_options`

## Módulo de Acesso a Dados (Já Definido em `docs/01_system_core/sys_options/data_access_module.md`):

*   `Deeper.SystemCore.OptionsRepo` (ou nome similar) será utilizado para todas as interações com o banco de dados.

## Endpoints da API de Administração para Configurações

Todos os endpoints estão sob `/api/v1/admin/settings/...` e requerem autenticação de administrador.

### 1. Listar Tipos de Opções

*   **Endpoint:** `GET /api/v1/admin/settings/option-types`
*   **Propósito:** Retorna uma lista de todos os tipos de configuração definidos em `sys_options_types`.
*   **Autenticação:** Administrador.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"group_name\": \"general\", // Nome original era `group`
          \"name\": \"site\",
          \"caption\": \"Site Settings\", // Título traduzido
          \"icon\": \"settings-outline\",
          \"order\": 1
        }
        // ... mais tipos ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"type_id\": 1,
          \"name\": \"general_site\",
          \"caption\": \"General Site Settings\", // Título traduzido
          \"hidden\": 0,
          \"order\": 1
        }
        // ... mais categorias ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"category_id\": 1,
          \"name\": \"site_title\",
          \"caption\": \"Site Title\", // Título traduzido
          \"info\": \"The main title of the website.\", // Info traduzida
          \"value\": \"Deeper Community\",
          \"type\": \"text\", // tipo de input: value, digit, text, checkbox, select, etc.
          \"extra\": \"\", // Para selects/comboboxes: nome da prelist (ex: sys_yes_no)
          \"order\": 1
        },
        {
          \"id\": 2,
          \"category_id\": 1,
          \"name\": \"maintenance_mode\",
          \"caption\": \"Maintenance Mode\",
          \"info\": \"Enable to put the site in maintenance mode.\",
          \"value\": \"0\", // 0 ou 1 para checkbox
          \"type\": \"checkbox\",
          \"extra\": \"sys_boolean\", // Prelist para valores de checkbox
          \"order\": 2
        }
        // ... mais opções ...
      ]
      // Paginação pode ser adicionada se a lista for muito grande
    }
```

```json
    {
      \"site_title\": \"Deeper Social Platform\",
      \"maintenance_mode\": \"1\",
      \"default_lang\": \"en\"
    }
```

```json
    {
      \"message\": \"Settings updated successfully.\",
      \"updated_options\": [ // Opcional: lista das opções que foram atualizadas
        \"site_title\",
        \"maintenance_mode\",
        \"default_lang\"
      ]
    }
```

```json
    {
      \"error\": {
        \"code\": \"VALIDATION_ERROR\",
        \"message\": \"One or more settings could not be updated.\",
        \"details\": [
          {
            \"option_name\": \"items_per_page\",
            \"issue\": \"Value must be a positive integer.\"
          },
          {
            \"option_name\": \"non_existent_option\",
            \"issue\": \"Option not found.\"
          }
        ]
      }
    }
```

### 2. Listar Categorias de Opções

*   **Endpoint:** `GET /api/v1/admin/settings/option-categories`
*   **Propósito:** Retorna uma lista de todas as categorias de configuração de `sys_options_categories`.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `type_id` (Integer, Opcional): Filtrar categorias por `sys_options_types.id`.
    *   `lang` (String, Opcional): Para tradução dos `caption`.
*   **Resposta de Sucesso (200 OK):**

### 3. Listar Todas as Opções (Configurações)

*   **Endpoint:** `GET /api/v1/admin/settings/options`
*   **Propósito:** Retorna uma lista de todas as configurações definidas em `sys_options`, com seus valores atuais.
*   **Autenticação:** Administrador.
*   **Query Parameters:**
    *   `category_id` (Integer, Opcional): Filtrar opções por `sys_options_categories.id`.
    *   `type_id` (Integer, Opcional): Filtrar opções pelo `type_id` da categoria.
    *   `search_term` (String, Opcional): Buscar no nome (`sys_options.name`) ou `caption` da opção.
    *   `lang` (String, Opcional): Para tradução dos `caption` e `info`.
*   **Resposta de Sucesso (200 OK):**

    *   **Nota:** O campo `extra` pode conter o nome de uma `sys_form_pre_lists` se o tipo for `select` ou `rlist`. A API pode, opcionalmente, buscar e aninhar os valores dessa prelist.

### 4. Obter Detalhes de uma Opção Específica

*   **Endpoint:** `GET /api/v1/admin/settings/options/{option_name}`
*   **Propósito:** Retorna os detalhes e o valor de uma opção específica pelo seu nome único.
*   **Autenticação:** Administrador.
*   **Parâmetros de URL:**
    *   `{option_name}` (String, Obrigatório): O campo `name` da tabela `sys_options`.
*   **Query Parameters:**
    *   `lang` (String, Opcional): Para tradução.
*   **Resposta de Sucesso (200 OK):** Similar a um item da lista do endpoint anterior.

### 5. Atualizar Valor de Uma ou Mais Opções

*   **Endpoint:** `PUT /api/v1/admin/settings/options`
*   **Propósito:** Atualiza o valor de uma ou mais opções.
*   **Autenticação:** Administrador.
*   **Corpo da Requisição (JSON):**
    Um objeto onde as chaves são os nomes das opções (`sys_options.name`) e os valores são os novos valores para essas opções.

*   **Lógica do Backend:**
    1.  Para cada par chave-valor no corpo da requisição:
        *   Verificar se a opção (`key`) existe em `sys_options`.
        *   Validar o novo `value` com base no `sys_options.type` e `sys_options.check` (ex: se `type` é `digit`, o valor deve ser numérico; se `check` é `Xss`, aplicar sanitização). Esta validação é crucial.
        *   Se válido, chamar `OptionsRepo.update_option_value(option_name, new_value)`.
    2.  Pode ser necessário limpar caches de configuração após a atualização.
*   **Resposta de Sucesso (200 OK):**

*   **Resposta de Erro (400 Bad Request ou 422 Unprocessable Entity):**
    Se alguma opção não existir, ou se algum valor falhar na validação. A resposta deve detalhar os erros.

### Considerações de Implementação:

*   **Validação de Valores:** A validação dos valores das opções antes de salvá-los é crítica. O UNA original usa `sys_options.check` (ex: `Xss`, `Avail`, `Date`, `Preg`) e `sys_options.check_params`. Essa lógica de validação precisará ser portada para Elixir no `OptionsRepo` ou em um serviço de validação.
*   **Tipos de Input:** O campo `sys_options.type` indica como a opção deve ser renderizada no admin (text, checkbox, select, etc.). A API deve fornecer essa informação para que o cliente de administração possa renderizar o controle correto. Se for `select` ou `rlist`, o campo `extra` geralmente contém o nome da `sys_form_pre_lists` cujos valores devem ser usados. A API pode precisar de um endpoint auxiliar para buscar valores de prelists.
*   **Cache:** Após atualizar opções, qualquer cache de configuração no lado do servidor deve ser invalidado/atualizado.

Esta API fornece as funcionalidades essenciais para que um painel de administração possa gerenciar as configurações do sistema \"Deeper\".