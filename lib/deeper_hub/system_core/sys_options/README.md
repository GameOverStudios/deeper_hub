# Documentação Deeper: Configurações do Sistema (`sys_options`)

Este documento descreve como a API \"Deeper\" irá interagir com o sistema de configurações do UNA, primariamente armazenado nas tabelas `sys_options`, `sys_options_categories`, e `sys_options_types`.

**Foco Principal:**
*   Fornecer endpoints da API para que o cliente (e o próprio backend \"Deeper\") possam **ler** as configurações do sistema.
*   A API para **administração** (modificação) das configurações será detalhada na seção `07_studio_admin_api/system_settings_admin_api.md`.

## Responsabilidades Principais da API de Configurações:

*   Permitir a busca de valores de configuração por nome.
*   Permitir a listagem de configurações por categoria ou tipo.
*   Fornecer informações sobre os tipos e categorias de configuração.

## Componentes do Banco de Dados UNA para Configurações:

*   **`sys_options_types`**: Define os \"grupos\" principais de configurações (ex: \"Geral\", \"Avançado\", \"Templates\").
    *   Campos importantes: `id`, `group`, `name`, `caption`, `icon`, `order`.
*   **`sys_options_categories`**: Define categorias dentro de cada tipo (ex: dentro de \"Geral\", pode haver \"Site Info\", \"SEO\").
    *   Campos importantes: `id`, `type_id` (FK para `sys_options_types.id`), `name`, `caption`, `order`.
*   **`sys_options`**: A tabela principal com as configurações individuais.
    *   Campos importantes: `id`, `category_id` (FK para `sys_options_categories.id`), `name` (nome único da opção), `caption`, `info`, `value` (o valor da configuração), `type` (tipo de dado/controle: 'text', 'digit', 'checkbox', 'select', etc.), `extra` (para 'select', 'list', etc.), `check` (função de validação), `order`.
*   **`sys_options_mixes` e `sys_options_mixes2options`**: Relacionadas a \"temas\" ou \"presets\" de configurações. O escopo inicial da API de leitura pode não cobrir mixes profundamente, focando nas configurações ativas.

## Esquema do Banco de Dados (SQLite - Tabelas de Configurações)

As definições `CREATE TABLE` para `sys_options_types`, `sys_options_categories`, e `sys_options` serão detalhadas no arquivo `database_schema.md` dentro desta pasta.

## Módulos de Acesso a Dados (`data_access_modules.md`)

Descreverá o `Deeper.SystemCore.OptionsRepo` com funções para:
*   `get_option_value(option_name)`
*   `get_option_details(option_name)`
*   `list_options_by_category_name(category_name)`
*   `list_options_by_type_name(type_name)`
*   `list_option_categories(type_id_or_name)`
*   `list_option_types()`

## Endpoints da API

Detalhará os endpoints da API para buscar configurações, categorias e tipos.

## Considerações:

*   **Cache:** Valores de configuração são frequentemente acessados e raramente mudam. O backend \"Deeper\" deve implementar uma estratégia de cache (ex: usando um GenServer ou ETS) para armazenar configurações lidas do banco de dados, reduzindo a carga no DB. A API retornaria os valores cacheados. Uma mecanismo para invalidar o cache (ex: quando um admin muda uma configuração via API de admin) será necessário.
*   **Tipagem de Valores:** A coluna `sys_options.value` é `mediumtext`. A API precisará, idealmente, converter o valor para o tipo Elixir apropriado (inteiro, booleano, string) com base na coluna `sys_options.type` antes de retornar no JSON, para facilitar o consumo pelo cliente.
*   **Mixes de Opções:** A leitura inicial pode focar apenas nos valores \"base\" das opções. A lógica para aplicar \"mixes\" (temas) sobre as configurações base pode ser uma adição futura se necessário, pois adiciona complexidade.