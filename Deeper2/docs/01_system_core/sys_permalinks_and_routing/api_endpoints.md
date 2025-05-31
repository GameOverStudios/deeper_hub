# Documentação Deeper: Endpoints da API para Permalinks e Resolução de Caminhos

Este documento especifica os endpoints da API \"Deeper\" relacionados à resolução de caminhos de URL (permalinks ou slugs) para identificar recursos específicos do sistema.

## Convenções Gerais:

*   **Base URL:** `/api/v1`
*   **Autenticação:** O endpoint de resolução pode ser público, pois apenas retorna informações sobre para onde um caminho aponta.
*   **Formato de Resposta:** JSON.
*   **Códigos de Status e Erros:** Conforme definido em `docs/00_core_concepts/api_design_conventions.md`.

## Endpoints

### 1. Resolver um Caminho de URL

*   **Endpoint:** `POST /resolve-path`
*   **Status:** Público
*   **Descrição:** Recebe um caminho de URL (um permalink do UNA ou um slug de conteúdo) e tenta identificar o tipo de recurso e o identificador principal ao qual ele corresponde.
*   **Corpo da Requisição (JSON):**

```json
    {
      \"path\": \"/m/persons/home\" // Exemplo de permalink de página
    }
```

```json
    {
      \"path\": \"/john-doe-profile\" // Exemplo de slug de perfil de pessoa (se bx_persons_data.uri existir)
    }
```

```json
        {
          \"data\": {
            \"path_type\": \"page_permalink\",
            \"original_path\": \"/m/persons/home\",
            \"resolved_to\": {
              \"standard_url\": \"page.php?i=persons_home\", // Do sys_permalinks.standard
              \"page_object_name\": \"persons_home\" // Extraído do standard_url
            },
            \"message\": \"Caminho resolvido para um objeto de página UNA.\"
          }
        }
```

```json
        {
          \"data\": {
            \"path_type\": \"content_slug\",
            \"original_path\": \"/john-doe-profile\",
            \"resolved_to\": {
              \"resource_type\": \"bx_persons\", // Tipo do módulo/conteúdo
              \"profile_id\": 456, // sys_profiles.id
              \"content_id\": 789, // bx_persons_data.id
              \"account_id\": 123  // sys_accounts.id
            },
            \"message\": \"Caminho resolvido para um perfil de pessoa.\"
          }
        }
```

```json
        {
          \"error\": {
            \"code\": \"PATH_NOT_RESOLVED\",
            \"message\": \"O caminho fornecido não pôde ser resolvido para um recurso conhecido.\"
          }
        }
```

```elixir
# No router.ex
scope \"/api/v1\", DeeperWeb do
  pipe_through :api

  # ... outras rotas ...

  # Rota para buscar um perfil de pessoa pelo seu slug/uri
  get \"/persons/uri/:uri_slug\", PersonController, :show_by_uri

  # Rota para buscar uma página pelo seu nome de objeto (que pode vir de um permalink resolvido pelo cliente)
  get \"/pages/object/:page_object_name\", PageController, :show_by_object_name
end

# No PersonController.ex
def show_by_uri(conn, %{\"uri_slug\" => uri_slug}) do
  case Deeper.SystemCore.RoutingRepo.resolve_path_to_person_profile(uri_slug) do
    {:ok, profile_data_map} ->
      # Aqui, profile_data_map já conteria os IDs necessários.
      # Pode ser necessário buscar mais detalhes do perfil usando PersonsRepo.get_person_data/1
      # ou uma função combinada.
      # Vamos assumir que resolve_path_to_person_profile já retorna dados suficientes
      # ou que temos outra função para pegar os detalhes completos do perfil.
      # Ex: com {:ok, person_details} <- Deeper.Content.PersonsRepo.get_full_person_details_by_uri(uri_slug)
      #      render(conn, \"show.json\", person: person_details)
      #    end
      # Por ora, simplificando:
      render(conn, :ok, json: %{data: profile_data_map})
    {:error, :not_found} ->
      conn |> put_status(:not_found) |> json(%{error: %{code: \"PROFILE_NOT_FOUND\", message: \"Perfil não encontrado com este URI.\"}})
    {:error, _reason} ->
      conn |> put_status(:internal_server_error) |> json(%{error: %{code: \"SERVER_ERROR\", message: \"Erro interno no servidor.\"}})
  end
end
```

    Ou:

*   **Resposta de Sucesso (200 OK):**
    *   **Se o caminho corresponde a um permalink de página (via `sys_permalinks`):**

    *   **Se o caminho corresponde a um slug de conteúdo (ex: perfil de pessoa):**

    *   **(Outros tipos de resolução podem ser adicionados futuramente)**
*   **Erros Comuns:**
    *   `400 Bad Request`: Se o campo `path` estiver faltando no corpo da requisição.
    *   `404 Not Found`: Se o caminho fornecido não puder ser resolvido para nenhum recurso conhecido.

*   **Lógica do Backend (Controller):**
    1.  Receber o `path` da requisição.
    2.  Chamar uma função de alto nível, por exemplo, `RoutingRepo.resolve_generic_path/1` (ou uma sequência de chamadas a funções mais específicas do `RoutingRepo`):
        a.  Tentar `RoutingRepo.resolve_permalink/1`.
            *   Se sucesso, extrair o nome do objeto de página do campo `standard` (ex: de `page.php?i=NOME_OBJETO_PAGINA`, extrair `NOME_OBJETO_PAGINA`).
            *   Formatar a resposta como `path_type: \"page_permalink\"`.
        b.  Se não for um permalink, tentar resolver como um slug de conteúdo conhecido (a lógica para isso precisará ser expandida à medida que os módulos de conteúdo são adicionados):
            *   Tentar `RoutingRepo.resolve_path_to_person_profile/1`. Se sucesso, formatar a resposta como `path_type: \"content_slug\"`, `resource_type: \"bx_persons\"`.
            *   (Futuramente) Tentar resolver para outros tipos de conteúdo (artigos, eventos, etc.).
        c.  Se nenhuma resolução for bem-sucedida, retornar `404 Not Found`.

## Uso Interno pelo Roteador Phoenix (Não é um Endpoint Público)

Além do endpoint público `/resolve-path`, o `RoutingRepo` pode ser usado internamente pelo roteador do Phoenix para lidar com rotas de API mais dinâmicas que buscam recursos por slugs.

**Exemplo (Conceitual no `router.ex` do Phoenix):**

Neste cenário de uso interno, o `RoutingRepo` ajuda os controllers a buscar os dados corretos com base em identificadores amigáveis (slugs) passados na URL da API. O cliente, por sua vez, construiria essas URLs da API (ex: `/api/v1/persons/uri/john-doe`) após o usuário navegar para uma URL amigável na UI (ex: `/john-doe`).

A escolha entre o cliente usar o endpoint `/resolve-path` primeiro ou construir diretamente as URLs da API para slugs conhecidos dependerá da arquitetura do cliente e da complexidade do roteamento desejado.