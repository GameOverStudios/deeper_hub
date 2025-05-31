# Documentação Deeper: Migrações para Gerenciamento de Arquivos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Gerenciamento de Arquivos no \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Essenciais:

1.  [**Criar Tabela `sys_objects_storage` (`create_sys_objects_storage_table.elixir.md`)**](./create_sys_objects_storage_table.elixir.md):
    *   Cria a tabela para definir diferentes \"motores\" ou locais de armazenamento.

2.  [**Criar Tabela `deeper_files` (`create_deeper_files_table.elixir.md`)**](./create_deeper_files_table.elixir.md):
    *   Cria a tabela principal para armazenar metadados de todos os arquivos enviados.

3.  [**Criar Tabela `sys_storage_tokens` (`create_sys_storage_tokens_table.elixir.md`)**](./create_sys_storage_tokens_table.elixir.md):
    *   Cria a tabela para gerenciar tokens de acesso seguro a arquivos.

## Migrações Opcionais / Implementação Futura:

As seguintes migrações podem ser adicionadas posteriormente para funcionalidades mais avançadas:

*   **Criar Tabela `sys_storage_ghosts` (`create_sys_storage_ghosts_table.elixir.md`)**: Para rastrear arquivos fantasmas ou pendentes.
*   **Criar Tabela `sys_storage_user_quotas` (`create_sys_storage_user_quotas_table.elixir.md`)**: Para gerenciamento de cotas de usuário.
*   **Criar Tabela `sys_storage_mime_types` (`create_sys_storage_mime_types_table.elixir.md`)**: Para mapear extensões a tipos MIME e ícones.
*   **Criar Tabela `sys_storage_deletions` (`create_sys_storage_deletions_table.elixir.md`)**: Para uma fila de exclusão de arquivos.

A ordem de execução das migrações essenciais deve garantir que as dependências de chaves estrangeiras sejam respeitadas (ex: `deeper_files` depende de `sys_objects_storage` e `sys_profiles`).