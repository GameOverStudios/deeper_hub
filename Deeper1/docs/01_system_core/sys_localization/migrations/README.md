# Documentação Deeper: Migrações para Internacionalização e Localização

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Internacionalização e Localização (`sys_localization_*`) do UNA.

## Migrações Definidas:

1.  [**Criar Tabela `sys_localization_languages` (`create_sys_localization_languages_table.elixir.md`)**](./create_sys_localization_languages_table.elixir.md):
    *   Cria a tabela que define todos os idiomas disponíveis no sistema, seus códigos, títulos e status (habilitado/desabilitado).

2.  [**Criar Tabela `sys_localization_categories` (`create_sys_localization_categories_table.elixir.md`)**](./create_sys_localization_categories_table.elixir.md):
    *   Cria a tabela que categoriza as chaves de tradução para melhor organização.

3.  [**Criar Tabela `sys_localization_keys` (`create_sys_localization_keys_table.elixir.md`)**](./create_sys_localization_keys_table.elixir.md):
    *   Cria a tabela que armazena as chaves de string únicas (ex: `_sys_txt_welcome`) que precisam ser traduzidas.

4.  [**Criar Tabela `sys_localization_strings` (`create_sys_localization_strings_table.elixir.md`)**](./create_sys_localization_strings_table.elixir.md):
    *   Cria a tabela que armazena as traduções efetivas de cada chave para cada idioma.

## Ordem e Dependências:

*   `sys_localization_languages` e `sys_localization_categories` podem ser criadas independentemente.
*   `sys_localization_keys` depende de `sys_localization_categories`.
*   `sys_localization_strings` depende de `sys_localization_keys` e `sys_localization_languages`.

O sistema de execução de migrações deve respeitar essa ordem para garantir que as chaves estrangeiras (se definidas explicitamente nas migrações SQLite) sejam válidas.