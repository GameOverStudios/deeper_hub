# Documentação Deeper: Migrações para Configurações do Sistema

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Configurações (`sys_options*`) no \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/options/` (sugestão de subpasta).

## Migrações Definidas:

1.  [**Criar Tabela `sys_options_types` (`create_sys_options_types_table.elixir.md`)**](./create_sys_options_types_table.elixir.md):
    *   Cria a tabela para definir os tipos/grupos de configurações.

2.  [**Criar Tabela `sys_options_categories` (`create_sys_options_categories_table.elixir.md`)**](./create_sys_options_categories_table.elixir.md):
    *   Cria a tabela para definir as categorias de configurações, vinculadas aos tipos.

3.  [**Criar Tabela `sys_options` (`create_sys_options_table.elixir.md`)**](./create_sys_options_table.elixir.md):
    *   Cria a tabela principal para armazenar as configurações individuais.

## Ordem de Execução:

As migrações devem ser executadas na seguinte ordem devido às dependências de chave estrangeira:
1.  `sys_options_types`
2.  `sys_options_categories` (depende de `sys_options_types`)
3.  `sys_options` (depende de `sys_options_categories`)