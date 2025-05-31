# Documentação Deeper Studio API: Gerenciamento de Conteúdo - Pessoas (`bx_persons`)

Este documento descreve os endpoints da API de Administração (\"Studio API\") especificamente para o gerenciamento e moderação de perfis de pessoas (`bx_persons_data` e entidades relacionadas como `sys_profiles` e `sys_accounts` no contexto de um perfil de pessoa).

**Objetivo Principal:** Fornecer aos administradores as ferramentas para visualizar, editar, deletar, e gerenciar o status de qualquer perfil de pessoa na plataforma \"Deeper\".

## Entidades Relevantes:

*   `bx_persons_data`: Dados principais do perfil da pessoa.
*   `sys_profiles`: Liga a `bx_persons_data.id` (como `content_id`) a uma `sys_accounts.id`.
*   `sys_accounts`: Contém o status da conta (ativo, bloqueado), email, etc.
*   Tabelas associadas: `bx_persons_pictures`, comentários, votos, etc. (o gerenciamento direto dessas sub-entidades pode ter seus próprios endpoints de admin ou ser parte da edição do perfil).

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.Content.PersonsRepo`
*   `Deeper.SystemCore.ProfilesRepo`
*   `Deeper.SystemCore.AccountsRepo`

Estes repositórios precisarão de funções que permitam:
*   Buscar perfis de pessoas com filtros administrativos (ex: por status da conta, por status do perfil).
*   Modificar qualquer campo em `bx_persons_data`, `sys_profiles.status`, `sys_accounts` (status, email confirmado, etc.).
*   Deletar perfis e contas associadas de forma controlada.

## Funcionalidades da API de Admin para Perfis de Pessoas:

*   Listar todos os perfis de pessoas com filtros administrativos.
*   Visualizar todos os detalhes de um perfil de pessoa específico (incluindo dados da conta e do perfil).
*   Editar qualquer aspecto de um perfil de pessoa e da conta associada.
*   Mudar o status do perfil (`sys_profiles.status`: active, pending, suspended).
*   Mudar o status da conta (`sys_accounts.active`, `sys_accounts.locked`).
*   Deletar um perfil de pessoa (o que pode implicar em deletar o registro em `sys_profiles` e, opcionalmente, a conta `sys_accounts` se for o único perfil).
*   Gerenciar fotos de perfil (aprovar, deletar).
*   Gerenciar o status \"destacado\" (`featured`) do perfil.