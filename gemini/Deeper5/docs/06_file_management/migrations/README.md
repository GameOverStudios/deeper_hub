# Documentação Deeper: Migrações para Gerenciamento de Arquivos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Gerenciamento de Arquivos no \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/file_management/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_storage_backends` (`create_deeper_storage_backends_table.elixir.md`)**](./create_deeper_storage_backends_table.elixir.md):
    *   Cria a tabela para configurar diferentes backends de armazenamento (local, S3, etc.).

2.  [**Criar Tabela `deeper_files` (`create_deeper_files_table.elixir.md`)**](./create_deeper_files_table.elixir.md):
    *   Cria a tabela unificada para armazenar metadados de todos os arquivos upados.

3.  **(Opcional)** [**Criar Tabela `deeper_file_versions` (`create_deeper_file_versions_table.elixir.md`)**](./create_deeper_file_versions_table.elixir.md):
    *   Cria a tabela para rastrear diferentes versões ou transformações de um arquivo original (ex: thumbnails, resoluções de vídeo). Esta migração é mais relevante se um sistema de transcodificação robusto for implementado.

## Ordem de Execução:

1.  `deeper_storage_backends`
2.  `deeper_files` (depende de `sys_profiles` e, logicamente, de `deeper_storage_backends`)
3.  (Opcional) `deeper_file_versions` (depende de `deeper_files` e `deeper_storage_backends`)

É crucial que a tabela `sys_profiles` (de `01_system_core`) exista antes de criar `deeper_files`.