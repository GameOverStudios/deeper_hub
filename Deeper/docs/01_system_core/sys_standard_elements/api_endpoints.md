# Documentação Deeper: Endpoints da API para Elementos Padrão (`sys_std_*`)

Este documento especifica os endpoints RESTful da API \"Deeper\" para ler informações sobre os elementos padrão do sistema UNA, como páginas padrão do Studio, widgets e papéis. A modificação desses elementos é geralmente reservada para a API de Administração.

## Convenções Gerais:

*   **Base URL:** `/api/v1/standard-elements` (ou `/api/v1/std` para abreviar)
*   **Autenticação:** A maioria destes endpoints pode ser pública se os dados não forem sensíveis, ou podem requerer autenticação de administrador, especialmente se forem usados para construir uma UI de admin. Assumiremos como públicos para leitura, com notas sobre proteção se necessário.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints para Páginas Padrão (`sys_std_pages`, `sys_std_pages_widgets`)

### 1. Listar Todas as Páginas Padrão

*   **Endpoint:** `GET /standard-elements/pages`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna uma lista de todas as páginas padrão definidas em `sys_std_pages`.
*   **Query Parameters:**
    *   `sort_by=index|name`: (Opcional) Campo para ordenação.
    *   `order=asc|desc`: (Opcional) Direção da ordenação.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"index\": 0,
          \"name\": \"dashboard\",
          \"header\": \"Dashboard Principal\",
          \"caption\": \"Visão geral do sistema\",
          \"icon\": \"bx-home\"
        }
        // ... outras páginas padrão
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"index\": 0,
        \"name\": \"dashboard\",
        \"header\": \"Dashboard Principal\",
        \"caption\": \"Visão geral do sistema\",
        \"icon\": \"bx-home\",
        \"widgets\": [
          {
            \"widget_id\": 10,
            \"module\": \"bx_accounts\",
            \"type\": \"service\",
            \"caption\": \"Login Form\",
            \"icon\": \"bx-log-in\",
            \"order\": 1,
            \"featured\": false
            // ... outros campos do widget
          }
          // ... outros widgets da página
        ]
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 10,
          \"page_id_context\": \"dashboard\", // sys_std_widgets.page_id
          \"module\": \"bx_accounts\",
          \"type\": \"service\",
          \"caption\": \"Login Form\",
          \"icon\": \"bx-log-in\",
          \"featured\": false
        }
        // ... outros widgets
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 10,
        \"page_id_context\": \"dashboard\",
        \"module\": \"bx_accounts\",
        \"type\": \"service\",
        \"url\": null,
        \"click\": \"{'object': 'bx_accounts', 'method': 'get_login_form'}\", // Exemplo de como pode ser
        \"icon\": \"bx-log-in\",
        \"caption\": \"Login Form\",
        \"cnt_notices\": null,
        \"cnt_actions\": null,
        \"featured\": false
      }
    }
```

```json
    {
      \"bookmarked\": true // ou false
    }
```

```json
    {
      \"data\": {
        \"widget_id\": 10,
        \"profile_id\": 123, // profile_id do usuário logado
        \"bookmarked\": true
      }
    }
```

```json
    {
      \"data\": [
        {
          \"widget_id\": 10,
          \"widget_caption\": \"Login Form\",
          \"widget_icon\": \"bx-log-in\",
          \"bookmarked\": true
        }
        // ...
      ]
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 1,
          \"name\": \"admin\",
          \"title\": \"Administrator\",
          \"description\": \"Full access to the system.\",
          \"active\": true,
          \"order\": 1
        }
        // ...
      ]
    }
```

```json
    {
      \"data\": {
        \"id\": 1,
        \"name\": \"admin\",
        \"title\": \"Administrator\",
        \"description\": \"Full access to the system.\",
        \"active\": true,
        \"order\": 1,
        \"actions\": [
          {
            \"action_id\": 101,
            \"action_name\": \"manage_settings\",
            \"action_title\": \"Manage System Settings\"
          }
          // ...
        ]
      }
    }
```

```json
    {
      \"data\": [
        {
          \"id\": 101,
          \"name\": \"manage_settings\",
          \"title\": \"Manage System Settings\",
          \"description\": \"Allows changing global configurations.\"
        }
        // ...
      ]
    }
```

```json
    {
      \"data\": { // Dados do papel, ex:
        \"id\": 1,
        \"name\": \"admin\",
        \"title\": \"Administrator\"
        // ...
      }
    }
