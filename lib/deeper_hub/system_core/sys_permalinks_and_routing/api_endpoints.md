# Documentação Deeper: Endpoints da API para Permalinks (Opcional)

Esta seção descreve endpoints da API RESTful \"Deeper\" que podem ser implementados para interagir com o sistema de permalinks, principalmente para fins de resolução ou informação. O roteamento principal da API é gerenciado pelo Phoenix.

## 1. Resolver Permalink

*   **Endpoint:** `GET /api/v1/permalinks/resolve`
*   **Autenticação:** Nenhuma (público).
*   **Descrição:** Dado um permalink (URL amigável do UNA), retorna a URL \"standard\" associada e, opcionalmente, o parâmetro principal extraído (ex: nome do objeto de página).
*   **Query Parameters:**
    *   `uri` (obrigatório): O permalink a ser resolvido (ex: `/m/persons/home`).
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"permalink_id\": 123,
        \"permalink_uri\": \"/m/persons/home\",
        \"standard_uri\": \"page.php?i=bx_persons_home\",
        \"check_handler\": \"BxPersonsModule::check_permalinks\", // Informativo
        \"extracted_param\": \"bx_persons_home\" // Resultado de extract_param_from_standard_url
      }
    }
```

```json
    {
      \"data\": {
        \"permalink_id\": 124,
        \"permalink_uri\": \"/m/persons/view/john_doe\",
        \"standard_uri\": \"modules/?r=persons/view_entry/101\", // Exemplo, formato pode variar
        \"check_handler\": \"BxPersonsModule::check_permalinks\",
        \"content_type\": \"bx_persons\", // Inferido do 'check' ou standard_uri
        \"content_id\": 101 // Inferido do standard_uri
      }
    }
```

```json
    {
      \"data\": {
        \"object_name\": \"bx_persons_home\",
        \"standard_uri\": \"page.php?i=bx_persons_home\",
        \"permalink_uri\": \"/m/persons/home\"
      }
    }
```

    Ou, se o `standard_uri` for um ID de conteúdo:

*   **Respostas de Erro:**
    *   `400 Bad Request`: Parâmetro `uri` ausente.
    *   `404 Not Found`: Permalink não encontrado ou não pôde ser resolvido para um parâmetro útil.
*   **Lógica de Backend:**
    1.  Obter `uri` do query param.
    2.  Chamar `Deeper.SystemCore.PermalinksRepo.get_standard_url_from_permalink(uri)`.
    3.  Se encontrado, chamar `Deeper.SystemCore.PermalinksRepo.extract_param_from_standard_url(standard_uri)` para tentar obter o parâmetro principal.
    4.  Construir e retornar a resposta JSON.

## 2. Obter Permalink para um Objeto de Página (Opcional)

*   **Endpoint:** `GET /api/v1/permalinks/for-page-object`
*   **Autenticação:** Nenhuma.
*   **Descrição:** Dado o nome de um objeto de página do UNA (ex: `bx_persons_home`), retorna o permalink associado.
*   **Query Parameters:**
    *   `object_name` (obrigatório): O nome do objeto de página (ex: `bx_persons_home`).
*   **Resposta de Sucesso (200 OK):**

*   **Lógica de Backend:**
    1.  Construir a `standard_uri` esperada (ex: `page.php?i=#{object_name}`).
    2.  Chamar `Deeper.SystemCore.PermalinksRepo.get_permalink_from_standard_url(standard_uri)`.

## Observações:

*   Estes endpoints são opcionais e sua necessidade dependerá de como o cliente interage com o conceito de permalinks.
*   Para a maioria das operações da API \"Deeper\", o cliente usará os endpoints diretos da API (ex: `GET /api/v1/pages?object_name=bx_persons_home`), e o Phoenix cuidará do roteamento. Os endpoints de permalink seriam mais para \"tradução\" ou descoberta.
*   A API para **administrar** permalinks (criar, editar, deletar) estaria em `07_studio_admin_api/seo_admin_api.md`.