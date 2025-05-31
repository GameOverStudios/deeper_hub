# Documentação Deeper: Módulo de Acesso a Dados para Localização (`LocalizationRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.LocalizationRepo`, responsável por encapsular a lógica de consulta às tabelas de internacionalização e localização do sistema UNA (`sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, `sys_localization_strings`).

O `LocalizationRepo` fornecerá funções para listar idiomas disponíveis e buscar as strings traduzidas para um idioma específico, potencialmente filtradas por categoria.

**Localização do Código:** `lib/deeper/system_core/localization_repo.ex`

## Funções Principais (Exemplos):

### 1. Listar Idiomas

*   **`list_languages(only_enabled :: boolean() | nil) :: {:ok, list(map())} | {:error, any()}`**
    *   Lista os idiomas disponíveis no sistema.
    *   **Argumentos:**
        *   `only_enabled`: (Opcional) Se `true`, retorna apenas os idiomas com `Enabled = 1`. Se `nil` ou `false`, retorna todos.
    *   **Retorno:** `{:ok, [%{id: 1, name: \"en\", title: \"English\", ...}, ...]}`
    *   **SQL:**

```sql
        SELECT ID, Name, Flag, Title, Direction, LanguageCountry, Enabled
        FROM sys_localization_languages
        -- WHERE Enabled = 1 -- Adicionar dinamicamente se only_enabled == true
        ORDER BY Title;
```

```sql
                SELECT k.\"Key\", s.String
                FROM sys_localization_strings s
                JOIN sys_localization_keys k ON s.IDKey = k.ID
                WHERE s.IDLanguage = ?;
```

```sql
                SELECT k.\"Key\", s.String
                FROM sys_localization_strings s
                JOIN sys_localization_keys k ON s.IDKey = k.ID
                WHERE s.IDLanguage = ? AND k.IDCategory = ?;
```

```elixir
        base_sql = \"SELECT ID, Name, Flag, Title, Direction, LanguageCountry, Enabled FROM sys_localization_languages\"
        where_clause = if only_enabled, do: \" WHERE Enabled = 1\", else: \"\"
        order_clause = \" ORDER BY Title;\"
        sql = base_sql <> where_clause <> order_clause
        # ... Repo.query(sql, params_for_where_if_any) ...
```

        A cláusula `WHERE` seria construída dinamicamente:

### 2. Obter Strings de Tradução para um Idioma

*   **`get_strings_for_language(language_code :: String.t(), category_name :: String.t() | nil) :: {:ok, map()} | {:error, :language_not_found | :category_not_found | any()}`**
    *   Busca todas as strings de tradução para um determinado código de idioma (ex: \"en\", \"pt-BR\").
    *   Opcionalmente, pode filtrar por uma categoria de localização.
    *   **Argumentos:**
        *   `language_code`: O código do idioma (de `sys_localization_languages.Name`).
        *   `category_name`: (Opcional) O nome da categoria (de `sys_localization_categories.Name`) para filtrar as chaves.
    *   **Retorno:** `{:ok, %{\"_sys_txt_key1\" => \"Translated String 1\", \"_bx_mod_key2\" => \"String 2\", ...}}`
    *   **Lógica Interna Detalhada:**
        1.  **Obter `IDLanguage`:**
            *   SQL: `SELECT ID FROM sys_localization_languages WHERE Name = ? AND Enabled = 1 LIMIT 1;`
            *   Parâmetros: `language_code`.
            *   Se não encontrar, retorna `{:error, :language_not_found_or_disabled}`.
        2.  **(Opcional) Obter `IDCategory` se `category_name` fornecido:**
            *   SQL: `SELECT ID FROM sys_localization_categories WHERE Name = ? LIMIT 1;`
            *   Parâmetros: `category_name`.
            *   Se fornecido e não encontrado, retorna `{:error, :category_not_found}`.
        3.  **Buscar as Chaves e Strings:**
            *   SQL (sem filtro de categoria):

            *   SQL (com filtro de categoria):

            *   Parâmetros: `IDLanguage` (do passo 1), `IDCategory` (do passo 2, se aplicável).
        4.  Processar os resultados para criar o mapa `%{key => string}`.

### 3. Obter Todas as Categorias de Localização

*   **`list_categories() :: {:ok, list(map())} | {:error, any()}`**
    *   Lista todas as categorias de localização.
    *   **Retorno:** `{:ok, [%{id: 1, name: \"System\"}, %{id: 2, name: \"bx_persons\"}, ...]}`
    *   **SQL:** `SELECT ID, Name FROM sys_localization_categories ORDER BY Name;`

### Funções Auxiliares (Internas):

*   Mapeamento de linhas do banco de dados para mapas Elixir.

### Considerações:

*   **Fallback de Idioma:**
    *   A lógica de fallback (se uma string não existe para `language_code`, tentar buscar no idioma padrão do sistema) pode ser implementada aqui ou na camada de serviço/controller que usa este Repo.
    *   Isso envolveria uma query adicional ou uma lógica mais complexa para combinar resultados.
    *   O idioma padrão geralmente é definido em `sys_options` (ex: `lang_default`).
*   **Performance e Caching:**
    *   `get_strings_for_language/2` é uma função crítica para a performance da UI.
    *   **Caching Agressivo:** As strings traduzidas são candidatas perfeitas para caching (ex: Cachex, ETS).
        *   O cache pode ser por `(language_code, category_name)`.
        *   O cache seria invalidado quando as traduções são atualizadas (via API de Admin).
    *   A query de `JOIN` entre `sys_localization_strings` e `sys_localization_keys` deve ser eficiente. Índices em `s.IDLanguage`, `k.IDCategory`, `s.IDKey`, e `k.ID` são importantes.
*   **Sensibilidade de Caixa para Chaves:** Se a unicidade das chaves em `sys_localization_keys.\"Key\"` for estritamente case-sensitive (como no UNA original com `utf8_bin`), as buscas por chave também podem precisar considerar isso, ou a aplicação deve normalizar a caixa das chaves.