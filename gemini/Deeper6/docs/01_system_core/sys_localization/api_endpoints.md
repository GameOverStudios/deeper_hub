# Documentação Deeper: Endpoints da API Pública para Internacionalização e Localização

Este documento especifica os endpoints da API RESTful \"Deeper\" para leitura pública de dados de localização, permitindo que o cliente frontend renderize a interface no idioma apropriado. A modificação dos dados de localização (chaves, strings, idiomas) é feita através da API de Administração.

## Objetivos:

*   Permitir que o cliente obtenha a lista de idiomas ativos no sistema.
*   Permitir que o cliente obtenha todas as strings de tradução para um idioma específico e, opcionalmente, para uma categoria específica de chaves.

## Tabelas Relevantes (Já Definidas em `docs/01_system_core/sys_localization/`):

*   `sys_localization_languages`
*   `sys_localization_categories`
*   `sys_localization_keys`
*   `sys_localization_strings`

## Módulo de Acesso a Dados (Já Definido em `docs/01_system_core/sys_localization/data_access_module.md`):

*   `Deeper.SystemCore.LocalizationRepo` será utilizado.

## Endpoints da API Pública para Localização

### 1. Listar Idiomas Ativos

*   **Endpoint:** `GET /api/v1/localization/languages`
*   **Propósito:** Retorna uma lista de todos os idiomas ativos e disponíveis para os usuários.
*   **Autenticação:** Nenhuma (endpoint público).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1, // sys_localization_languages.ID
          \"name\": \"en\", // Código do idioma (ex: en, es, pt-BR)
          \"title\": \"English\",
          \"flag\": \"us\", // Código do país para o ícone da bandeira
          \"direction\": \"LTR\", // LTR ou RTL
          \"language_country\": \"en-US\"
        },
        {
          \"id\": 2,
          \"name\": \"pt-BR\",
          \"title\": \"Português (Brasil)\",
          \"flag\": \"br\",
          \"direction\": \"LTR\",
          \"language_country\": \"pt-BR\"
        }
        // ... mais idiomas ativos ...
      ]
    }
```

```json
    // Exemplo para GET /api/v1/localization/strings/en
    {
      \"data\": {
        \"_sys_menu_item_home\": \"Home\",
        \"_sys_menu_item_profile\": \"Profile\",
        \"_bx_persons_page_title_browse_people\": \"Browse People\",
        \"_bx_persons_form_input_fullname\": \"Full Name\",
        // ... todas as outras chaves e suas traduções para 'en' ...
        \"Hello {0}, welcome to {1}!\": \"Hello {0}, welcome to {1}!\" // Strings com placeholders
      }
    }
```

### 2. Obter Strings de Tradução para um Idioma

*   **Endpoint:** `GET /api/v1/localization/strings/{lang_code}`
*   **Propósito:** Retorna um objeto JSON contendo todas as chaves de tradução e suas strings correspondentes para o idioma especificado. Este é o endpoint principal para o cliente carregar as traduções.
*   **Autenticação:** Nenhuma (endpoint público).
*   **Parâmetros de URL:**
    *   `{lang_code}` (String, Obrigatório): O código do idioma (ex: `en`, `pt-BR`, correspondente a `sys_localization_languages.name`).
*   **Query Parameters:**
    *   `category_id` (Integer, Opcional): ID de uma `sys_localization_categories`. Se fornecido, retorna apenas strings dessa categoria.
    *   `module` (String, Opcional): Nome de um módulo UNA (ex: `bx_persons`). Se fornecido, tenta buscar strings associadas a categorias com esse nome de módulo (requer que `sys_localization_categories.Name` possa ser mapeado para módulos).
*   **Lógica do Backend:**
    1.  Validar `{lang_code}` e encontrar o `IDLanguage` correspondente em `sys_localization_languages`.
    2.  Se `category_id` ou `module` for fornecido, filtrar as `IDCategory` relevantes.
    3.  Chamar `Deeper.SystemCore.LocalizationRepo.get_strings_for_language(language_id, optional_category_filter)`.
    4.  O Repo buscará todas as `sys_localization_keys.Key` e suas `sys_localization_strings.String` correspondentes.
    5.  Formatar a resposta como um objeto JSON onde as chaves são as `Key` e os valores são as `String`.
*   **Resposta de Sucesso (200 OK):**

    *   **Formato:** Um objeto simples chave-valor é geralmente o mais fácil para bibliotecas de i18n do cliente consumirem (ex: `i18next`, `vue-i18n`).

*   **Respostas de Erro:**
    *   `404 Not Found`: Se o `{lang_code}` não corresponder a um idioma ativo ou se não houver strings para esse idioma/categoria.
    *   `500 Internal Server Error`.

### Considerações:

*   **Cache:** As respostas destes endpoints são candidatas ideais para cache agressivo (CDN, cache do navegador, cache do servidor), pois as traduções não mudam com extrema frequência. Quando um administrador atualiza traduções, os caches relevantes devem ser invalidados.
*   **Tamanho da Resposta:** Para sistemas com muitas chaves de tradução, a resposta de `/api/v1/localization/strings/{lang_code}` pode ser grande.
    *   **Divisão por Módulo/Categoria:** O parâmetro `category_id` ou `module` ajuda a mitigar isso, permitindo que o cliente carregue apenas as strings necessárias para a visualização atual ou para um módulo específico.
    *   **Lazy Loading de Módulos de Tradução:** O cliente pode carregar um conjunto base de traduções e depois carregar traduções específicas de módulos/seções conforme o usuário navega.
*   **Placeholders em Strings:** As strings de tradução podem conter placeholders (ex: `{0}`, `%{name}`). A API simplesmente retorna a string com os placeholders; a substituição é responsabilidade do cliente usando sua biblioteca de i18n.
*   **Formato de `{lang_code}`:** Usar códigos de idioma padrão (ISO 639-1 para idioma, opcionalmente com região ISO 3166-1 Alpha 2, ex: `en`, `en-US`, `pt-BR`).

Estes endpoints permitem que o cliente frontend se torne totalmente internacionalizado, buscando os idiomas disponíveis e as traduções necessárias da API \"Deeper\".