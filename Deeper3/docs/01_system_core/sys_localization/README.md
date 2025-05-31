# Documentação Deeper: Internacionalização e Localização (`sys_localization`)

Este módulo da API \"Deeper\" é responsável por fornecer acesso aos recursos de internacionalização (i18n) e localização (l10n) do sistema UNA. Isso inclui a listagem de idiomas disponíveis e a recuperação de strings traduzidas para a interface do usuário.

O objetivo é permitir que o cliente remoto renderize a aplicação no idioma preferido do usuário ou no idioma padrão do sistema. A modificação dos idiomas e traduções será uma funcionalidade da API de Administração (`07_studio_admin_api/`).

## Tabelas Relevantes do UNA:

*   **`sys_localization_languages`**: Define os idiomas suportados pelo sistema (ex: \"en\", \"pt-BR\"), seus títulos e flags.
*   **`sys_localization_categories`**: Agrupa chaves de tradução (geralmente por módulo ou funcionalidade).
*   **`sys_localization_keys`**: Armazena as chaves de tradução únicas (ex: `_sys_txt_hello`, `_bx_persons_txt_profile`).
*   **`sys_localization_strings`**: Contém as traduções efetivas, ligando uma `IDKey` (de `sys_localization_keys`) a um `IDLanguage` (de `sys_localization_languages`) e a string traduzida.

## Responsabilidades da API (Leitura Inicial):

*   Fornecer um endpoint para listar todos os idiomas ativos e disponíveis.
*   Fornecer um endpoint para buscar todas as strings traduzidas para um determinado idioma (potencialmente filtrado por categoria/módulo).

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite das tabelas `sys_localization_languages`, `sys_localization_categories`, `sys_localization_keys`, e `sys_localization_strings`.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas de localização no banco de dados SQLite.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.SystemCore.LocalizationRepo` e suas funções para ler dados das tabelas de localização.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para buscar informações de idiomas e strings traduzidas.

## Considerações Importantes:

*   **Formato de Retorno das Strings:** Para o endpoint que retorna strings traduzidas, um formato JSON chave-valor (onde a chave é a `sys_localization_keys.Key` e o valor é a `sys_localization_strings.String`) é geralmente o mais útil para o cliente (ex: bibliotecas i18n como `i18next`).
*   **Caching:** Strings de tradução raramente mudam. São candidatas ideais para caching agressivo no lado do servidor e/em cache do navegador do cliente.
*   **Fallback de Idioma:** Se uma string não estiver disponível no idioma solicitado, a API pode (opcionalmente) tentar buscar no idioma padrão do sistema (definido em `sys_options`).
*   **Carregamento Parcial:** Para aplicações grandes, carregar *todas* as strings de uma vez pode ser excessivo. A API pode suportar o carregamento de strings por categoria/módulo (que corresponde a `sys_localization_categories`).