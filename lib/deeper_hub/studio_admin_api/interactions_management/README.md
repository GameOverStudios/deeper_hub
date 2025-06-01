# Documentação Deeper Studio API: Gerenciamento de Interações

Este diretório descreve os endpoints da API de Administração (\"Studio API\") para o gerenciamento e moderação de interações dos usuários, como comentários, denúncias, e potencialmente votos, favoritos, e scores.

**Objetivo Principal:** Permitir que administradores e moderadores visualizem, editem, deletem, aprovem ou alterem o status de interações geradas pelos usuários, garantindo a qualidade e segurança da plataforma \"Deeper\".

## Abordagem Geral:

*   Para cada sistema de interação genérico (Comentários, Denúncias, etc.), haverá um subdiretório correspondente aqui (ex: `comments_moderation/`, `reports_processing/`).
*   Os endpoints permitirão listar interações com filtros administrativos (ex: todos os comentários pendentes, todas as denúncias não resolvidas).
*   Ações de moderação incluirão alterar status, editar conteúdo (para comentários), e deletar.
*   A lógica utilizará os Repositórios de Interação genéricos já definidos (ex: `Deeper.Interactions.CommentsRepo`, `Deeper.Interactions.ReportingRepo`), mas com privilégios administrativos.

## Sistemas de Interação a Serem Gerenciados:

1.  [**Moderação de Comentários (`comments_moderation/`)**](./comments_moderation/README.md):
    *   Listar comentários por status (pendente, aprovado, spam).
    *   Aprovar, marcar como spam, editar, deletar comentários.

2.  [**Processamento de Denúncias (`reports_processing/`)**](./reports_processing/README.md):
    *   Listar denúncias por status (pendente, investigando, resolvido).
    *   Visualizar detalhes da denúncia e do conteúdo denunciado.
    *   Alterar status da denúncia (aceitar, rejeitar) e registrar quem processou.

3.  **(Opcional) Gerenciamento de Votos/Scores/Favoritos/Reações:**
    *   Menos comum ter gerenciamento administrativo direto para estes, a menos que seja para limpar votos/scores fraudulentos ou visualizar tendências. Para o escopo inicial, podemos focar em Comentários e Denúncias.

---
### Moderação de Comentários

Vamos detalhar os endpoints para moderação de comentários.