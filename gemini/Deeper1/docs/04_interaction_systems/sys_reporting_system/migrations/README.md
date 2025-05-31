# Documentação Deeper: Migrações para Sistema de Denúncias

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Denúncias Genérico.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_report` (`create_sys_objects_report_table.elixir.md`)**](./create_sys_objects_report_table.elixir.md):
    *   Responsável por criar a tabela `sys_objects_report`. Esta tabela define as configurações para cada \"instância\" de sistema de denúncias usada por diferentes tipos de conteúdo.

2.  **Migrações para Tabelas de Denúncias Específicas (Exemplo: `bx_persons_reports` e `bx_persons_reports_track`):**
    *   Estas migrações criam as tabelas que armazenam os dados de denúncias para um tipo de conteúdo específico.
    *   [**Criar Tabela `bx_persons_reports` (Agregação) (`create_bx_persons_reports_table.elixir.md`)**](./create_bx_persons_reports_table.elixir.md)
    *   [**Criar Tabela `bx_persons_reports_track` (Rastreamento) (`create_bx_persons_reports_track_table.elixir.md`)**](./create_bx_persons_reports_track_table.elixir.md)
    *   Outros módulos teriam suas próprias tabelas de denúncias com migrações correspondentes.

## Ordem e Dependências:

*   `sys_objects_report` deve existir para que o `ReportingRepo` funcione dinamicamente.
*   As tabelas de denúncias específicas devem existir para armazenar os dados.
*   Tabelas referenciadas em `TriggerTable` (ex: `bx_persons_data`) devem existir.