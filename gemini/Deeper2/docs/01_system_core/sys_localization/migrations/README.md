# Documentação Deeper: Migrações para Localização (`sys_localization`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas de Internacionalização e Localização (`sys_localization_*`) no backend \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_localization_languages` (`create_sys_localization_languages_table.elixir.md`)**](./create_sys_localization_languages_table.elixir.md):
    *   Cria a tabela para definir os idiomas suportados.

2.  [**Criar Tabela `sys_localization_categories` (`create_sys_localization_categories_table.elixir.md`)**](./create_sys_localization_categories_table.elixir.md):
    *   Cria a tabela para definir categorias de chaves de tradução.

3.  [**Criar Tabela `sys_localization_keys` (`create_sys_localization_keys_table.elixir.md`)**](./create_sys_localization_keys_table.elixir.md):
    *   Cria a tabela para armazenar as chaves de tradução únicas, ligada a `sys_localization_categories`.

4.  [**Criar Tabela `sys_localization_strings` (`create_sys_localization_strings_table.elixir.md`)**](./create_sys_localization_strings_table.elixir.md):
    *   Cria a tabela para armazenar as strings traduzidas efetivas, ligada a `sys_localization_keys` e `sys_localization_languages`.

## Ordem de Criação e Dependências:

1.  `sys_localization_languages`
2.  `sys_localization_categories`
3.  `sys_localization_keys` (depende de `sys_localization_categories`)
4.  `sys_localization_strings` (depende de `sys_localization_keys` e `sys_localization_languages`)

As migrações devem ser executadas nesta ordem ou de uma forma que respeite essas dependências.