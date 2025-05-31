# Documentação Deeper Studio API: Gerenciamento de Localização

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento completo do sistema de Internacionalização e Localização do UNA. Isso inclui o gerenciamento de Idiomas (`sys_localization_languages`), Categorias de Chaves (`sys_localization_categories`), Chaves de Tradução (`sys_localization_keys`), e as Strings Traduzidas (`sys_localization_strings`).

**Objetivo Principal:** Permitir que administradores adicionem novos idiomas, modifiquem idiomas existentes, gerenciem categorias de tradução, e adicionem/editem/deletem chaves de tradução e suas respectivas strings em cada idioma.

## Tabelas Relevantes (já definidas e migradas):

*   `sys_localization_languages`
*   `sys_localization_categories`
*   `sys_localization_keys`
*   `sys_localization_strings`

## Módulo de Acesso a Dados (`Deeper.SystemCore.LocalizationRepo`):

O `LocalizationRepo` (já parcialmente definido para leitura em `01_system_core/sys_localization/`) precisará ser estendido com funções CRUD completas para todas as quatro tabelas de localização.

**Funções Adicionais Chave no `LocalizationRepo`:**

*   CRUD para `sys_localization_languages`: `create_language`, `get_language_by_id_or_name`, `list_all_languages` (não apenas habilitados), `update_language`, `delete_language` (com cuidado para as strings associadas).
*   CRUD para `sys_localization_categories`: `create_category`, `get_category_by_id_or_name`, `list_categories`, `update_category`, `delete_category`.
*   CRUD para `sys_localization_keys`: `create_key`, `get_key_by_id_or_string`, `list_keys_by_category` (ou com filtros), `update_key`, `delete_key` (e suas strings).
*   CRUD para `sys_localization_strings`: `set_string_translation` (cria ou atualiza), `get_string_translation_details`, `delete_string_translation`.
*   Função para importar/exportar traduções (pode ser mais complexo).

## Endpoints da API de Administração para Localização (`/api/v1/admin/localization`):

---
### Gerenciamento de Idiomas (`/api/v1/admin/localization/languages`)

#### 1. Listar Todos os Idiomas (Habilitados e Desabilitados)

*   **Endpoint:** `GET /api/v1/admin/localization/languages`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name_code\": \"en\", // sys_localization_languages.Name
          \"title\": \"English\",
          \"flag_code\": \"gb\",
          \"direction\": \"LTR\",
          \"system_code\": \"en-GB\", // sys_localization_languages.LanguageCountry
          \"is_enabled\": true
        }
        // ... outros idiomas ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"category_id\": 5,
          \"category_name\": \"System\",
          \"key_string\": \"_sys_txt_welcome\"
        }
        // ... outras chaves ...
      ]
      // \"pagination\": { ... }
    }
```

```json
    {
      \"data\": [ // Exemplo para ?key_id=101
        {
          \"key_id\": 101,
          \"key_string\": \"_sys_txt_welcome\",
          \"language_id\": 1,
          \"language_code\": \"en\",
          \"translated_string\": \"Welcome\"
        },
        {
          \"key_id\": 101,
          \"key_string\": \"_sys_txt_welcome\",
          \"language_id\": 2,
          \"language_code\": \"pt-BR\",
          \"translated_string\": \"Bem-vindo\"
        }
      ]
    }
```

```json
    {
      \"key_id\": 101,
      \"language_id\": 1,
      \"translated_string\": \"Welcome to our Platform!\"
    }
```

#### 2. Criar Novo Idioma

*   **Endpoint:** `POST /api/v1/admin/localization/languages`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `name_code`, `title`, `flag_code`, `direction`, `system_code`, `is_enabled`.
*   **Resposta de Sucesso (201 Created):** Retorna o idioma criado.

#### 3. Obter Detalhes de um Idioma

*   **Endpoint:** `GET /api/v1/admin/localization/languages/{language_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK).**

#### 4. Atualizar um Idioma

