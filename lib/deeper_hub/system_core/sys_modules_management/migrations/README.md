# Documentação Deeper: Migrações para Gerenciamento de Módulos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas à tabela `sys_modules`, que armazena informações sobre os módulos do sistema UNA.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_modules` (`create_sys_modules_table.elixir.md`)**](./create_sys_modules_table.elixir.md):
    *   Cria a tabela principal para armazenar metadados de todos os módulos instalados no sistema.

*(Migrações para `sys_modules_file_tracks` e `sys_modules_relations` podem ser adicionadas futuramente se a leitura dessas informações se tornar relevante para a API \"Deeper\", mas inicialmente o foco é em `sys_modules`.)*