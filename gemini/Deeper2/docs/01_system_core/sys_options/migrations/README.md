# Documentação Deeper: Migrações para Configurações do Sistema (`sys_options`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas de Configurações do Sistema (`sys_options` e suas tabelas de suporte) no backend \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_options_types` (`create_sys_options_types_table.elixir.md`)**](./create_sys_options_types_table.elixir.md):
    *   Cria a tabela para definir os tipos de categorias de opções.

2.  [**Criar Tabela `sys_options_categories` (`create_sys_options_categories_table.elixir.md`)**](./create_sys_options_categories_table.elixir.md):
    *   Cria a tabela para definir as categorias das opções, ligada a `sys_options_types`.

3.  [**Criar Tabela `sys_options` (`create_sys_options_table.elixir.md`)**](./create_sys_options_table.elixir.md):
    *   Cria a tabela principal que armazena cada opção individual, seu valor e metadados, ligada a `sys_options_categories`.

4.  [**Criar Tabela `sys_options_mixes` (`create_sys_options_mixes_table.elixir.md`)**](./create_sys_options_mixes_table.elixir.md):
    *   Cria a tabela para definir \"mixes\" de configurações (ex: temas).

5.  [**Criar Tabela `sys_options_mixes2options` (`create_sys_options_mixes2options_table.elixir.md`)**](./create_sys_options_mixes2options_table.elixir.md):
    *   Cria a tabela de junção para armazenar os valores específicos das opções para cada mix, ligada a `sys_options_mixes`.

## Ordem de Criação e Dependências:

1.  `sys_options_types`
2.  `sys_options_categories` (depende de `sys_options_types`)
3.  `sys_options` (depende de `sys_options_categories`)
4.  `sys_options_mixes`
5.  `sys_options_mixes2options` (depende de `sys_options_mixes` e conceitualmente de `sys_options` via `option_name`)

As migrações devem ser executadas nesta ordem ou de uma forma que respeite essas dependências.