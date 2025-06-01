# Documentação Deeper: Migrações para o Motor de Formulários

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Formulários Dinâmicos (`sys_objects_form`, `sys_form_inputs`, etc.) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/forms_engine/`.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_form` (`create_sys_objects_form_table.elixir.md`)**](./create_sys_objects_form_table.elixir.md):
    *   Cria a tabela para definir os objetos de formulário.

2.  [**Criar Tabela `sys_form_pre_lists` (`create_sys_form_pre_lists_table.elixir.md`)**](./create_sys_form_pre_lists_table.elixir.md):
    *   Cria a tabela para listas de valores pré-definidos (ex: para selects).

3.  [**Criar Tabela `sys_form_pre_values` (`create_sys_form_pre_values_table.elixir.md`)**](./create_sys_form_pre_values_table.elixir.md):
    *   Cria a tabela para os valores dentro das listas pré-definidas.

4.  [**Criar Tabela `sys_form_inputs` (`create_sys_form_inputs_table.elixir.md`)**](./create_sys_form_inputs_table.elixir.md):
    *   Cria a tabela para definir cada campo de entrada de um formulário. (Logicamente depende de `sys_objects_form` e `sys_form_pre_lists`).

5.  [**Criar Tabela `sys_form_displays` (`create_sys_form_displays_table.elixir.md`)**](./create_sys_form_displays_table.elixir.md):
    *   Cria a tabela para definir diferentes \"visualizações\" ou \"modos\" de um formulário. (Logicamente depende de `sys_objects_form`).

6.  [**Criar Tabela `sys_form_display_inputs` (`create_sys_form_display_inputs_table.elixir.md`)**](./create_sys_form_display_inputs_table.elixir.md):
    *   Cria a tabela para mapear quais campos de `sys_form_inputs` aparecem em um `sys_form_displays` específico, sua ordem e visibilidade ACL.

## Ordem de Execução:

A ordem de execução deve respeitar as dependências lógicas e de FK (se impostas na criação):
1.  `sys_objects_form`
2.  `sys_form_pre_lists`
3.  `sys_form_pre_values` (depende de `sys_form_pre_lists` se FK for usada)
4.  `sys_form_inputs`
5.  `sys_form_displays`
6.  `sys_form_display_inputs`