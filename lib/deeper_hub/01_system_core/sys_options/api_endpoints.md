# Documentação Deeper: Endpoints da API para Configurações do Sistema (`sys_options`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para ler as configurações do sistema. A modificação das opções é geralmente reservada para a API de Administração.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** A maioria dos endpoints de leitura de opções pode ser pública, mas alguns podem requerer autenticação dependendo da sensibilidade da opção. Isso será notado por endpoint.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Obter o Valor de uma Opção Específica

*   **Endpoint:** `GET /options/{option_name}`
*   **Status:** Público (geralmente)
*   **Descrição:** Retorna o valor efetivo de uma única opção do sistema. Considera o \"mix\" de tema ativo se aplicável.
*   **Parâmetros de URL:**
    *   `{option_name}`: O nome da opção (ex: `site_title`, `bx_persons_per_page_browse`).
*   **Query Parameters (Opcional):**
    *   `mix_type`: (Opcional, ex: `template`) Para especificar o tipo de mix a ser considerado. Se omitido, o backend pode tentar usar um tipo de mix padrão (como \"template\") ou nenhum mix.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"name\": \"site_title\",
        \"value\": \"Minha Comunidade Incrível\", // Valor convertido para o tipo apropriado
        \"type\": \"text\" // Tipo original da opção
      }
    }
```

```json
    {
      \"data\": {
        \"value\": \"Minha Comunidade Incrível\"
      }
    }
```

```json
    {
      \"data\": {
        \"category_name\": \"geral\",
        \"options\": {
          \"site_title\": \"Minha Comunidade\",
          \"site_email\": \"admin@example.com\",
          \"maintenance_mode\": false // Valores convertidos
          // ... outras opções da categoria
        }
      }
    }
```

```json
    {
      \"data\": {
        \"geral\": {
          \"site_title\": \"Minha Comunidade\",
          \"maintenance_mode\": false
        },
        \"bx_persons\": {
          \"per_page_browse\": 10,
          \"enable_feature_x\": true
        }
        // ... outras categorias e suas opções
      }
    }
```

```json
    {
      \"data\": {
        \"site_title\": \"Minha Comunidade\",
        \"maintenance_mode\": false,
        \"bx_persons_per_page_browse\": 10,
        \"bx_persons_enable_feature_x\": true
        // ... todas as opções
      }
    }
```

```json
    {
      \"data\": [
        {
          \"name\": \"geral\",
          \"caption\": \"Configurações Gerais\",
          \"type_name\": \"system\"
        },
        {
          \"name\": \"bx_persons\",
          \"caption\": \"Configurações do Módulo Pessoas\",
          \"type_name\": \"modules\"
        }
        // ...
      ]
    }
```

    Ou, mais simplesmente, apenas o valor:

    (A primeira opção é mais informativa).
*   **Erros Comuns:**
    *   `404 Not Found`: Opção `{option_name}` não encontrada.
*   **Lógica do Backend:**
    1.  Obter `option_name` da URL.
    2.  (Opcional) Obter `mix_type` dos query params.
    3.  Determinar o `active_mix_name` para o `mix_type` (ou default) usando `OptionsRepo.get_active_mix_name_for_type/1`.
    4.  Chamar `OptionsRepo.get_option_value/2` com `option_name` e o `active_mix_name` determinado.
    5.  Retornar o valor e o tipo.

### 2. Obter Todas as Opções de uma Categoria

*   **Endpoint:** `GET /options/category/{category_name}`
*   **Status:** Público (geralmente)
*   **Descrição:** Retorna todos os pares nome/valor das opções pertencentes a uma categoria específica.
*   **Parâmetros de URL:**
    *   `{category_name}`: O nome da categoria (de `sys_options_categories.name`, ex: ` promoção`, `geral`).
*   **Query Parameters (Opcional):**
    *   `mix_type`: (Opcional, ex: `template`) Para especificar o tipo de mix a ser considerado.
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `404 Not Found`: Categoria `{category_name}` não encontrada.
*   **Lógica do Backend:**
    1.  Obter `category_name` da URL.
    2.  (Opcional) Obter `mix_type`.
    3.  Determinar `active_mix_name`.
    4.  Chamar `OptionsRepo.get_options_by_category/2`.

### 3. Obter Todas as Opções do Sistema (Uso com Cautela)

*   **Endpoint:** `GET /options`
*   **Status:** Autenticado (Recomendado, pois pode expor muitas configurações) ou fortemente cacheado se público.
*   **Descrição:** Retorna todas as opções do sistema, potencialmente agrupadas por categoria.
*   **Query Parameters (Opcional):**
    *   `mix_type`: (Opcional, ex: `template`).
    *   `group_by_category=true|false` (default `true`): Se deve agrupar as opções por categoria na resposta.
*   **Resposta de Sucesso (200 OK) (agrupado):**

*   **Resposta de Sucesso (200 OK) (plano - se `group_by_category=false`):**

*   **Lógica do Backend:**
    1.  (Opcional) Obter `mix_type`.
    2.  Determinar `active_mix_name`.
    3.  Chamar `OptionsRepo.get_all_options/1`.
    4.  Formatar a resposta (agrupada ou plana).

### 4. (Opcional) Obter Categorias de Opções

*   **Endpoint:** `GET /options/categories`
*   **Status:** Público
*   **Descrição:** Lista as categorias de opções disponíveis.
*   **Query Parameters (Opcional):**
    *   `type_name`: Filtrar categorias por um tipo (de `sys_options_types.name`, ex: `system`, `modules`).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    *   Consultar `sys_options_categories` e, opcionalmente, fazer `JOIN` com `sys_options_types` para filtrar por `type_name` ou incluir `type_name` na resposta.
    *   Usaria funções do `OptionsRepo` para buscar essas informações.

### Considerações de Caching para Endpoints de Opções:

*   Dado que as opções mudam com pouca frequência, esses endpoints são candidatos primários para caching no lado do servidor (usando `Cachex`, ETS, ou um proxy reverso como Varnish/Nginx) e/ou para o cliente ser instruído a cachear as respostas (via cabeçalhos HTTP `Cache-Control`, `ETag`).
*   O cache precisaria ser invalidado quando as opções são alteradas (através da API de Administração).