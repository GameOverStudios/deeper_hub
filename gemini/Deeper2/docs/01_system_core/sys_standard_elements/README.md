# Documentação Deeper: Elementos Padrão do Sistema (`sys_std_*`)

Esta seção da API \"Deeper\" aborda o acesso a dados de tabelas \"padrão\" (`sys_std_*`) do sistema UNA. Essas tabelas geralmente definem:

*   Páginas padrão do painel de administração (Studio).
*   Widgets padrão que podem ser usados nessas páginas ou em outros contextos.
*   Papéis padrão (diferentes dos níveis de ACL, mais como papéis administrativos ou funcionais dentro do Studio).

O foco inicial da API \"Deeper\" para esses elementos será a **leitura**, permitindo que um cliente remoto (especialmente um cliente de administração) possa entender a estrutura desses componentes. A modificação desses elementos padrão geralmente é feita através da interface de administração do UNA ou diretamente no banco de dados e pode não ser uma prioridade para a API \"Deeper\" inicial, a menos que se esteja construindo um clone completo do Studio.

## Tabelas Relevantes do UNA:

*   **`sys_std_pages`**: Define páginas padrão (principalmente para o Studio).
*   **`sys_std_widgets`**: Define widgets padrão que podem ser colocados nas `sys_std_pages`.
*   **`sys_std_pages_widgets`**: Tabela de junção entre `sys_std_pages` e `sys_std_widgets`.
*   **`sys_std_roles`**: Define papéis padrão (ex: Administrador, Moderador, Staff).
*   **`sys_std_roles_actions`**: Define ações específicas para esses papéis padrão.
*   **`sys_std_roles_actions2roles`**: Tabela de junção entre `sys_std_roles` e `sys_std_roles_actions`.
*   **`sys_std_roles_members`**: Associa contas de usuário a esses papéis padrão.
*   **`sys_std_widgets_bookmarks`**: Permite que usuários (geralmente administradores) favoritem/marquem widgets no dashboard do Studio.

## Abordagem para a API \"Deeper\" (Leitura):

*   Fornecer endpoints para listar e obter detalhes de páginas padrão, widgets e papéis.
*   A lógica de como esses elementos são renderizados ou funcionam no UNA PHP (especialmente no Studio) é complexa e não será replicada diretamente. A API fornecerá os dados brutos.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md):
    *   Define os `CREATE TABLE` statements para SQLite de todas as tabelas `sys_std_*` mencionadas.

2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar essas tabelas no banco de dados SQLite.

3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.SystemCore.StdElementsRepo` (ou repositórios mais granulares) e suas funções para ler dados dessas tabelas.

4.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md):
    *   Especifica os endpoints RESTful para buscar informações sobre esses elementos padrão.

## Considerações:

*   A principal utilidade desses dados via API \"Deeper\" seria para um cliente que está tentando reconstruir funcionalidades similares ao painel de administração do UNA ou para entender a configuração padrão de certos aspectos da interface.
*   Para um cliente de frontend focado no usuário final, essas tabelas podem ter relevância limitada, exceto talvez `sys_std_roles` se os papéis forem usados para lógica de exibição além do ACL principal.