# Documentação Deeper: Módulo de Acesso a Dados para Permalinks e Roteamento (`Deeper.SystemCore.RoutingRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.RoutingRepo` (ou `PermalinksRepo`). Sua principal responsabilidade é interagir com a tabela `sys_permalinks` para resolver um caminho de URL amigável (permalink) para seus componentes internos do UNA (como o `uri` de um `sys_objects_page` e quaisquer parâmetros associados).

Este repositório será usado pelo serviço da API que lida com a resolução de caminhos.

## Responsabilidades Principais:

*   Buscar um registro de permalink correspondente a um caminho de URL fornecido.
*   Parsear a URL \"standard\" associada para extrair o identificador da página (`i` ou `object`) e outros parâmetros.

## Funções Auxiliares Chave (Internas):

*   **`parse_standard_url(standard_url :: String.t()) :: {:ok, %{page_uri: String.t(), params: map()}} | {:error, :parsing_failed}`**
    *   Recebe uma URL standard do UNA (ex: `page.php?i=bx_persons_view&id=123&extra_param=abc`).
    *   Usa `URI.decode_query/1` e lógica de parsing para extrair:
        *   `page_uri`: O valor do parâmetro `i` (ou outro parâmetro chave que identifica o objeto de página, como `object`).
        *   `params`: Um mapa de todos os outros query parameters (ex: `%{ \"id\" => \"123\", \"extra_param\" => \"abc\" }`).
    *   Lida com casos onde a URL standard pode não seguir um padrão exato (ex: `modules/?r=modulename/action`).

## Funções Públicas Principais e Lógica SQL:

*   **`resolve_permalink_path(path :: String.t()) :: {:ok, resolution_data :: map()} | {:error, :not_found | any()}`**
    *   `path`: O caminho da URL amigável (ex: `/profile/john-doe`).
    1.  **Busca Direta:**
        *   SQL: `SELECT id, standard, permalink, \"check\", compare_by_prefix FROM sys_permalinks WHERE permalink = ? LIMIT 1;`
        *   `bind_params = [path]`
    2.  **Se não encontrado e houver lógica de prefixo:**
        *   Se a política for buscar por prefixos, a query seria mais complexa, buscando todos os permalinks onde `compare_by_prefix = 1` e então, em Elixir, encontrar a correspondência mais longa para o `path` dado.
        *   SQL (para buscar candidatos a prefixo): `SELECT id, standard, permalink, \"check\", compare_by_prefix FROM sys_permalinks WHERE compare_by_prefix = 1 AND ? LIKE permalink || '%';`
        *   A lógica de encontrar o \"melhor\" match por prefixo (o mais específico/longo) seria feita em Elixir após buscar os candidatos.
        *   **Simplificação Inicial:** Para a primeira versão, podemos focar na correspondência exata e depois adicionar a lógica de prefixo se for crítica. O dump do UNA SQL usa `ORDER BY LENGTH(permalink) DESC` ao buscar por prefixo, o que ajuda a obter o mais específico primeiro.

```elixir
        # Exemplo de query que tenta exato e depois prefixo (mais complexa para DBConnection direto)
        # Poderia ser duas queries separadas.
        # Para SQLite, o || é concatenação.
        # A query de prefixo pode retornar múltiplos resultados, o primeiro (mais longo) é o desejado.
        sql = \"\"\"
        SELECT id, standard, permalink, \"check\", compare_by_prefix FROM sys_permalinks
        WHERE permalink = ? OR (? LIKE permalink || '%' AND compare_by_prefix = 1)
        ORDER BY CASE WHEN permalink = ? THEN 0 ELSE 1 END, LENGTH(permalink) DESC
        LIMIT 1;
        \"\"\"
        # bind_params = [path, path, path]
```

```elixir
            {:ok, %{
              resolved: true,
              original_path: path,
              una_standard_url: permalink_db_row[\"standard\"],
              page_object_uri: page_uri,
              params: query_params, // Parâmetros da URL standard
              permalink_info: %{ // Metadados do permalink em si
                id: permalink_db_row[\"id\"],
                permalink: permalink_db_row[\"permalink\"],
                check_original: permalink_db_row[\"check\"]
              }
            }}
```

    3.  Se um registro de permalink (`permalink_db_row`) for encontrado:
        *   `{:ok, %{page_uri: page_uri, params: query_params}} = parse_standard_url(permalink_db_row[\"standard\"])`
        *   Retorna:

    4.  Se não encontrado, retorna `{:error, :not_found}`.

## Considerações:

*   **Complexidade do `parse_standard_url`:** As URLs \"standard\" no UNA podem ter formatos variados. A função de parsing precisa ser robusta o suficiente para lidar com os padrões mais comuns (ex: `page.php?i=...`, `modules/?r=...`).
*   **Performance da Busca de Permalink:** A coluna `permalink` deve ter um índice `UNIQUE` para buscas rápidas. A busca por prefixo pode ser mais lenta se houver muitos permalinks com `compare_by_prefix = 1`.
*   **Mapeamento para `sys_objects_page.uri`:** A API de Páginas (`GET /api/v1/pages`) espera um `uri` que corresponda a `sys_objects_page.uri`. A função `parse_standard_url` precisa garantir que o `page_uri` extraído seja esse identificador.
*   **Prioridade de Matching:** Se múltiplos permalinks puderem corresponder a um caminho (ex: um exato e um por prefixo), a lógica deve priorizar a correspondência mais específica (geralmente a exata, ou a de prefixo mais longa).

Este `RoutingRepo` fornecerá a funcionalidade base para que a API \"Deeper\" possa interpretar as URLs amigáveis e direcionar para o conteúdo correto da página UNA.