```

*   **Lógica do Backend:** Chama `StdElementsRepo.list_std_pages/1`.

### 2. Obter Detalhes de uma Página Padrão

*   **Endpoint:** `GET /standard-elements/pages/{page_name}`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna detalhes de uma página padrão específica e os widgets associados a ela.
*   **Parâmetros de URL:**
    *   `{page_name}`: O nome da página padrão (de `sys_std_pages.name`).
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `404 Not Found`: Página `{page_name}` não encontrada.
*   **Lógica do Backend:**
    1.  Chama `StdElementsRepo.get_std_page_by_name/1`.
    2.  Se encontrada, chama `StdElementsRepo.get_widgets_for_std_page/1` usando o ID da página.
    3.  Combina os resultados.

## Endpoints para Widgets Padrão (`sys_std_widgets`, `sys_std_widgets_bookmarks`)

### 3. Listar Todos os Widgets Padrão

*   **Endpoint:** `GET /standard-elements/widgets`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna uma lista de todos os widgets padrão.
*   **Query Parameters:**
    *   `page_context=<page_name>`: (Opcional) Filtra widgets que pertencem a um `page_id` (nome da página) específico em `sys_std_widgets.page_id`.
    *   `module=<module_name>`: (Opcional) Filtra widgets por módulo.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Chama `StdElementsRepo.list_std_widgets/1`.

### 4. Obter Detalhes de um Widget Padrão

*   **Endpoint:** `GET /standard-elements/widgets/{widget_id}`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna detalhes de um widget padrão específico.
*   **Parâmetros de URL:**
    *   `{widget_id}`: O ID do widget.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Chama `StdElementsRepo.get_std_widget/1`.

### 5. Gerenciar Bookmark de Widget para Usuário Logado

*   **Endpoint:** `PUT /standard-elements/widgets/{widget_id}/bookmark`
*   **Status:** Protegido (requer usuário autenticado para ter `profile_id`)
*   **Descrição:** Define ou remove um bookmark para um widget para o perfil do usuário logado.
*   **Parâmetros de URL:**
    *   `{widget_id}`: O ID do widget.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK ou 204 No Content):**

*   **Lógica do Backend:**
    1.  Extrair `profile_id` do JWT do usuário logado.
    2.  Chamar `StdElementsRepo.set_widget_bookmark/3`.

### 6. Listar Bookmarks de Widget para Usuário Logado

*   **Endpoint:** `GET /standard-elements/widgets/bookmarks/me`
*   **Status:** Protegido
*   **Descrição:** Lista todos os widgets favoritados pelo perfil do usuário logado.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Extrair `profile_id` do JWT.
    2.  Chamar `StdElementsRepo.get_widget_bookmarks_for_profile/1`.


## Endpoints para Papéis Padrão (`sys_std_roles`, etc.)

### 7. Listar Todos os Papéis Padrão

*   **Endpoint:** `GET /standard-elements/roles`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna uma lista de todos os papéis padrão.
*   **Query Parameters:**
    *   `active=true|false`: (Opcional) Filtrar por status ativo.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Chama `StdElementsRepo.list_std_roles/1`.

### 8. Obter Detalhes de um Papel Padrão (incluindo Ações)

*   **Endpoint:** `GET /standard-elements/roles/{role_name_or_id}`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna detalhes de um papel padrão específico e as ações associadas.
*   **Parâmetros de URL:**
    *   `{role_name_or_id}`: O nome ou ID do papel.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:**
    1.  Buscar o papel por nome ou ID usando `StdElementsRepo`.
    2.  Se encontrado, chamar `StdElementsRepo.get_actions_for_std_role/1`.
    3.  Combinar os resultados.

### 9. Listar Todas as Ações de Papéis Padrão

*   **Endpoint:** `GET /standard-elements/roles-actions`
*   **Status:** Público (ou Admin)
*   **Descrição:** Retorna uma lista de todas as ações de papéis padrão disponíveis.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend:** Chama `StdElementsRepo.list_std_roles_actions/0`.

### 10. Obter Papel Padrão de uma Conta de Usuário

*   **Endpoint:** `GET /accounts/{account_id}/standard-role`
*   **Status:** Admin (ou protegido, pois expõe o papel de um usuário)
*   **Descrição:** Retorna o papel padrão atribuído a uma conta de usuário específica.
*   **Parâmetros de URL:**
    *   `{account_id}`: O ID da conta do usuário.
*   **Resposta de Sucesso (200 OK):**

*   **Erros Comuns:**
    *   `404 Not Found`: Se a conta não tiver um papel padrão atribuído ou a conta/papel não existir.
*   **Lógica do Backend:** Chama `StdElementsRepo.get_std_role_for_account/1`.

### Considerações:

*   **Sensibilidade dos Dados:** Avaliar cuidadosamente quais desses endpoints devem ser públicos versus protegidos (ex: admin-only). Informações sobre a estrutura interna do Studio ou papéis de usuário podem não precisar ser universalmente acessíveis.
*   **Uso no Cliente:** Um cliente de frontend que não seja uma réplica do Studio pode ter uso limitado para alguns desses endpoints. Eles são mais relevantes para ferramentas de administração ou para introspecção do sistema.