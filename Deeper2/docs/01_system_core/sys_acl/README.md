# Documentação Deeper: Controle de Acesso (ACL)

Este módulo da API \"Deeper\" não se destina a expor endpoints para gerenciar diretamente as configurações de ACL (isso será parte da `07_studio_admin_api/`). Em vez disso, esta seção detalha como a lógica de Controle de Acesso (ACL) do sistema UNA será implementada e utilizada internamente pelo backend \"Deeper\" para proteger os endpoints da API e controlar o acesso a funcionalidades.

## Responsabilidades Principais (Internas ao Backend):

*   Verificar se um usuário autenticado (identificado por seu `IDLevel` de ACL) tem permissão para executar uma determinada `IDAction`.
*   Consultar as tabelas `sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, e `sys_acl_levels_members` para tomar decisões de autorização.
*   Lidar com ações contáveis e suas restrições de tempo (se aplicável), consultando `sys_acl_actions_track`.

## Componentes do ACL do UNA:

*   **`sys_acl_levels`**: Define os diferentes níveis de membresia (ex: Visitante, Membro Grátis, Membro Premium).
*   **`sys_acl_actions`**: Define as ações granulares que podem ser controladas no sistema (ex: `bx_persons_view_profile`, `bx_persons_create_entry`, `send_message`).
*   **`sys_acl_matrix`**: Tabela de junção que especifica quais `IDLevel` têm permissão para quais `IDAction`, e com quais restrições (número de vezes permitido, período de validade).
*   **`sys_acl_levels_members`**: Associa contas de usuário (via `IDMember`, que geralmente é o `account_id`) a um `IDLevel` de ACL, especificando a data de início e, opcionalmente, de expiração da membresia.
*   **`sys_acl_actions_track`**: Rastreia o uso de ações contáveis por membro.

## Integração com a API \"Deeper\":

*   **Autenticação:** O JWT gerado no login conterá o `IDLevel` atual do usuário.
*   **Middleware de Autorização/Verificação:** Um middleware ou uma função de verificação dentro dos controllers/serviços será responsável por:
    1.  Identificar a `IDAction` requerida para o endpoint/operação atual.
    2.  Obter o `IDLevel` do usuário a partir do JWT.
    3.  Chamar funções do `Deeper.SystemCore.AclRepo` (ou similar) para verificar a permissão.
*   **`Deeper.SystemCore.AclRepo`**: Este módulo de acesso a dados encapsulará as queries SQL para consultar as tabelas de ACL e conterá a lógica para:
    *   Verificar se uma associação `IDLevel` <-> `IDAction` existe e é permitida na `sys_acl_matrix`.
    *   Verificar se a membresia do usuário em `sys_acl_levels_members` está ativa.
    *   Para ações contáveis, verificar e potencialmente atualizar `sys_acl_actions_track`.

## Documentação Detalhada:

1.  [**Esquema do Banco de Dados (`database_schema.md`)**](./database_schema.md): (Será criado se houver tabelas ACL específicas do Deeper, mas primariamente usaremos as tabelas UNA).
2.  [**Migrações Elixir (`migrations/`)**](./migrations/README.md):
    *   Contém os módulos de migração Elixir para criar as tabelas de ACL do UNA (`sys_acl_levels`, `sys_acl_actions`, `sys_acl_matrix`, `sys_acl_levels_members`, `sys_acl_actions_track`) no banco de dados SQLite.
3.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md):
    *   Descreve o `Deeper.SystemCore.AclRepo` e suas funções para verificar permissões.

O objetivo é garantir que a API \"Deeper\" respeite rigorosamente o sistema de permissões definido no banco de dados do UNA.