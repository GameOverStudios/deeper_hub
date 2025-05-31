# Documentação Deeper: Endpoints da API para Localização (`sys_localization`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para acessar recursos de internacionalização e localização, como a lista de idiomas disponíveis e as strings traduzidas.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** Estes endpoints são geralmente públicos.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Listar Idiomas Disponíveis

*   **Endpoint:** `GET /localization/languages`
*   **Status:** Público
*   **Descrição:** Retorna uma lista de todos os idiomas configurados no sistema.
*   **Query Parameters:**
    *   `enabled=true|false`: (Opcional) Se `true`, retorna apenas idiomas ativos. Se `false` ou omitido, pode retornar todos ou apenas ativos dependendo da implementação padrão do `LocalizationRepo.list_languages/1`.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"en\",
          \"title\": \"English\",
          \"flag\": \"us\",
          \"direction\": \"LTR\",
          \"language_country\": \"en-US\",
          \"enabled\": true
        },
        {
          \"id\": 2,
          \"name\": \"pt-BR\",
          \"title\": \"Português (Brasil)\",
          \"flag\": \"br\",
          \"direction\": \"LTR\",
          \"language_country\": \"pt-BR\",
          \"enabled\": true
        }
        // ... outros idiomas
      ]
    }
```

```json
    {
      \"data\": {
        \"_sys_txt_greeting\": \"Hello\",
        \"_sys_btn_submit\": \"Submit\",
        \"_bx_persons_txt_profile_title\": \"Profile\",
        // ... todas as outras chaves e suas traduções
      },
      \"metadata\": {
        \"language_code\": \"en\",
        \"category_name\": null, // ou o nome da categoria se filtrado
        \"fallback_applied\": false // true se o fallback foi usado para algumas chaves
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"System\"
        },
        {
          \"id\": 15,
          \"name\": \"bx_persons\"
        }
        // ... outras categorias
      ]
    }
```

*   **Lógica do Backend:**
    1.  Chamar `LocalizationRepo.list_languages/1` passando o parâmetro `enabled` (convertido para booleano).
    2.  Formatar a lista de mapas retornada para a estrutura JSON de resposta.

### 2. Obter Strings de Tradução para um Idioma

*   **Endpoint:** `GET /localization/strings/{language_code}`
*   **Status:** Público
*   **Descrição:** Retorna um objeto JSON contendo todas as chaves de tradução e suas strings correspondentes para o idioma especificado.
*   **Parâmetros de URL:**
    *   `{language_code}`: O código do idioma (ex: `en`, `pt-BR`, correspondente a `sys_localization_languages.Name`).
*   **Query Parameters:**
    *   `category_name`: (Opcional) Nome da categoria de localização (de `sys_localization_categories.Name`) para buscar apenas strings dessa categoria. Se omitido, retorna todas as strings para o idioma.
    *   `fallback_to_default=true|false`: (Opcional, default `false` ou conforme configuração) Se `true` e uma chave não for encontrada para o `language_code` especificado, tenta buscar no idioma padrão do sistema.
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `404 Not Found`: Se o `{language_code}` não existir ou não estiver ativo. Se `category_name` for fornecido e não existir.
*   **Lógica do Backend:**
    1.  Obter `language_code` da URL e `category_name` (opcional) e `fallback_to_default` (opcional) dos query params.
    2.  Chamar `LocalizationRepo.get_strings_for_language/2` com `language_code` e `category_name`.
    3.  (Opcional) Se `fallback_to_default` for `true` e a função do Repo suportar/implementar fallback, a lógica de fallback é aplicada.
    4.  Formatar o mapa de chaves/strings para a estrutura JSON de resposta.

### 3. Listar Categorias de Localização

*   **Endpoint:** `GET /localization/categories`
*   **Status:** Público
*   **Descrição:** Retorna uma lista de todas as categorias de localização disponíveis (para permitir que o cliente solicite strings por categoria, se desejado).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Chamar `LocalizationRepo.list_categories/0`.
    2.  Formatar a lista de mapas para a estrutura JSON de resposta.

### Considerações de Caching:

*   **Extremamente Importante:** Todos estes endpoints, especialmente `GET /localization/strings/{language_code}`, devem ser agressivamente cacheados.
    *   **Cache do Lado do Servidor (Elixir):** Usar `Cachex` ou ETS para armazenar os resultados de `LocalizationRepo.list_languages/1` e `LocalizationRepo.get_strings_for_language/2`. O cache pode ser por `language_code` e `category_name`.
    *   **Cabeçalhos HTTP Cache-Control:** Instruir os clientes (navegadores, apps) a cachear as respostas por um longo período (ex: `Cache-Control: public, max-age=360000`). Usar `ETag`s também pode ajudar na validação do cache.
*   O cache deve ser invalidado quando houver alterações nos idiomas ou nas traduções (geralmente acionado por ações na API de Administração).