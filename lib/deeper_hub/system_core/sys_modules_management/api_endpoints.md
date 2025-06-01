# Documentação Deeper: Endpoints da API para Gerenciamento de Módulos (Leitura)

Este documento especifica os endpoints RESTful da API \"Deeper\" para ler informações sobre os módulos do sistema UNA. A modificação do status dos módulos (habilitar/desabilitar) será abordada na API de Administração.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** Estes endpoints podem ser públicos ou requerer autenticação de administrador, dependendo da política de exposição de informações do sistema. Para um cliente genérico, podem ser públicos. Para uso interno ou para um cliente de administração, podem ser protegidos. Assumiremos inicialmente como públicos para leitura.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Listar Todos os Módulos

*   **Endpoint:** `GET /modules`
*   **Status:** Público (inicialmente)
*   **Descrição:** Retorna uma lista de todos os módulos registrados no sistema.
*   **Query Parameters:**
    *   `enabled=true|false`: (Opcional) Filtra módulos pelo status de habilitação.
    *   `type=<module_type>`: (Opcional) Filtra módulos pelo campo `type` (ex: `module`, `language`, `template`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"bx_persons\",
          \"title\": \"Persons\",
          \"vendor\": \"UNA\",
          \"version\": \"13.0.5\",
          \"uri\": \"persons\",
          \"enabled\": true, // Convertido para booleano
          \"type\": \"module\",
          \"dependencies\": [\"bx_timeline\", \"bx_notifications\"] // Parseado para lista
        },
        {
          \"id\": 2,
          \"name\": \"bx_timeline\",
          \"title\": \"Timeline\",
          \"vendor\": \"UNA\",
          \"version\": \"13.0.2\",
          \"uri\": \"timeline\",
          \"enabled\": true,
          \"type\": \"module\",
          \"dependencies\": []
        }
        // ... outros módulos
      ],
      \"pagination\": { // Se a paginação for implementada para esta lista
        \"total_items\": 50,
        \"total_pages\": 3,
        \"current_page\": 1,
        \"per_page\": 20
      }
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"type\": \"module\",
        \"subtypes\": 0, // ou interpretado
        \"name\": \"bx_persons\",
        \"title\": \"Persons\",
        \"vendor\": \"UNA\",
        \"version\": \"13.0.5\",
        \"help_url\": \"http://una.io/page/view-module?name=bx_persons\",
        \"path\": \"boonex/persons/\",
        \"uri\": \"persons\",
        \"class_prefix\": \"BxPersons\",
        \"db_prefix\": \"bx_persons_\",
        \"lang_category\": \"Persons\",
        \"dependencies\": [\"bx_timeline\", \"bx_notifications\"], // Parseado
        \"date\": 1678886400, // Unix timestamp ou ISO 8601
        \"enabled\": true,
        \"pending_uninstall\": false,
        \"hash\": \"abcdef1234567890\",
        \"updated\": 1678886500 // Unix timestamp ou ISO 8601
      }
    }
```

*   **Lógica do Backend:**
    1.  Coletar `filter_opts` dos query parameters.
    2.  Chamar `ModulesRepo.list_modules/1` com `filter_opts`.
    3.  Formatar a lista de mapas retornada:
        *   Converter `enabled` e `pending_uninstall` para booleanos.
        *   Parsear `dependencies` de string para lista de strings.
        *   Converter `date` e `updated` para formato ISO 8601 string ou manter como timestamp Unix.
    4.  Adicionar informações de paginação se aplicável.

### 2. Obter Detalhes de um Módulo Específico pelo Nome

*   **Endpoint:** `GET /modules/{module_name}`
*   **Status:** Público (inicialmente)
*   **Descrição:** Retorna informações detalhadas de um módulo específico.
*   **Parâmetros de URL:**
    *   `{module_name}`: O nome único do módulo (ex: `bx_persons`).
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `404 Not Found`: Módulo `{module_name}` não encontrado.
*   **Lógica do Backend:**
    1.  Obter `module_name` da URL.
    2.  Chamar `ModulesRepo.get_module_by_name/1`.
    3.  Formatar o mapa retornado (conversões de tipo, parse de dependências).

### 3. Obter Detalhes de um Módulo Específico pelo URI

*   **Endpoint:** `GET /modules/uri/{module_uri}`
*   **Status:** Público (inicialmente)
*   **Descrição:** Retorna informações detalhadas de um módulo específico pelo seu URI. Útil quando o URI é conhecido, mas não o nome interno.
*   **Parâmetros de URL:**
    *   `{module_uri}`: O URI do módulo (ex: `persons`).
*   **Resposta de Sucesso (200 OK):** Similar à resposta de `GET /modules/{module_name}`.
*   **Erros Comuns:**
    *   `404 Not Found`: Módulo com o URI `{module_uri}` não encontrado.
*   **Lógica do Backend:**
    1.  Obter `module_uri` da URL.
    2.  Chamar `ModulesRepo.get_module_by_uri/1`.
    3.  Formatar o mapa retornado.

### Considerações:

*   **Paginação para `GET /modules`:** Se o número de módulos for grande, a paginação deve ser considerada para o endpoint de listagem.
*   **Sensibilidade da Informação:** Expor todos os detalhes dos módulos (como `path`, `hash`) publicamente pode ter implicações de segurança. Deve-se avaliar quais campos são seguros para retornar em um contexto público e quais devem ser restritos a endpoints de administração. Para uma API cliente genérica, talvez apenas `name`, `title`, `uri`, `version`, e `enabled` sejam suficientes.
*   **Caching:** A lista de módulos e seus detalhes mudam apenas quando módulos são instalados/desinstalados/atualizados/habilitados/desabilitados. Portanto, os resultados desses endpoints são bons candidatos para caching.