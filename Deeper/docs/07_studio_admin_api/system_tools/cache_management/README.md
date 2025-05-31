# Documentação Deeper Studio API: Gerenciamento de Cache

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento de caches internos da aplicação \"Deeper\".

**Objetivo Principal:** Permitir que administradores limpem caches específicos ou todos os caches do sistema para forçar o recarregamento de dados e configurações, o que é útil após alterações significativas.

## Tipos de Cache na API \"Deeper\" (Exemplos):

A API \"Deeper\" pode implementar vários tipos de cache para otimizar a performance:

1.  **Cache de Configurações (`sys_options`):** Valores de `sys_options` podem ser cacheados na memória pelo `OptionsRepo` ou um serviço.
2.  **Cache de Localização (`sys_localization_strings`):** Strings traduzidas por idioma podem ser cacheadas pelo `LocalizationRepo`.
3.  **Cache de Definições de ACL (`sys_acl_matrix`, etc.):** Regras de permissão podem ser cacheadas pelo `AclRepo` ou `AclService`.
4.  **Cache de Definições de Formulários/Grids/Menus/Páginas:** As estruturas desses componentes podem ser cacheadas.
5.  **Cache de Respostas de API (Opcional):** Algumas respostas de API `GET` podem ser cacheadas (ex: usando `Plug.CacheControl` ou um cache HTTP reverso como Varnish/Nginx, ou um cache de aplicação como Redis).
6.  **Cache de Templates (Se aplicável):** Se a API \"Deeper\" usar algum tipo de sistema de templating interno (menos comum para APIs JSON puras, mas possível para alguma lógica).
7.  **Cache de Banco de Dados (Nível de Query):** Algumas bibliotecas ou o próprio SGBD podem ter seus caches. Limpar isso geralmente está fora do controle direto da API, mas a API pode limpar caches de *resultados de query* que ela mantém.

## Mecanismo de Cache na \"Deeper\":

*   A implementação do cache pode usar Agentes Elixir, ETS, `Nebulex`, `Cachex`, ou `Redis` (se um storage externo for usado).
*   Cada `Repo` ou Serviço responsável por dados cacheados deve expor funções para invalidar/limpar seu cache específico.

## Endpoints da API de Admin para Gerenciamento de Cache (`/api/v1/admin/system/cache`):

### 1. Limpar Todos os Caches da Aplicação

*   **Endpoint:** `POST /api/v1/admin/system/cache/clear-all`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"message\": \"All application caches cleared successfully.\",
        \"cleared_caches\": [\"settings\", \"localization\", \"acl_matrix\", \"page_definitions\"] // Lista dos tipos de cache limpos
      }
    }
```

```json
    {
      \"data\": {
        \"message\": \"Cache '{cache_name}' cleared successfully.\",
        \"cache_name\": \"localization\",
        \"key_param_cleared\": \"en\" // Se um key_param foi usado
      }
    }
```

```json
    {
      \"data\": [
        {\"name\": \"settings\", \"description\": \"System configurations (sys_options)\"},
        {\"name\": \"localization\", \"description\": \"Language strings (sys_localization_strings)\", \"supports_key_param\": \"lang_code\"},
        {\"name\": \"acl_matrix\", \"description\": \"ACL permission matrix\"},
        {\"name\": \"page_definitions\", \"description\": \"Cached page structures\"}
      ]
    }
```

*   **Lógica do Backend:** Chama funções de limpeza em todos os módulos/serviços relevantes que mantêm caches (ex: `OptionsRepo.clear_cache()`, `LocalizationRepo.clear_all_language_caches()`, etc.).

### 2. Limpar Cache Específico

*   **Endpoint:** `POST /api/v1/admin/system/cache/clear/{cache_name}`
*   **Path Parameter:** `cache_name` (um identificador para o tipo de cache, ex: `settings`, `localization`, `acl`, `pages`).
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters (Opcionais):**
    *   `key_param` (ex: `lang_code` para `localization`, `object_name` para `pages`): Para limpar uma entrada específica do cache em vez do cache inteiro.
*   **Corpo da Requisição:** Vazio.
*   **Resposta de Sucesso (200 OK):**

*   **Respostas de Erro:** `400 Bad Request` (se `cache_name` for inválido).
*   **Lógica do Backend:**
    *   Usa um `case` ou dispatch para chamar a função de limpeza apropriada com base em `cache_name`.
    *   Ex: Se `cache_name == \"localization\"` e `key_param` (como `lang_code`) for fornecido, chama `LocalizationRepo.clear_cache_for_language(lang_code)`. Se `key_param` não for fornecido, chama `LocalizationRepo.clear_all_language_caches()`.

### 3. (Opcional) Listar Tipos de Cache Gerenciáveis

*   **Endpoint:** `GET /api/v1/admin/system/cache/types`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):**

    *   Isso ajuda a UI de admin a saber quais caches podem ser limpos.

## Considerações:

*   **Impacto da Limpeza de Cache:** Limpar caches pode causar uma carga temporariamente maior no sistema (DB, processamento) enquanto os caches são repovoados.
*   **Granularidade:** Permitir a limpeza de entradas de cache específicas (quando aplicável, como por `lang_code` para localização) é melhor do que sempre limpar o cache inteiro.
*   **Caches Externos:** Se caches externos como Redis ou Memcached forem usados, a API precisará de lógica para se conectar e enviar comandos de limpeza a eles.
*   **Cache de CDN/Browser:** Esta API geralmente não controla caches de CDN ou de browser do cliente diretamente, mas limpar caches do lado do servidor pode ajudar a propagar alterações mais rapidamente.

Esta API de gerenciamento de cache é uma ferramenta importante para administradores garantirem que as alterações de configuração ou dados sejam refletidas corretamente.