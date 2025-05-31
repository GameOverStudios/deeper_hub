# Documentação Deeper: Migrações para Gerenciamento de Arquivos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Gerenciamento de Arquivos.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_storage` (`create_sys_objects_storage_table.elixir.md`)**](./create_sys_objects_storage_table.elixir.md):
    *   Cria a tabela `sys_objects_storage`, que define as configurações para diferentes \"motores\" ou \"objetos\" de armazenamento (ex: armazenamento local, S3). Esta tabela é crucial para determinar onde e como os arquivos são armazenados e quais tabelas de metadados são usadas.

2.  [**Criar Tabela de Arquivos Genérica (Exemplo: `sys_files`) (`create_sys_files_table.elixir.md`)**](./create_sys_files_table.elixir.md):
    *   Cria uma tabela de exemplo (`sys_files`) que pode ser referenciada por `sys_objects_storage.table_files` para armazenar metadados de arquivos. Módulos específicos (como `bx_persons_pictures`) podem ter suas próprias tabelas de metadados com estruturas similares, e suas migrações estarão nos respectivos diretórios de módulo. Esta migração serve como um modelo para uma tabela de arquivos genérica.

3.  **(Opcional) Outras Tabelas de Suporte ao Armazenamento:**
    *   `sys_storage_ghosts`: Para arquivos temporários antes da submissão final.
    *   `sys_storage_tokens`: Para tokens de acesso a arquivos privados.
    *   `sys_storage_user_quotas`: Para cotas de armazenamento por usuário.
    *   As migrações para estas tabelas podem ser adicionadas aqui se a funcionalidade for implementada. Para o escopo inicial da API de upload/download, elas podem ser adiadas.

## Ordem e Dependências:

*   `sys_objects_storage` deve existir para que a lógica de upload e recuperação de arquivos possa determinar as configurações corretas.
*   As tabelas de metadados de arquivos (como `sys_files` ou `bx_persons_pictures`) devem existir para armazenar informações sobre os arquivos carregados.