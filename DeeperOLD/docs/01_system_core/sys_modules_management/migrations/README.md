# Documentação Deeper: Migrações para Gerenciamento de Módulos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas à tabela `sys_modules`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_modules` (`create_sys_modules_table.elixir.md`)**](./create_sys_modules_table.elixir.md):
    *   Cria a tabela `sys_modules`, que é o catálogo central de todos os módulos instalados no sistema UNA.

2.  **(Opcional) Outras Tabelas Relacionadas a Módulos:**
    *   `sys_modules_file_tracks`: Para rastrear alterações em arquivos de módulos (mais relevante para o sistema de atualização do UNA PHP).
    *   `sys_modules_relations`: Para dependências e ações inter-módulos durante instalação/desinstalação.
    *   Para a API \"Deeper\" inicial, focar em `sys_modules` é o mais importante para saber o estado dos módulos.