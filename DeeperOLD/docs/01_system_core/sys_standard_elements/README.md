# Documentação Deeper: Elementos Padrão do Sistema (`sys_std_*`)

Este diretório detalha a estrutura de dados e a potencial API para os \"Elementos Padrão do Sistema\" do UNA, que incluem páginas padrão, widgets e papéis. Estes elementos são frequentemente parte integral da experiência do usuário e da administração.

## Componentes:

1.  [**Migrações (`migrations/`)**](./migrations/README.md):
    *   Define as migrações para criar as tabelas `sys_std_pages`, `sys_std_widgets`, `sys_std_roles` e tabelas relacionadas.

2.  [**Módulo de Acesso a Dados (`data_access_module.md`)**](./data_access_module.md) (Ex: `Deeper.SystemCore.StdElementsRepo`):
    *   Fornece funções para listar e obter detalhes desses elementos padrão. A modificação via API pode ser limitada, pois muitos são definidos pelo core ou módulos.

3.  [**Endpoints da API (`api_endpoints.md`)**](./api_endpoints.md) (Principalmente para leitura ou admin com escopo limitado):
    *   Endpoints para listar esses elementos, útil para a construção da UI de admin ou para entender a estrutura padrão.

## Importância:

*   **Páginas Padrão (`sys_std_pages`):** Podem definir as páginas não dinâmicas ou de sistema (ex: página de login, dashboard, configurações de conta do usuário). A API \"Deeper\" pode precisar saber sobre elas para roteamento ou para a API de Admin permitir a associação de widgets.
*   **Widgets Padrão (`sys_std_widgets`):** Define os blocos de informação/funcionalidade que podem ser colocados em páginas padrão ou dashboards.
*   **Papéis Padrão (`sys_std_roles`):** O UNA define um conjunto de papéis padrão além dos níveis de ACL. É importante entender como eles se relacionam (se houver relação direta) com `sys_acl_levels` ou se são um conceito separado.