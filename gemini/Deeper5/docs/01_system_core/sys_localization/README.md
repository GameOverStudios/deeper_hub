# Documentação Deeper: Internacionalização e Localização (`sys_localization`)

Este documento descreve como a API \"Deeper\" irá interagir com o sistema de internacionalização (i18n) e localização (L10n) do UNA, que é primariamente gerenciado pelas tabelas `sys_localization_languages`, `sys_localization_keys`, `sys_localization_strings`, e `sys_localization_categories`.

**Foco Principal:**
*   Fornecer endpoints da API para que o cliente possa **obter strings traduzidas** para um idioma específico.
*   Permitir a listagem dos idiomas disponíveis no sistema.
*   A API para **administração** (adicionar/editar idiomas, chaves, traduções) será detalhada na seção `07_studio_admin_api/localization_admin_api.md` (a ser criada).

## Responsabilidades Principais da API de Localização:

*   Retornar um conjunto de strings traduzidas para um determinado idioma e, opcionalmente, para uma categoria ou módulo específico.
*   Listar os idiomas habilitados no sistema.

## Componentes do Banco de Dados UNA para Localização:

*   **`sys_localization_languages`**: Define os idiomas disponíveis no sistema.
    *   Campos importantes: `ID`, `Name` (código do idioma, ex: \"en\", \"pt-BR\"), `Title` (nome do idioma, ex: \"English\", \"Português (Brasil)\"), `Flag` (código do país para ícone de bandeira), `Direction` ('LTR' ou 'RTL'), `Enabled`.
*   **`sys_localization_categories`**: Categoriza as chaves de tradução (ex: \"Geral\", \"Módulo Pessoas\").
    *   Campos importantes: `ID`, `Name`.
*   **`sys_localization_keys`**: Armazena as chaves de tradução únicas (agnósticas de idioma).
    *   Campos importantes: `ID`, `IDCategory` (FK para `sys_localization_categories.id`), `Key` (a string da chave, ex: `_sys_txt_hello_world`).
*   **`sys_localization_strings`**: Armazena as traduções efetivas para cada chave em cada idioma.
    *   Campos importantes: `IDKey` (FK para `sys_localization_keys.ID`), `IDLanguage` (FK para `sys_localization_languages.ID`), `String` (o texto traduzido).

## Esquema do Banco de Dados (SQLite - Tabelas de Localização)

As definições `CREATE TABLE` para `sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, e `sys_localization_strings` serão detalhadas no arquivo `database_schema.md` dentro desta pasta.

## Módulos de Acesso a Dados (`data_access_modules.md`)

Descreverá o `Deeper.SystemCore.LocalizationRepo` com funções para:
*   `get_language_by_code(lang_code)`
*   `list_enabled_languages()`
*   `get_strings_for_language(lang_id_or_code, category_id_or_name, module_name)`
*   `get_string(key_string, lang_id_or_code)`

## Endpoints da API

Detalhará os endpoints da API para buscar pacotes de tradução e listar idiomas.

## Considerações:

*   **Cache:** Strings de tradução são candidatas ideais para cache, pois são frequentemente acessadas e mudam com pouca frequência. O backend \"Deeper\" deve cachear pacotes de tradução por idioma (e, opcionalmente, por categoria/módulo) para evitar consultas repetidas ao banco de dados.
*   **Formato de Retorno:** A API pode retornar as strings traduzidas como um objeto JSON onde as chaves são as `sys_localization_keys.Key` e os valores são as `sys_localization_strings.String`.

```json
    // Exemplo de resposta para GET /api/v1/localization/strings/en
    {
      \"_sys_txt_hello_world\": \"Hello World!\",
      \"_bx_persons_txt_profile\": \"Profile\",
      // ...
    }
```

*   **Idioma Padrão/Fallback:** A API pode precisar de uma lógica para retornar strings do idioma padrão do sistema se uma tradução específica não estiver disponível para o idioma solicitado.
*   **Carregamento Parcial vs. Completo:** A API pode oferecer opções para carregar todas as strings de um idioma ou apenas as strings de um módulo/categoria específica para otimizar o tamanho da resposta.