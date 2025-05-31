# Documentação Deeper: Migrações para Localização

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Localização (`sys_localization_*`) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/localization/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_localization_languages` (`create_sys_localization_languages_table.elixir.md`)**](./create_sys_localization_languages_table.elixir.md)
2.  [**Criar Tabela `sys_localization_categories` (`create_sys_localization_categories_table.elixir.md`)**](./create_sys_localization_categories_table.elixir.md)
3.  [**Criar Tabela `sys_localization_keys` (`create_sys_localization_keys_table.elixir.md`)**](./create_sys_localization_keys_table.elixir.md)
4.  [**Criar Tabela `sys_localization_strings` (`create_sys_localization_strings_table.elixir.md`)**](./create_sys_localization_strings_table.elixir.md)

## Ordem de Execução:

As migrações devem ser executadas na seguinte ordem devido às dependências de chave estrangeira:
1.  `sys_localization_languages`
2.  `sys_localization_categories`
3.  `sys_localization_keys` (depende de `sys_localization_categories`)
4.  `sys_localization_strings` (depende de `sys_localization_keys` e `sys_localization_languages`)