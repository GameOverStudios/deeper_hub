# Documentação Deeper Studio API: Gerenciamento de Conteúdo

Este diretório descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento e moderação de conteúdo específico de módulos (ex: perfis de pessoas, posts, eventos, etc.).

**Objetivo Principal:** Permitir que administradores e moderadores visualizem, editem, deletem, aprovem, ou realizem outras ações de moderação sobre o conteúdo gerado pelos usuários ou pelo sistema, para cada módulo de conteúdo específico.

## Abordagem Geral:

*   Para cada módulo de conteúdo principal do UNA (ex: `bx_persons`, `bx_posts`), haverá um subdiretório correspondente aqui (ex: `content_management/bx_persons/`, `content_management/bx_posts/`).
*   Cada subdiretório de módulo conterá um `README.md` e `api_endpoints.md` detalhando as operações de gerenciamento para aquele tipo de conteúdo.
*   Os endpoints geralmente seguirão padrões CRUD, mas com o contexto de administração (ex: um admin pode editar qualquer post, não apenas os seus).
*   A lógica de negócios e as permissões para estas ações administrativas residirão nos controllers da API de Admin, que por sua vez utilizarão os Repositórios de conteúdo já definidos (ex: `Deeper.Content.PersonsRepo`, `Deeper.Content.PostsRepo`).

## Funcionalidades Comuns de Gerenciamento de Conteúdo:

*   **Listagem com Filtros Avançados:** Listar todo o conteúdo de um tipo, com filtros por status (pendente, ativo, spam), autor, data, etc.
*   **Visualização Detalhada:** Ver todos os detalhes de um item de conteúdo específico.
*   **Edição:** Modificar qualquer campo de um item de conteúdo.
*   **Deleção:** Remover itens de conteúdo.
*   **Mudança de Status:** Aprovar conteúdo pendente, marcar como spam, destacar (featured), etc.
*   **Ações em Lote:** Aplicar uma ação (ex: deletar, aprovar) a múltiplos itens de conteúdo de uma vez.

## Relação com APIs Públicas e de Usuário:

Enquanto as APIs públicas (`/api/v1/persons`, `/api/v1/posts`) lidam com a visualização e criação de conteúdo pelo usuário final (respeitando suas permissões), a API de Admin de Conteúdo permite operações privilegiadas sobre *qualquer* conteúdo.

---
### Exemplo: Gerenciamento de Conteúdo para Módulo Pessoas (`bx_persons`)

O subdiretório `content_management/bx_persons/` detalhará os endpoints para administrar perfis de pessoas.