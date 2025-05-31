# Documentação Deeper: Endpoints da API para Sistema de Denúncias Genérico

Este documento especifica os endpoints RESTful da API \"Deeper\" para interagir com o sistema de denúncias genérico. Estes endpoints permitem que usuários submetam denúncias e (para administradores) gerenciem essas denúncias.

## Convenções Gerais:

*   **Base URL:** `/api/v1/reports`
*   **Identificadores:**
    *   `{object_report_name}`: O nome do \"objeto de denúncia\" (de `sys_objects_report.Name`, ex: `bx_persons_reports`, `bx_posts_reports`). Identifica qual sistema de denúncias está sendo usado.
    *   `{item_id}`: O ID do item de conteúdo principal que está sendo denunciado.
    *   `{report_id}`: O ID da denúncia específica (de `table_track.id`).
*   **Autenticação:** A submissão de denúncias (POST) é protegida. A listagem e gerenciamento de denúncias (GET, PUT para status) são para administradores.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Submeter uma Nova Denúncia

*   **Endpoint:** `POST /reports/object/{object_report_name}/item/{item_id}`
*   **Status:** Protegido
*   **Descrição:** Permite que um usuário autenticado submeta uma denúncia para um item de conteúdo específico.
*   **Parâmetros de URL:**
    *   `{object_report_name}`: Nome do objeto de denúncia.
    *   `{item_id}`: ID do item de conteúdo.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"type\": \"spam\", // Tipo da denúncia (ex: 'spam', 'abusive_content', 'copyright')
      \"text\": \"Este conteúdo é claramente spam e não relacionado.\" // Detalhes/justificativa
    }
```

```json
    {
      \"data\": {
        \"report_id\": 567, // ID da denúncia registrada na table_track
        \"item_id\": \"{item_id}\",
        \"object_report_name\": \"{object_report_name}\",
        \"status\": \"submitted\", // ou 0 (pendente)
        \"message\": \"Denúncia submetida com sucesso.\"
      }
    }
```

```json
    {
      \"data\": [
        {
          \"report_id\": 567,
          \"object_report_name\": \"bx_posts_reports\",
          \"item_id\": 789,
          \"item_title\": \"Título do Post Denunciado\", // Obtido via JOIN ou chamada subsequente
          \"reporter_profile_id\": 123,
          \"reporter_fullname\": \"Usuário Denunciante\",
          \"report_type\": \"spam\",
          \"report_text\": \"Conteúdo de spam.\",
          \"report_date_timestamp\": 1680000000,
          \"status\": 0, // Pendente
          \"checked_by_admin_id\": null,
          \"checked_by_admin_fullname\": null
        }
        // ... outras denúncias
      ],
      \"pagination\": { ... }
    }
```

```json
    {
      \"status\": 1 // Novo status (ex: 0=pendente, 1=aceita/ação tomada, 2=rejeitada/ignorada)
      // \"admin_notes\": \"Usuário advertido.\" (Opcional, se houver campo para notas do admin)
    }
```

*   **Resposta de Sucesso (201 Created ou 200 OK):**

*   **Erros Comuns:**
    *   `400 Bad Request`: `type` ou `text` faltando ou inválido.
    *   `401 Unauthorized`: Usuário não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para denunciar (raro) ou já denunciou recentemente.
    *   `404 Not Found`: Objeto de denúncia ou item não encontrado.
    *   `409 Conflict`: Se o usuário já denunciou este item com o mesmo tipo (dependendo da política).
*   **Lógica do Backend (Controller):**
    1.  Extrair `author_profile_id` e `author_nip_integer` do JWT e da requisição.
    2.  Validar dados do corpo da requisição.
    3.  Chamar `ReportingRepo.add_report/5` com os dados.
    4.  Formatar e retornar a resposta.

### 2. Listar Denúncias (Admin)

*   **Endpoint:** `GET /reports/admin/list`
*   **Status:** Protegido (Admin)
*   **Descrição:** Retorna uma lista paginada de todas as denúncias no sistema, com filtros.
*   **Query Parameters:**
    *   `object_report_name=<name>`: (Opcional) Filtrar por um sistema de denúncia específico.
    *   `item_id=<id>`: (Opcional) Filtrar denúncias para um item específico.
    *   `status=0|1|2`: (Opcional) Filtrar por status da denúncia (0=pendente, 1=aceita, 2=rejeitada).
    *   `reporter_id=<profile_id>`: (Opcional) Filtrar por quem fez a denúncia.
    *   `page=1`, `per_page=20`
    *   `sort_by=date_desc|date_asc`
*   **Resposta de Sucesso (200 OK):**

*   **Lógica do Backend (Controller):**
    1.  Verificar permissões de admin.
    2.  Coletar filtros dos query parameters.
    3.  Chamar `ReportingRepo.list_reports/2`.
    4.  Formatar a resposta.

### 3. Obter Detalhes de uma Denúncia Específica (Admin)

*   **Endpoint:** `GET /reports/admin/report/{report_track_id}`
    *   Nota: O `{report_track_id}` é o ID da entrada na `table_track` específica do objeto de denúncia. Pode ser necessário também o `{object_report_name}` se o ID não for globalmente único entre todas as tabelas de track. Para simplificar, assumiremos que o `report_track_id` é único ou que o contexto do objeto é conhecido. Uma abordagem melhor pode ser `GET /reports/admin/object/{object_report_name}/track/{report_track_id}`.
*   **Endpoint (Alternativa mais robusta):** `GET /reports/admin/object/{object_report_name}/track/{report_track_id}`
*   **Status:** Protegido (Admin)
*   **Descrição:** Retorna detalhes completos de uma denúncia específica.
*   **Resposta de Sucesso (200 OK):** Similar a um item da lista de `GET /reports/admin/list`.
*   **Lógica do Backend:**
    1.  Verificar permissões de admin.
    2.  Chamar uma função no `ReportingRepo` como `get_report_details(object_report_name, report_track_id)`.

### 4. Atualizar Status de uma Denúncia (Admin)

*   **Endpoint:** `PUT /reports/admin/object/{object_report_name}/track/{report_track_id}/status`
*   **Status:** Protegido (Admin)
*   **Descrição:** Permite que um administrador atualize o status de uma denúncia.
*   **Parâmetros de URL:**
    *   `{object_report_name}`: Nome do objeto de denúncia.
    *   `{report_track_id}`: ID da denúncia na tabela de track.
*   **Corpo da Requisição (JSON):**

*   **Resposta de Sucesso (200 OK):** Retorna a denúncia atualizada.
*   **Erros Comuns:**
    *   `400 Bad Request`: Status inválido.
    *   `404 Not Found`: Denúncia não encontrada.
*   **Lógica do Backend (Controller):**
    1.  Verificar permissões de admin.
    2.  Extrair `admin_profile_id` do JWT.
    3.  Chamar `ReportingRepo.update_report_status/4` com `object_report_name`, `report_track_id`, `new_status`, `admin_profile_id`.

### Considerações:

*   **Tipos de Denúncia:** A API pode precisar de um endpoint para listar os tipos de denúncia disponíveis para um `{object_report_name}` se eles forem configuráveis e não um conjunto fixo.
*   **Notificações:** A submissão de uma denúncia deve idealmente acionar uma notificação para os moderadores/administradores.
*   **Contadores:** O `ReportingRepo` é responsável por atualizar os contadores de denúncias na `table_main` do objeto e na `TriggerTable` do conteúdo principal.