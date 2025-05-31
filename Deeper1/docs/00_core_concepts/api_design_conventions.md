# Documentação Deeper: Convenções de Design da API

Este documento estabelece as convenções e padrões a serem seguidos no design e implementação da API RESTful \"Deeper\".

## 1. Versionamento

*   A API será versionada através do caminho da URL.
*   Exemplo: `/api/v1/...`

## 2. Formato de Dados

*   Todas as requisições e respostas que contêm um corpo (body) usarão **JSON**.
*   Cabeçalho `Content-Type: application/json` para requisições com corpo.
*   Cabeçalho `Accept: application/json` nas requisições para indicar que o cliente espera JSON.
*   O servidor sempre responderá com `Content-Type: application/json` para respostas com corpo.

## 3. Nomenclatura de Endpoints

*   Use **substantivos no plural** para representar coleções de recursos.
    *   Exemplo: `GET /api/v1/users`, `GET /api/v1/articles`
*   Use o ID do recurso no caminho para operações em um recurso específico.
    *   Exemplo: `GET /api/v1/users/{user_id}`, `PUT /api/v1/articles/{article_id}`
*   Para recursos aninhados, siga a hierarquia.
    *   Exemplo: `GET /api/v1/articles/{article_id}/comments`
*   Use **kebab-case** para nomes de endpoints se necessário (embora a preferência seja por caminhos simples).

## 4. Métodos HTTP

Use os métodos HTTP semanticamente:

*   `GET`: Para recuperar recursos. Deve ser seguro (não causa efeitos colaterais) e idempotente.
*   `POST`: Para criar novos recursos em uma coleção. Não é idempotente.
    *   Em sucesso, deve retornar `201 Created` com um cabeçalho `Location` apontando para o novo recurso e, opcionalmente, o corpo do novo recurso.
*   `PUT`: Para atualizar completamente um recurso existente (substituição total). Deve ser idempotente.
    *   Em sucesso, deve retornar `200 OK` (se retornar o recurso atualizado no corpo) ou `204 No Content` (se não retornar corpo).
*   `PATCH`: Para atualizar parcialmente um recurso existente. Não é necessariamente idempotente.
    *   Em sucesso, deve retornar `200 OK` (se retornar o recurso atualizado no corpo) ou `204 No Content`.
*   `DELETE`: Para remover um recurso existente. Deve ser idempotente.
    *   Em sucesso, deve retornar `200 OK` (se retornar uma mensagem de confirmação) ou `204 No Content`.

## 5. Códigos de Status HTTP

Use os códigos de status HTTP apropriados:

*   **2xx (Sucesso):**
    *   `200 OK`: Requisição bem-sucedida.
    *   `201 Created`: Recurso criado com sucesso.
    *   `204 No Content`: Requisição bem-sucedida, sem corpo de resposta.
*   **4xx (Erro do Cliente):**
    *   `400 Bad Request`: Requisição inválida (ex: JSON malformado, parâmetros faltando). A resposta deve incluir detalhes do erro.
    *   `401 Unauthorized`: Autenticação falhou ou não foi fornecida.
    *   `403 Forbidden`: Usuário autenticado, mas não tem permissão para acessar o recurso.
    *   `404 Not Found`: Recurso solicitado não existe.
    *   `405 Method Not Allowed`: Método HTTP não suportado para o recurso.
    *   `409 Conflict`: Conflito com o estado atual do recurso (ex: tentar criar um recurso que já existe com um identificador único).
    *   `422 Unprocessable Entity`: A requisição estava bem formada, mas contém erros semânticos (ex: falha de validação de campo). A resposta deve detalhar os erros de validação.
*   **5xx (Erro do Servidor):**
    *   `500 Internal Server Error`: Erro inesperado no servidor. Não exponha detalhes sensíveis do erro.
    *   `503 Service Unavailable`: Servidor temporariamente indisponível.

## 6. Formato de Resposta de Erro

Para erros `4xx` e `5xx`, a resposta JSON deve seguir um formato padronizado:

```json
// Exemplo para 400 Bad Request ou 422 Unprocessable Entity
{
  \"error\": {
    \"code\": \"VALIDATION_ERROR\", // Código de erro interno da aplicação
    \"message\": \"A validação falhou para os campos fornecidos.\",
    \"details\": [ // Opcional, para múltiplos erros de validação
      {
        \"field\": \"email\",
        \"issue\": \"O formato do email é inválido.\"
      },
      {
        \"field\": \"password\",
        \"issue\": \"A senha deve ter no mínimo 8 caracteres.\"
      }
    ]
  }
}

// Exemplo para 404 Not Found
{
  \"error\": {
    \"code\": \"RESOURCE_NOT_FOUND\",
    \"message\": \"O recurso solicitado não foi encontrado.\"
  }
}
```

```json
    {
      \"data\": [
        // ... lista de recursos ...
      ],
      \"pagination\": {
        \"total_items\": 127,
        \"total_pages\": 7,
        \"current_page\": 1,
        \"per_page\": 20,
        \"next_page_url\": \"/api/v1/resources?page=2&per_page=20\", // Opcional
        \"prev_page_url\": null // Opcional
      }
    }
```

## 7. Paginação

Para endpoints que retornam listas de recursos, a paginação deve ser suportada via query parameters.

*   **Baseada em Offset/Limite (ou Cursor):**
    *   `GET /api/v1/resources?offset=0&limit=20`
    *   `GET /api/v1/resources?page=1&per_page=20` (alternativa comum)
*   **Resposta com Informações de Paginação:** O corpo da resposta JSON para uma lista paginada deve incluir metadados de paginação.

    *   **Para `DBConnection` e SQL direto:** Implementar a paginação exigirá o uso de `LIMIT` e `OFFSET` na query SQL. O `total_items` exigirá uma query `COUNT(*)` separada (sem `LIMIT`/`OFFSET`, mas com os mesmos filtros).

## 8. Filtragem

*   Permitir filtragem de coleções através de query parameters.
*   Os nomes dos parâmetros devem corresponder aos atributos do recurso.
    *   Exemplo: `GET /api/v1/users?status=active&role=admin`

## 9. Ordenação

*   Permitir ordenação de coleções através de um query parameter `sort_by`.
*   O valor pode indicar o campo e a direção (ex: `name_asc`, `date_desc`).
    *   Exemplo: `GET /api/v1/articles?sort_by=created_at_desc`
*   Permitir múltiplos campos de ordenação, se necessário.

## 10. Seleção de Campos (Opcional, para otimização)

*   Considerar permitir que o cliente especifique quais campos retornar através de um query parameter `fields`.
    *   Exemplo: `GET /api/v1/users?fields=id,name,email`

## 11. Datas e Horas

*   Todas as datas e horas em respostas JSON devem estar no formato **ISO 8601** e, preferencialmente, em **UTC**.
    *   Exemplo: `2023-10-27T10:30:00Z`

Estas convenções ajudarão a manter a API \"Deeper\" consistente, previsível e fácil de usar.