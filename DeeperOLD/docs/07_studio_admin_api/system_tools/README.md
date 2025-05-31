# Documentação Deeper Studio API: Ferramentas do Sistema

Este documento descreve os endpoints da API de Administração (\"Studio API\") para diversas ferramentas e utilitários do sistema. Estas ferramentas ajudam os administradores a manter a saúde da plataforma, diagnosticar problemas e realizar operações de manutenção.

**Objetivo Principal:** Fornecer aos administradores acesso programático a funcionalidades como limpeza de cache, visualização de informações do servidor, gerenciamento de tarefas agendadas (se aplicável), e potencialmente logs do sistema.

## Funcionalidades de Ferramentas do Sistema:

1.  [**Gerenciamento de Cache (`cache_management/`)**](./cache_management/README.md):
    *   Endpoints para limpar diferentes tipos de cache (ex: cache de templates, cache de DB, cache de configurações, cache de localização).

2.  [**Informações do Servidor/Sistema (`server_info/`)**](./server_info/README.md):
    *   Endpoint para obter informações sobre o ambiente do servidor Elixir/OTP, versões de dependências, status do banco de dados, etc.

3.  **(Opcional) Gerenciamento de Tarefas Agendadas (`cron_jobs/`)**:
    *   Se a API \"Deeper\" for gerenciar ou interagir com `sys_cron_jobs`, endpoints para listar, disparar ou ver o status de jobs. (Para uma API Elixir, isso pode ser mais integrado com ferramentas Elixir/OTP como `Quantum` ou processos supervisionados).

4.  **(Opcional) Visualização de Logs (`logs_viewer/`)**:
    *   Se a API \"Deeper\" tiver um sistema de logging acessível via API (além dos logs de console/arquivo padrão do Elixir).

## Abordagem Geral:

*   Os endpoints aqui são geralmente ações ou leituras de status, não necessariamente CRUDs em tabelas de configuração (exceto talvez para `sys_cron_jobs`).
*   Muitas dessas funcionalidades interagirão com mecanismos internos do Elixir/OTP ou com o estado da aplicação \"Deeper\".

---
### Gerenciamento de Cache

Vamos detalhar os endpoints para gerenciamento de cache.