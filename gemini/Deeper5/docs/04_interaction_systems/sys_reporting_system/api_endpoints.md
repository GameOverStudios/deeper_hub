# Documentação Deeper: Endpoints da API para o Sistema de Denúncias

Este documento especifica os endpoints RESTful para interagir com o sistema genérico de \"Denúncias\" no \"Deeper\". Estes endpoints são principalmente para usuários registrarem denúncias. Endpoints para administração de denúncias (listar, mudar status) estariam em `07_studio_admin_api/reports_admin_api.md` (a ser criado).

**Convenções Gerais:**
*   Endpoints sob `/api/v1`.
*   Respostas e corpos de requisição em JSON.
*   Autenticação JWT obrigatória para registrar denúncias.
*   Códigos de status HTTP e formatos de erro seguem as [Convenções de Design da API](../../00_core_concepts/api_design_conventions.md).
*   ACL será aplicado (geralmente, qualquer usuário logado pode denunciar, mas não pode denunciar seu próprio conteúdo).

**Parâmetros de Path Genéricos:**

*   `{resource_type}`: Identifica o tipo de recurso principal (ex: `articles`, `persons`, `comments`). Este será usado para determinar o `system_name` do sistema de denúncias.
*   `{resource_id}`: O ID do recurso principal específico que está sendo denunciado.

---

## 1. Denunciar um Recurso (`/{resource_type}/{resource_id}/report`)

### 1.1. Registrar uma Nova Denúncia para um Recurso

*   **Endpoint:** `POST /{resource_type}/{resource_id}/report`
*   **Autenticação:** Requerida (JWT).
*   **Descrição:** Permite que um usuário autenticado registre uma nova denúncia para um recurso específico.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"report_type_key\": \"spam\", // Chave do tipo de denúncia (ex: 'spam', 'harassment', 'inappropriate_content')
      \"comment\": \"Este conteúdo parece ser spam e contém links suspeitos.\" // Opcional
    }
```

```json
    {
      \"data\": {
        \"id\": 567, // ID da denúncia em deeper_reports_track
        \"system_name\": \"deeper_articles_reports\", // Exemplo
        \"object_id\": \"{resource_id}\",
        \"reporter_profile_id\": 15, // ID do perfil do denunciante
        \"report_type_key\": \"spam\",
        \"comment\": \"Este conteúdo parece ser spam e contém links suspeitos.\",
        \"status\": \"new\",
        \"reported_at\": 1678892000,
        \"message\": \"Denúncia recebida com sucesso. Obrigado.\" // Mensagem amigável
      }
    }
```

```json
    {
      \"data\": {
        \"object_id\": \"{resource_id}\",
        \"report_type_key\": \"spam\",
        \"has_reported_for_type\": true, // ou false
        \"report_details\": { // Presente e preenchido se has_reported_for_type for true
          \"id\": 567,
          \"status\": \"new\",
          \"reported_at\": 1678892000,
          \"comment\": \"Comentário original da denúncia.\"
        } // ou null
      }
    }
```

```json
    {
      \"data\": [
        {
          \"type_key\": \"spam\",
          \"title\": \"Spam ou Enganoso\", // Traduzido ou valor de title_lkey
          \"description\": \"Conteúdo comercial não solicitado, golpes, ou informações falsas.\" // Opcional
        },
        {
          \"type_key\": \"harassment\",
          \"title\": \"Assédio ou Discurso de Ódio\",
          \"description\": \"Ataques direcionados, bullying, ou conteúdo que promove violência/discriminação.\"
        }
        // ... mais tipos de denúncia ...
      ]
    }
```

*   **Resposta de Sucesso (201 Created):**

*   **Respostas de Erro:**
    *   `400 Bad Request`: `report_type_key` ausente ou inválido.
    *   `401 Unauthorized`: Não autenticado.
    *   `403 Forbidden`: Usuário não tem permissão para denunciar (ex: denunciando a si mesmo, ou limite de ACL).
    *   `404 Not Found`: Recurso principal (`{resource_id}`) não encontrado.
    *   `409 Conflict`: Se o usuário já denunciou este objeto por este mesmo `report_type_key` (devido à constraint UNIQUE na tabela track).
    *   `500 Internal Server Error`.
*   **Lógica de Backend (Controller):**
    1.  Extrair `reporter_profile_id` do JWT.
    2.  Mapear `{resource_type}` para o `system_name` apropriado (ex: `articles` -> `\"deeper_articles_reports\"`).
    3.  Verificar permissão ACL para denunciar.
    4.  Validar `report_type_key` contra uma lista de tipos permitidos (pode vir de `ReportingRepo.list_report_types/0`).
    5.  Chamar `Deeper.InteractionSystems.ReportingRepo.create_report/1` com os dados.
    6.  Se `create_report` retornar `{:error, :already_reported_this_type}`, retornar `409 Conflict`.
    7.  Retornar os detalhes da denúncia criada.

### 1.2. Verificar se o Usuário Atual Denunciou um Recurso por um Tipo Específico (Opcional)

Este endpoint pode ser útil para a UI saber se o botão \"Denunciar por este motivo\" deve ser desabilitado.

*   **Endpoint:** `GET /{resource_type}/{resource_id}/report/status`
*   **Autenticação:** Requerida (JWT).
*   **Query Parameters:**
    *   `report_type_key={string}` (obrigatório): O tipo de denúncia a ser verificado.
*   **Descrição:** Verifica se o usuário autenticado já denunciou um recurso específico por um determinado tipo de denúncia.
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Extrair `reporter_profile_id` do JWT.
    2.  Mapear `{resource_type}` para `system_name`.
    3.  Chamar `Deeper.InteractionSystems.ReportingRepo.has_user_reported_object_for_type?/4`.
    4.  Se `true`, opcionalmente buscar os detalhes da denúncia existente (pode ser uma nova função no repo ou parte da lógica do controller).

---

## 2. Tipos de Denúncia (`/report-types`)

### 2.1. Listar Tipos de Denúncia Disponíveis

*   **Endpoint:** `GET /report-types`
*   **Autenticação:** Nenhuma (público).
*   **Descrição:** Retorna uma lista dos tipos de denúncia disponíveis que os usuários podem selecionar.
*   **Query Parameters:**
    *   `lang={lang_code}` (opcional, para obter `title` traduzido se `title_lkey` for usado).
*   **Resposta de Sucesso (200 OK):**