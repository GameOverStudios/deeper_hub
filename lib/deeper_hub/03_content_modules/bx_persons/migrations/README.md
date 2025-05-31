# Documentação Deeper: Migrações para Tabelas Adicionais de Pessoas (`bx_persons`)

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas às tabelas específicas do módulo `bx_persons` que não foram cobertas na seção `01_system_core` (como `sys_accounts`, `sys_profiles`, `bx_persons_data`).

Estas tabelas adicionais geralmente lidam com:
*   Imagens da galeria de perfis.
*   Rastreamento de interações (visualizações, favoritos, denúncias, votos, pontuações).
*   Metadados (palavras-chave, localizações, menções).
*   Habilidades.
*   Comentários específicos do módulo (se não usar o sistema genérico).

Cada arquivo `.elixir.md` aqui descreve um módulo de migração específico (`*.ex`) que reside em `lib/deeper/core/data/migrations/` (ou em um subdiretório específico para migrações de módulos de conteúdo, ex: `lib/deeper/content/persons/migrations/`).

## Migrações Definidas:

1.  [**Criar Tabela `bx_persons_pictures` (`create_bx_persons_pictures_table.elixir.md`)**](./create_bx_persons_pictures_table.elixir.md)
2.  [**Criar Tabela `bx_persons_pictures_resized` (`create_bx_persons_pictures_resized_table.elixir.md`)**](./create_bx_persons_pictures_resized_table.elixir.md)
3.  [**Criar Tabela `bx_persons_views_track` (`create_bx_persons_views_track_table.elixir.md`)**](./create_bx_persons_views_track_table.elixir.md)
4.  (Condicional) [**Criar Tabela `bx_persons_cmts` (`create_bx_persons_cmts_table.elixir.md`)**](./create_bx_persons_cmts_table.elixir.md) - Se o sistema de comentários específico do módulo for usado.
5.  [**Criar Tabela `bx_persons_favorites_track` (`create_bx_persons_favorites_track_table.elixir.md`)**](./create_bx_persons_favorites_track_table.elixir.md)
6.  [**Criar Tabela `bx_persons_reports_track` (`create_bx_persons_reports_track_table.elixir.md`)**](./create_bx_persons_reports_track_table.elixir.md)
7.  [**Criar Tabela `bx_persons_scores_track` (`create_bx_persons_scores_track_table.elixir.md`)**](./create_bx_persons_scores_track_table.elixir.md)
8.  [**Criar Tabela `bx_persons_votes_track` (`create_bx_persons_votes_track_table.elixir.md`)**](./create_bx_persons_votes_track_table.elixir.md)
9.  [**Criar Tabela `bx_persons_meta_keywords` (`create_bx_persons_meta_keywords_table.elixir.md`)**](./create_bx_persons_meta_keywords_table.elixir.md)
10. [**Criar Tabela `bx_persons_meta_locations` (`create_bx_persons_meta_locations_table.elixir.md`)**](./create_bx_persons_meta_locations_table.elixir.md)
11. [**Criar Tabela `bx_persons_meta_mentions` (`create_bx_persons_meta_mentions_table.elixir.md`)**](./create_bx_persons_meta_mentions_table.elixir.md)
12. [**Criar Tabela `bx_persons_skills` (`create_bx_persons_skills_table.elixir.md`)**](./create_bx_persons_skills_table.elixir.md)

## Dependências:

Muitas dessas tabelas têm chaves estrangeiras que referenciam `sys_profiles.id`. Portanto, a tabela `sys_profiles` deve existir antes da execução dessas migrações.

As migrações para tabelas de \"tracking\" (como `bx_persons_favorites_track`) também dependem da existência da tabela principal do objeto de interação (ex: `sys_objects_favorite`), que será definida em `04_interaction_systems/`. No entanto, as tabelas de tracking em si podem ser criadas, e a lógica de FK para as tabelas de configuração de objetos de interação pode ser conceitual inicialmente ou adicionada depois. Por simplicidade, as FKs diretas para `sys_profiles` são o foco aqui.