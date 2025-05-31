# Documentação Deeper: Arquitetura da Aplicação Elixir/Phoenix

Este documento descreve a arquitetura proposta para a aplicação backend \"Deeper\", construída com Elixir e o framework Phoenix. O objetivo é criar uma API RESTful robusta, escalável e de fácil manutenção que sirva como backend para o sistema UNA.

## Visão Geral

A arquitetura seguirá um padrão de camadas, comumente encontrado em aplicações Phoenix, promovendo a separação de responsabilidades:

1.  **Camada Web (Phoenix Controllers & Router):** Responsável por lidar com requisições HTTP, autenticação/autorização básica, validação de entrada, e formatação de respostas JSON.
2.  **Camada de Contexto/Serviço (Módulos Elixir):** Contém a lógica de negócios principal. Orquestra chamadas aos módulos de acesso a dados (Repos) e executa operações mais complexas.
3.  **Camada de Acesso a Dados (Repositórios - Módulos Elixir):** Responsável pela interação direta com o banco de dados SQLite, executando queries SQL manuais através da camada `Deeper.Core.Data.Repo` (que usa `DBConnection`).
4.  **Camada Core/Dados (Módulo `Deeper.Core.Data`):** Fornece a abstração de baixo nível para conexão com o banco de dados e execução de migrações.

+-----------------------------+       +-----------------------------+       +-----------------------------+
|      Cliente (Browser,      |------>|   Camada Web (Phoenix)      |<----->| Camada de Contexto/Serviço  |<----->+-----------------------------+
|      Mobile, etc.)          |       | - Router.ex                 |       | - Deeper.Accounts (Contexto)  |       | Camada de Acesso a Dados  |
+-----------------------------+       | - Controllers (AccountCtrl) |       | - Deeper.Content (Contexto) |       | - Deeper.SystemCore.AccountsRepo |
                                      | - Views (JSON Rendering)    |       |   - Lógica de Negócios    |       | - Deeper.Content.ArticlesRepo  |
                                      | - Plugs (Auth, CORS)        |       |   - Orquestração          |       |   - SQL Direto              |
                                      +-----------------------------+       +-----------------------------+       +-----------------------------+
                                                                                                                      |
                                                                                                                      V
                                                                                                        +-----------------------------+
                                                                                                        | Camada Core/Dados           |
                                                                                                        | - Deeper.Core.Data.Repo     |
                                                                                                        | - Deeper.Core.Data.Migrations|
                                                                                                        | - DBConnection Pool         |
                                                                                                        +-----------------------------+
                                                                                                                      |
                                                                                                                      V
                                                                                                        +-----------------------------+
                                                                                                        |      Banco de Dados         |
                                                                                                        |        (SQLite)             |
                                                                                                        +-----------------------------+