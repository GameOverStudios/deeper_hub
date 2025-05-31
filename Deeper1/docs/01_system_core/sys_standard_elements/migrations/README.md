# Documentação Deeper: Migrações para Elementos Padrão do Sistema

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas de Elementos Padrão do Sistema (`sys_std_*`).

## Migrações Definidas:

1.  [**Criar Tabela `sys_std_pages` (`create_sys_std_pages_table.elixir.md`)**](./create_sys_std_pages_table.elixir.md):
    *   Cria a tabela que define as páginas padrão do sistema.

2.  [**Criar Tabela `sys_std_widgets` (`create_sys_std_widgets_table.elixir.md`)**](./create_sys_std_widgets_table.elixir.md):
    *   Cria a tabela que define os widgets padrão.

3.  [**Criar Tabela `sys_std_pages_widgets` (`create_sys_std_pages_widgets_table.elixir.md`)**](./create_sys_std_pages_widgets_table.elixir.md):
    *   Cria a tabela de junção que associa widgets a páginas padrão.

4.  [**Criar Tabela `sys_std_roles` (`create_sys_std_roles_table.elixir.md`)**](./create_sys_std_roles_table.elixir.md):
    *   Cria a tabela que define os papéis padrão do sistema.

5.  [**Criar Tabela `sys_std_roles_actions` (`create_sys_std_roles_actions_table.elixir.md`)**](./create_sys_std_roles_actions_table.elixir.md):
    *   Cria a tabela que define ações associadas a esses papéis padrão.

6.  [**Criar Tabela `sys_std_roles_actions2roles` (`create_sys_std_roles_actions2roles_table.elixir.md`)**](./create_sys_std_roles_actions2roles_table.elixir.md):
    *   Cria a tabela de junção entre papéis e ações.

7.  [**Criar Tabela `sys_std_roles_members` (`create_sys_std_roles_members_table.elixir.md`)**](./create_sys_std_roles_members_table.elixir.md):
    *   Associa contas a papéis padrão.

8.  **(Opcional) Criar Tabela `sys_std_widgets_bookmarks`**:
    *   Se a funcionalidade de bookmark de widgets for implementada.