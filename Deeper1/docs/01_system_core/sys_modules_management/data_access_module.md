# Documentação Deeper: Módulo de Acesso a Dados para Gerenciamento de Módulos (`Deeper.SystemCore.ModulesRepo`)

Este documento descreve o módulo Elixir `Deeper.SystemCore.ModulesRepo`. Sua responsabilidade é interagir com a tabela `sys_modules` para fornecer informações sobre os módulos instalados no sistema, seu status e configurações básicas.

Este repositório será usado internamente pela API \"Deeper\" e potencialmente pela API de Administração.

## Responsabilidades Principais:

*   Listar todos os módulos ou módulos filtrados por status (ex: habilitados).
*   Obter informações detalhadas de um módulo específico pelo seu nome.
*   Verificar se um módulo está habilitado.
*   (Para API de Admin) Habilitar ou desabilitar um módulo (alterando o campo `enabled`).

## Funções Públicas Principais e Lógica SQL:

*   **`list_modules(filters :: Keyword.t()) :: {:ok, modules :: list(map())} | {:error, any()}`**
    *   `filters`: Pode incluir `enabled: true/false`, `type: \"module\"`, etc.
    *   Constrói a cláusula `WHERE` dinamicamente com base nos filtros.
    *   SQL (Exemplo com filtro `enabled`): `SELECT id, name, title, vendor, version, uri, path, class_prefix, db_prefix, lang_category, enabled FROM sys_modules WHERE (? IS NULL OR enabled = ?) ORDER BY title;`
        *   `bind_params` dependeriam dos filtros aplicados.
    *   Mapeia cada linha para um mapa. O `title` pode precisar ser traduzido se for uma chave.

*   **`get_module_by_name(module_name :: String.t()) :: {:ok, module_info :: map()} | {:error, :not_found | any()}`**
    *   Busca um módulo específico pelo seu campo `name`.
    *   SQL: `SELECT * FROM sys_modules WHERE name = ? LIMIT 1;`
    *   Retorna um mapa com todos os campos do módulo ou `{:error, :not_found}`.

*   **`is_module_enabled(module_name :: String.t()) :: {:ok, boolean()} | {:error, :not_found | any()}`**
    *   Verifica rapidamente se um módulo está habilitado.
    *   SQL: `SELECT enabled FROM sys_modules WHERE name = ? LIMIT 1;`
    *   Retorna `{:ok, true}` ou `{:ok, false}`.
    *   Este resultado pode ser cacheado para módulos frequentemente verificados.

*   **`set_module_enabled_status(module_name :: String.t(), is_enabled :: boolean()) :: {:ok, updated_module :: map()} | {:error, :not_found | any()}`** (Principalmente para API de Admin)
    1.  Verifica se o módulo existe.
    2.  SQL: `UPDATE sys_modules SET enabled = ?, date = ?, updated = ? WHERE name = ? RETURNING *;`
        *   `enabled_value = if is_enabled, do: 1, else: 0`
        *   `current_ts = System.os_time(:second)` (para `date` e `updated`).
    3.  **Lógica Adicional (Importante):** No UNA PHP, habilitar/desabilitar um módulo dispara hooks e pode executar código de `on_enable`/`on_disable` (definido em `sys_modules_relations`). A API \"Deeper\", ao mudar o status `enabled`, não executará esse código PHP.
        *   **Impacto:** Se esses hooks realizam tarefas importantes (ex: registrar/desregistrar handlers de alerta, limpar cache específico do módulo), essas ações não ocorrerão automaticamente.
        *   **Solução \"Deeper\":** A API de Admin que chama esta função precisará estar ciente dessas implicações. Para uma replicação completa, a API \"Deeper\" precisaria ter uma lógica Elixir equivalente para esses hooks `on_enable`/`on_disable`, o que é um escopo de trabalho muito maior. Inicialmente, a API apenas mudará o flag `enabled`.
    4.  Retorna os dados do módulo atualizado.

## Considerações:

*   **Cache:** Informações sobre módulos habilitados e suas configurações básicas (`db_prefix`, `class_prefix`, etc.) são bons candidatos para cache na inicialização da aplicação \"Deeper\" para evitar consultas repetidas ao DB.
*   **Tradução de `title`:** Se `sys_modules.title` for uma chave de tradução, o `LocalizationRepo` será necessário para obter o título traduzido ao listar módulos.
*   **Impacto de Habilitar/Desabilitar:** Como mencionado, a API \"Deeper\" inicialmente apenas alterará o flag `enabled`. A funcionalidade completa de `on_enable`/`on_disable` do UNA PHP (que pode envolver alterações de esquema, registro de componentes, etc.) não será replicada sem um esforço significativo de portar essa lógica para Elixir.

Este `ModulesRepo` fornece a base para que a API \"Deeper\" entenda a configuração modular do sistema.