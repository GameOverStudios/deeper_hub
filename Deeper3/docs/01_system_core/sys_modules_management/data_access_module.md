# Documentação Deeper: Módulo de Acesso a Dados para Módulos (`ModulesRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.ModulesRepo`, responsável por encapsular a lógica de consulta à tabela `sys_modules`. O foco principal é a leitura de informações sobre os módulos do sistema.

A modificação do status dos módulos (habilitar/desabilitar) via API será, a princípio, uma funcionalidade da API de Administração, mas este Repo poderá conter as funções de baixo nível para tal, se necessário.

**Localização do Código:** `lib/deeper/system_core/modules_repo.ex`

## Funções Principais (Exemplos):

### 1. Listar Todos os Módulos

*   **`list_modules(filter_opts :: map() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Retorna uma lista de todos os módulos registrados no sistema.
    *   **Argumentos:**
        *   `filter_opts`: (Opcional) Um mapa para filtros, ex: `%{enabled: true}`, `%{type: \"module\"}`.
    *   **Retorno:** `{:ok, [%{id: 1, name: \"bx_persons\", title: \"Persons\", enabled: 1, ...}, ...]}`
    *   **SQL (Exemplo com filtro opcional de `enabled`):**

```sql
        SELECT id, type, subtypes, name, title, vendor, version, help_url, path, uri, class_prefix, db_prefix, lang_category, dependencies, date, enabled, pending_uninstall, hash, updated
        FROM sys_modules
        -- WHERE enabled = ? -- Adicionar dinamicamente se filter_opts.enabled presente
        ORDER BY title;
```

```sql
        SELECT id, type, subtypes, name, title, vendor, version, help_url, path, uri, class_prefix, db_prefix, lang_category, dependencies, date, enabled, pending_uninstall, hash, updated
        FROM sys_modules
        WHERE name = ?
        LIMIT 1;
```

```sql
        SELECT id, type, subtypes, name, title, vendor, version, help_url, path, uri, class_prefix, db_prefix, lang_category, dependencies, date, enabled, pending_uninstall, hash, updated
        FROM sys_modules
        WHERE uri = ?
        LIMIT 1;
```

```sql
        SELECT enabled FROM sys_modules WHERE name = ? LIMIT 1;
```

        A cláusula `WHERE` seria construída dinamicamente com base em `filter_opts`.

### 2. Obter Detalhes de um Módulo pelo Nome

*   **`get_module_by_name(module_name :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca informações detalhadas de um módulo específico pelo seu nome único.
    *   **Argumentos:**
        *   `module_name`: O nome do módulo (de `sys_modules.name`).
    *   **Retorno:** `{:ok, %{id: 1, name: \"bx_persons\", ...}}` ou `{:error, :not_found}`.
    *   **SQL:**

### 3. Obter Detalhes de um Módulo pelo URI

*   **`get_module_by_uri(module_uri :: String.t()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Busca informações detalhadas de um módulo específico pelo seu URI único.
    *   **Argumentos:**
        *   `module_uri`: O URI do módulo (de `sys_modules.uri`).
    *   **Retorno:** `{:ok, %{id: 1, name: \"bx_persons\", ...}}` ou `{:error, :not_found}`.
    *   **SQL:**

### 4. Verificar se um Módulo está Habilitado

*   **`is_module_enabled?(module_name :: String.t()) :: {:ok, boolean()} | {:error, :not_found | any()}`**
    *   Verifica rapidamente se um módulo está marcado como habilitado.
    *   **Retorno:** `{:ok, true}`, `{:ok, false}`, ou `{:error, :not_found}`.
    *   **SQL:**

    *   A função então converteria o valor de `enabled` (0 ou 1) para um booleano.

### Funções de Modificação (Potencialmente para API de Admin - Esboço)

*Estas funções seriam mais complexas pois a simples alteração do campo `enabled` no UNA PHP dispara uma série de hooks (`on_enable`/`on_disable`) que a API \"Deeper\" não executaria diretamente. A API de Admin precisaria estar ciente dessas implicações.*

*   **`set_module_enabled_status(module_name :: String.t(), is_enabled :: boolean()) :: {:ok, map()} | {:error, :not_found | any()}`**
    *   Altera o campo `enabled` para um módulo.
    *   **SQL:** `UPDATE sys_modules SET enabled = ?, date = ? WHERE name = ? RETURNING *;` (atualiza `date` para refletir a mudança).
    *   **Atenção:** Chamar esta função diretamente contorna a lógica de enable/disable do UNA PHP.

### Mapeamento de Resultados:

*   As funções devem mapear as linhas do resultado SQL para mapas Elixir.
*   O campo `dependencies` (string separada por vírgulas) pode ser opcionalmente parseado para uma lista de strings no mapa Elixir.
*   Campos booleanos (`enabled`, `pending_uninstall`) devem ser convertidos para `true`/`false`.
*   Campos de data (`date`, `updated`) devem ser retornados como Timestamps Unix ou strings ISO 8601.

### Considerações:

*   **Caching:** Informações de módulos, especialmente seu status `enabled`, podem ser cacheadas para evitar acessos repetidos ao banco de dados, pois mudam com pouca frequência (geralmente apenas por ações de administração).
*   **Complexidade do Ciclo de Vida do Módulo:** O `ModulesRepo` para a API \"Deeper\" foca na leitura do estado atual. Replicar a lógica completa de instalação, desinstalação, habilitação e desabilitação de módulos do UNA (incluindo execução de hooks, gerenciamento de dependências, etc.) está fora do escopo de um simples Repo de leitura e seria uma tarefa de grande porte para a API de Administração.