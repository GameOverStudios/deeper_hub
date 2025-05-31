# Documentação Deeper Studio API: Gerenciamento de Elementos Padrão do Sistema

Este documento descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento de elementos padrão do sistema UNA, como Páginas Padrão (`sys_std_pages`), Widgets Padrão (`sys_std_widgets`), e Papéis Padrão (`sys_std_roles`).

**Objetivo Principal:** Permitir que administradores visualizem e, em alguns casos, modifiquem esses elementos que frequentemente compõem a estrutura do painel de administração (Studio) ou outras áreas fixas da plataforma.

## Entidades Relevantes (já definidas e migradas):

*   `sys_std_pages`
*   `sys_std_widgets`
*   `sys_std_pages_widgets` (tabela de junção)
*   `sys_std_roles`
*   `sys_std_roles_actions`
*   `sys_std_roles_actions2roles` (tabela de junção)
*   `sys_std_roles_members` (tabela de junção)

## Módulos de Acesso a Dados Envolvidos:

*   `Deeper.SystemCore.StdElementsRepo` (contendo funções CRUD para as tabelas acima).
*   `Deeper.SystemCore.LocalizationRepo` (para tradução de títulos, descrições, etc.).

## Endpoints da API de Administração para Elementos Padrão:

Os endpoints detalhados para cada tipo de elemento padrão são especificados em:
*   [**`api_endpoints.md`**](./api_endpoints.md)

## Considerações:

*   **Modificabilidade:** Muitos elementos padrão são definidos pelo sistema ou por módulos e podem não ser totalmente editáveis ou deletáveis via API para não quebrar funcionalidades core. A API deve indicar quais operações são permitidas.
*   **Uso:** Estes endpoints são primariamente para construir a interface do painel de administração da \"Deeper\", permitindo que ela se assemelhe ou adapte a estrutura do UNA Studio.