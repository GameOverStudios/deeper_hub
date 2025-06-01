# Documentação Deeper: Migrações para o Sistema de Favoritos

Este diretório contém a documentação e os exemplos de código Elixir para as migrações do banco de dados SQLite relacionadas ao sistema de Favoritos (`deeper_favorites_track`) no \"Deeper\".

Cada arquivo `.elixir.md` descreve um módulo de migração (`*.ex`) que reside em `lib/deeper/core/data/migrations/interaction_systems/favorites/`.

## Migrações Definidas:

1.  [**Criar Tabela `deeper_favorites_track` (`create_deeper_favorites_track_table.elixir.md`)**](./create_deeper_favorites_track_table.elixir.md):
    *   Cria a tabela para armazenar cada marcação de favorito.

## Considerações Adicionais de Migração:

*   As tabelas de entidade principal (ex: `deeper_articles_entries`) precisarão ser alteradas para incluir uma coluna `favorites_count` se ainda não existir. Essas alterações seriam parte das migrações dos respectivos módulos de conteúdo.