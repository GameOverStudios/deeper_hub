# Documentação Deeper: Migrações para Objetos de Página e Blocos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas que compõem o motor de renderização de páginas do UNA (`sys_objects_page`, `sys_pages_blocks`, `sys_pages_layouts`, `sys_pages_design_boxes`, `sys_pages_types`).

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_pages_layouts` (`create_sys_pages_layouts_table.elixir.md`)**](./create_sys_pages_layouts_table.elixir.md)
2.  [**Criar Tabela `sys_pages_design_boxes` (`create_sys_pages_design_boxes_table.elixir.md`)**](./create_sys_pages_design_boxes_table.elixir.md)
3.  [**Criar Tabela `sys_pages_types` (`create_sys_pages_types_table.elixir.md`)**](./create_sys_pages_types_table.elixir.md)
4.  [**Criar Tabela `sys_objects_page` (`create_sys_objects_page_table.elixir.md`)**](./create_sys_objects_page_table.elixir.md) (Depende de `sys_pages_layouts` e `sys_pages_types`)
5.  [**Criar Tabela `sys_pages_blocks` (`create_sys_pages_blocks_table.elixir.md`)**](./create_sys_pages_blocks_table.elixir.md) (Depende de `sys_objects_page` e `sys_pages_design_boxes`)
6.  (Opcional) [**Criar Tabela `sys_pages_blocks_data` (`create_sys_pages_blocks_data_table.elixir.md`)**](./create_sys_pages_blocks_data_table.elixir.md) (Depende de `sys_pages_blocks`)


## Ordem de Criação e Dependências:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeiras:
1.  `sys_pages_layouts`
2.  `sys_pages_design_boxes`
3.  `sys_pages_types`
4.  `sys_objects_page` (depois de `sys_pages_layouts` e `sys_pages_types`)
5.  `sys_pages_blocks` (depois de `sys_objects_page` e `sys_pages_design_boxes`)
6.  `sys_pages_blocks_data` (depois de `sys_pages_blocks`)