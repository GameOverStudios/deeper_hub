# Documentação Deeper: Migrações para o Sistema de Comentários Genérico

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas centrais do sistema de comentários genérico do UNA (`sys_objects_cmts`, `sys_cmts_ids`).

Também inclui um **exemplo** de migração para uma tabela de conteúdo de comentários específica de um módulo (`example_module_cmts`), já que o nome real dessas tabelas é dinâmico e configurado em `sys_objects_cmts.Table`.

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de sistemas de interação.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_cmts` (`create_sys_objects_cmts_table.elixir.md`)**](./create_sys_objects_cmts_table.elixir.md):
    *   Cria a tabela de configuração que define cada \"objeto de comentários\" para diferentes tipos de conteúdo.

2.  [**Criar Tabela `sys_cmts_ids` (`create_sys_cmts_ids_table.elixir.md`)**](./create_sys_cmts_ids_table.elixir.md):
    *   Cria a tabela que armazena metadados e status para cada comentário individual, independentemente do sistema ao qual pertence. (Depende de `sys_objects_cmts` e `sys_profiles`).

3.  [**(Exemplo) Criar Tabela de Conteúdo de Comentários (`create_example_module_cmts_table.elixir.md`)**](./create_example_module_cmts_table.elixir.md):
    *   Demonstra como uma tabela que armazena os dados reais dos comentários (ex: `bx_persons_profile_cmts_data` ou o nome especificado em `sys_objects_cmts.Table`) seria criada. As migrações reais para essas tabelas de conteúdo de comentários podem precisar ser geradas ou gerenciadas com base na configuração em `sys_objects_cmts`.

## Ordem de Criação e Dependências:

1.  `sys_objects_cmts`
2.  `sys_cmts_ids` (depende de `sys_objects_cmts` e `sys_profiles`)
3.  As tabelas de conteúdo de comentários (ex: `example_module_cmts`) dependem conceitualmente de `sys_profiles` (para `cmt_author_id`).

As migrações devem ser executadas respeitando essas dependências.