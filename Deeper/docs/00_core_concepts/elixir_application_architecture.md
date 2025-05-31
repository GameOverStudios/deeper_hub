# Documentação Deeper: Arquitetura Geral da Aplicação Elixir

Este documento descreve a arquitetura geral proposta para a aplicação Elixir \"Deeper\", incluindo a organização do código, os principais componentes e como eles interagem. O objetivo é construir um sistema modular, testável e manutenível.

## 1. Estrutura do Projeto (Umbrella vs. Single Application):

Considerando a complexidade e a separação clara entre a lógica de negócios/dados e a camada web/API, uma **estrutura de projeto Umbrella** é recomendada.

deeper_umbrella/
├── apps/
│   ├── deeper_core/    # Aplicação OTP para lógica de negócios, acesso a dados, serviços core.
│   │   ├── lib/
│   │   │   └── deeper_core/
│   │   │       ├── application.ex
│   │   │       ├── data/
│   │   │       │   ├── repo.ex             # Interface principal para DB (wrapper DBConnection)
│   │   │       │   ├── migrations/         # Módulos de migração .ex
│   │   │       │   └── schemas/            # (Opcional) Structs para DTOs, não Ecto Schemas
│   │   │       ├── system_core/            # Contexto/Repositórios: Accounts, ACL, Options, Modules, etc.
│   │   │       ├── content/                # Contexto/Repositórios: Persons, Posts, Events, etc.
│   │   │       ├── interactions/           # Contexto/Repositórios: Comments, Votes, Favorites, etc.
│   │   │       ├── forms_grids/            # Contexto/Repositórios: Forms, Grids
│   │   │       ├── files/                  # Contexto/Repositórios: Storage, Files, UploaderService
│   │   │       ├── page_engine/            # Contexto/Repositórios: Pages, Layouts, Menus
│   │   │       ├── system_tools/           # Contexto/Repositórios: CronJobsRepo, CacheManager
│   │   │       └── services/               # Serviços de negócios que orquestram múltiplos repositórios
│   │   │           ├── acl_service.ex
│   │   │           ├── file_uploader_service.ex
│   │   │           └── ...
│   │   └── test/
│   └── deeper_web/     # Aplicação Phoenix para a camada API RESTful.
│       ├── lib/
│       │   └── deeper_web/
│       │       ├── application.ex
│       │       ├── controllers/          # Controladores da API (Pública e Admin)
│       │       │   ├── v1/
│       │       │   │   ├── fallback_controller.ex
│       │       │   │   ├── public_api/     # Controladores para API pública
│       │       │   │   └── admin_api/      # Controladores para Studio API
│       │       ├── views/                # Views para renderizar JSON
│       │       ├── router.ex             # Roteador Phoenix
│       │       ├── endpoint.ex
│       │       └── plugs/                # Plugs customizados (ex: Auth, ACL Check)
│       └── priv/
│       └── test/
├── config/             # Configurações (compartilhadas e por app)
├── deps/
├── docs/               # Documentação .md
├── mix.exs             # Mixfile do projeto Umbrella
└── README.md