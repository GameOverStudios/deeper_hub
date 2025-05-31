# Documentação Deeper: Migrações para Motor de Formulários

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao Sistema de Formulários Genérico do UNA.

## Migrações Definidas:

1.  [**Criar Tabela `sys_objects_form` (`create_sys_objects_form_table.elixir.md`)**](./create_sys_objects_form_table.elixir.md):
    *   Cria a tabela que define cada formulário no sistema.

2.  [**Criar Tabela `sys_form_inputs` (`create_sys_form_inputs_table.elixir.md`)**](./create_sys_form_inputs_table.elixir.md):
    *   Cria a tabela que define cada campo de entrada dentro de um formulário.

3.  [**Criar Tabela `sys_form_displays` (`create_sys_form_displays_table.elixir.md`)**](./create_sys_form_displays_table.elixir.md):
    *   Cria a tabela que define diferentes \"exibições\" de um formulário (agrupando campos).

4.  [**Criar Tabela `sys_form_display_inputs` (`create_sys_form_display_inputs_table.elixir.md`)**](./create_sys_form_display_inputs_table.elixir.md):
    *   Cria a tabela que associa campos específicos a uma exibição de formulário e controla sua visibilidade por nível de ACL.

5.  [**Criar Tabela `sys_form_pre_lists` (`create_sys_form_pre_lists_table.elixir.md`)**](./create_sys_form_pre_lists_table.elixir.md):
    *   Cria a tabela que define chaves para listas de valores pré-definidos.

6.  [**Criar Tabela `sys_form_pre_values` (`create_sys_form_pre_values_table.elixir.md`)**](./create_sys_form_pre_values_table.elixir.md):
    *   Cria a tabela que armazena os valores e legendas para as listas pré-definidas.

7.  **(Opcional) Tabelas de Interação com Campos de Formulário:**
    *   `sys_form_fields_ids`, `sys_form_fields_reaction`, `sys_form_fields_reaction_track`, `sys_form_fields_votes`, `sys_form_fields_votes_track`.
    *   Estas permitem que campos individuais de formulários (ex: um campo de descrição em um perfil) possam ser votados ou ter reações. Para a API \"Deeper\" inicial, podemos adiar a implementação direta da API para estas interações em campos, mas as tabelas podem ser criadas por completude.

## Ordem e Dependências:

*   `sys_objects_form` é central.
*   `sys_form_inputs` depende de `sys_objects_form`.
*   `sys_form_displays` depende de `sys_objects_form` (implicitamente, pelo nome do objeto).
*   `sys_form_display_inputs` depende de `sys_form_displays` e `sys_form_inputs` (pelo nome).
*   `sys_form_pre_lists` é independente.
*   `sys_form_pre_values` depende de `sys_form_pre_lists` (pela `Key`).