*   **Endpoint:** `PUT /api/v1/admin/localization/languages/{language_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** Campos a serem atualizados (ex: `title`, `is_enabled`).
*   **Resposta de Sucesso (200 OK).**

#### 5. Deletar um Idioma

*   **Endpoint:** `DELETE /api/v1/admin/localization/languages/{language_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta de `sys_localization_languages`. `ON DELETE CASCADE` (se definido) ou uma deleção manual removeria as `sys_localization_strings` associadas.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Categorias de Tradução (`/api/v1/admin/localization/categories`)

#### 6. Listar Todas as Categorias

*   **Endpoint:** `GET /api/v1/admin/localization/categories`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta:** Lista de `sys_localization_categories` (`id`, `name`).

#### 7. Criar Nova Categoria

*   **Endpoint:** `POST /api/v1/admin/localization/categories`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"name\": \"MinhaNovaCategoria\"}`.
*   **Resposta de Sucesso (201 Created).**

#### 8. Atualizar uma Categoria

*   **Endpoint:** `PUT /api/v1/admin/localization/categories/{category_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"name\": \"CategoriaRenomeada\"}`.
*   **Resposta de Sucesso (200 OK).**

#### 9. Deletar uma Categoria

*   **Endpoint:** `DELETE /api/v1/admin/localization/categories/{category_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta de `sys_localization_categories`. `ON DELETE CASCADE` (se definido) ou uma deleção manual removeria `sys_localization_keys` e `sys_localization_strings` associadas.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Chaves de Tradução (`/api/v1/admin/localization/keys`)

#### 10. Listar Chaves de Tradução

*   **Endpoint:** `GET /api/v1/admin/localization/keys`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:** `filter_category_id`, `filter_key_string_like`.
*   **Resposta de Sucesso (200 OK):**

#### 11. Criar Nova Chave de Tradução

*   **Endpoint:** `POST /api/v1/admin/localization/keys`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"category_id\": 5, \"key_string\": \"_meu_modulo_txt_nova_label\"}`.
*   **Resposta de Sucesso (201 Created).**

#### 12. Atualizar uma Chave de Tradução (geralmente apenas `category_id`)

*   **Endpoint:** `PUT /api/v1/admin/localization/keys/{key_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):** `{\"category_id\": 6}`. (A `key_string` em si raramente é alterada após a criação).
*   **Resposta de Sucesso (200 OK).**

#### 13. Deletar uma Chave de Tradução

*   **Endpoint:** `DELETE /api/v1/admin/localization/keys/{key_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Lógica:** Deleta de `sys_localization_keys`. `ON DELETE CASCADE` (se definido) ou uma deleção manual removeria `sys_localization_strings` associadas.
*   **Resposta de Sucesso (204 No Content).**

---
### Gerenciamento de Strings Traduzidas (`/api/v1/admin/localization/strings`)

#### 14. Listar Traduções (para uma chave específica ou para um idioma)

*   **Endpoint:** `GET /api/v1/admin/localization/strings`
*   **Autenticação:** Requer JWT de Admin.
*   **Query Parameters:**
    *   `key_id` (opcional): Para listar todas as traduções de uma chave.
    *   `language_id` (opcional): Para listar todas as traduções de um idioma.
    *   `filter_string_like` (opcional).
*   **Resposta de Sucesso (200 OK):**

#### 15. Definir/Atualizar uma String Traduzida

*   **Endpoint:** `PUT /api/v1/admin/localization/strings`
*   **Autenticação:** Requer JWT de Admin.
*   **Corpo da Requisição (JSON):**

*   **Lógica do Backend:** Usa `LocalizationRepo.set_string_translation` que faz `INSERT OR REPLACE` ou `UPDATE` em `sys_localization_strings` (baseado na PK composta `IDKey, IDLanguage`).
*   **Resposta de Sucesso (200 OK):** Retorna a string traduzida atualizada/criada.
*   **Invalidação de Cache:** Esta ação DEVE invalidar o cache de traduções para o `language_id` afetado no `LocalizationRepo`.

#### 16. Deletar uma String Traduzida Específica

*   **Endpoint:** `DELETE /api/v1/admin/localization/strings/key/{key_id}/lang/{language_id}`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (204 No Content).**
*   **Invalidação de Cache:** Invalida o cache para o `language_id`.

## Considerações:

*   **Interface de Usuário:** Uma UI de administração para tradução geralmente permite selecionar um idioma e depois ver/editar todas as chaves (filtradas por categoria ou texto). A API deve suportar isso eficientemente.
*   **Importação/Exportação:** Funcionalidades para importar/exportar arquivos de tradução (ex: PO, JSON, CSV) seriam muito úteis para administradores e tradutores. Isso exigiria endpoints dedicados e lógica de parsing/formatação.
*   **Cache:** A modificação de qualquer string de tradução requer invalidação imediata do cache de strings para o idioma afetado no `LocalizationRepo` para que a API pública sirva as traduções atualizadas.

Esta API de gerenciamento de localização fornece controle total sobre o conteúdo multilíngue da plataforma \"Deeper\".