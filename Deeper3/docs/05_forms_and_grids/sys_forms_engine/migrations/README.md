# Documentação Deeper: Migrações para o Motor de Formulários

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas que compõem o sistema de formulários dinâmicos do UNA.

Isso inclui tabelas para definir os formulários em si (`sys_objects_form`), seus campos de entrada (`sys_form_inputs`), diferentes exibições de formulário (`sys_form_displays`, `sys_form_display_inputs`), e listas de valores pré-definidos (`sys_form_pre_lists`, `sys_form_pre_values`).

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` ou em um local apropriado para migrações de formulários/grids.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_form` (`create_sys_objects_form_table.elixir.md`)**](./create_sys_objects_form_table.elixir.md):
    *   Cria a tabela principal que define cada \"objeto de formulário\".

2.  [**Criar Tabela `sys_form_inputs` (`create_sys_form_inputs_table.elixir.md`)**](./create_sys_form_inputs_table.elixir.md):
    *   Cria a tabela que define cada campo de entrada dentro de um formulário. (Depende de `sys_objects_form`).

3.  [**Criar Tabela `sys_form_displays` (`create_sys_form_displays_table.elixir.md`)**](./create_sys_form_displays_table.elixir.md):
    *   Cria a tabela que define diferentes \"exibições\" ou contextos para um formulário. (Depende de `sys_objects_form`).

4.  [**Criar Tabela `sys_form_display_inputs` (`create_sys_form_display_inputs_table.elixir.md`)**](./create_sys_form_display_inputs_table.elixir.md):
    *   Cria a tabela de junção que controla quais campos aparecem em quais exibições de formulário e sua ordem. (Conceitualmente depende de `sys_form_displays` e `sys_form_inputs`).

5.  [**Criar Tabela `sys_form_pre_lists` (`create_sys_form_pre_lists_table.elixir.md`)**](./create_sys_form_pre_lists_table.elixir.md):
    *   Cria a tabela para definir nomes de listas de valores pré-definidos.

6.  [**Criar Tabela `sys_form_pre_values` (`create_sys_form_pre_values_table.elixir.md`)**](./create_sys_form_pre_values_table.elixir.md):
    *   Cria a tabela que armazena os valores para cada lista pré-definida. (Depende de `sys_form_pre_lists`).

*(Tabelas para interações em campos, como `sys_form_fields_ids`, podem ser adicionadas depois se essa funcionalidade for portada).*

## Ordem de Criação e Dependências:

As migrações devem ser executadas em uma ordem que respeite as dependências de chaves estrangeiras:
1.  `sys_objects_form`
2.  `sys_form_inputs` (depois de `sys_objects_form`)
3.  `sys_form_displays` (depois de `sys_objects_form`)
4.  `sys_form_display_inputs` (depois de `sys_form_displays` e `sys_form_inputs` conceitualmente)
5.  `sys_form_pre_lists`
6.  `sys_form_pre_values` (depois de `sys_form_pre_lists`)