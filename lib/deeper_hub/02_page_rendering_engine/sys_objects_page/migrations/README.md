# Documentação Deeper: Migrações para Páginas, Blocos e Layouts

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de renderização de páginas (`sys_objects_page`, `sys_pages_layouts`, `sys_pages_blocks`, etc.) no \"Deeper\".

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/page_engine/` (sugestão de subpasta para organização).

## Migrações Definidas:

1.  [**Criar Tabela `sys_pages_types` (`create_sys_pages_types_table.elixir.md`)**](./create_sys_pages_types_table.elixir.md):
    *   Cria a tabela para definir os tipos gerais de página.

2.  [**Criar Tabela `sys_pages_layouts` (`create_sys_pages_layouts_table.elixir.md`)**](./create_sys_pages_layouts_table.elixir.md):
    *   Cria a tabela para definir os diferentes layouts de página.

3.  [**Criar Tabela `sys_objects_page` (`create_sys_objects_page_table.elixir.md`)**](./create_sys_objects_page_table.elixir.md):
    *   Cria a tabela principal que define cada página única do sistema.

4.  [**Criar Tabela `sys_pages_design_boxes` (`create_sys_pages_design_boxes_table.elixir.md`)**](./create_sys_pages_design_boxes_table.elixir.md):
    *   Cria a tabela para definir os diferentes estilos/templates visuais para os blocos.

5.  [**Criar Tabela `sys_pages_blocks` (`create_sys_pages_blocks_table.elixir.md`)**](./create_sys_pages_blocks_table.elixir.md):
    *   Cria a tabela que define cada bloco de conteúdo em uma página.

6.  **(Opcional)** [**Criar Tabela `sys_pages_wiki_blocks` (`create_sys_pages_wiki_blocks_table.elixir.md`)**](./create_sys_pages_wiki_blocks_table.elixir.md):
    *   Se a funcionalidade de blocos Wiki com versionamento for portada.

## Ordem de Execução:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeira:
1.  `sys_pages_types`
2.  `sys_pages_layouts`
3.  `sys_pages_design_boxes`
4.  `sys_objects_page` (depende de `sys_pages_types` e `sys_pages_layouts`)
5.  `sys_pages_blocks` (depende de `sys_objects_page` - logicamente, e `sys_pages_design_boxes`)
6.  (Opcional) `sys_pages_wiki_blocks` (depende de `sys_pages_blocks`)