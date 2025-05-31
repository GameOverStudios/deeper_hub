# Documentação Deeper: Migrações para Sistema de Reações

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Reações Genérico.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_reaction` (`create_sys_objects_reaction_table.elixir.md`)**](./create_sys_objects_reaction_table.elixir.md):
    *   Responsável por criar a tabela `sys_objects_reaction` (ou uma tabela de configuração similar). Esta tabela define as configurações para cada \"instância\" de sistema de reações.

2.  **Migrações para Tabelas de Reações Específicas (Exemplo Genérico `module_reactions_summary` e `module_reactions_track`):**
    *   Estas migrações criam as tabelas que armazenam os dados de reações. Diferente de comentários ou votos onde o UNA frequentemente tem tabelas por módulo (ex: `bx_persons_cmts`), para reações, um par de tabelas genéricas (`module_reactions_summary`, `module_reactions_track`) poderia ser usado, ou o padrão de tabelas por módulo poderia ser seguido.
    *   Para este exemplo, vamos criar tabelas genéricas de exemplo que seriam nomeadas na `sys_objects_reaction.table_main` e `sys_objects_reaction.table_track`.
    *   [**Criar Tabela de Sumário de Reações (`create_reactions_summary_table.elixir.md`)**](./create_reactions_summary_table.elixir.md) (Ex: `generic_reactions_summary`)
    *   [**Criar Tabela de Rastreamento de Reações (`create_reactions_track_table.elixir.md`)**](./create_reactions_track_table.elixir.md) (Ex: `generic_reactions_track`)

## Ordem e Dependências:

*   `sys_objects_reaction` (ou similar) deve existir.
*   As tabelas de sumário e rastreamento de reações devem existir.
*   Tabelas referenciadas em `TriggerTable` devem existir.