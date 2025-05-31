# Documentação Deeper Studio API: Informações do Servidor/Sistema

Este documento descreve os endpoints da API de Administração (\"Studio API\") para obter informações sobre o ambiente do servidor, o estado da aplicação \"Deeper\", e suas dependências.

**Objetivo Principal:** Fornecer aos administradores uma visão geral do ambiente de execução para diagnóstico e monitoramento.

## Tipos de Informação a Serem Expostas:

*   **Versões de Software:** Versão do Elixir, Erlang/OTP, Phoenix, principais dependências, versão da aplicação \"Deeper\".
*   **Informações do Sistema Operacional:** Nome do SO, versão (com cuidado para não expor muita informação sensível).
*   **Informações da VM Erlang/OTP:** Uptime, contagem de processos, uso de memória (geral).
*   **Status da Conexão com o Banco de Dados:** Se a conexão está ativa, tipo de SGBD (SQLite).
*   **Configurações Chave da Aplicação (Não Sensíveis):** Ex: modo de ambiente (dev, prod), URL base da API.

## Módulos/Bibliotecas Elixir para Coleta de Informações:

*   `System.version/0`, `System.otp_release/0`, `:erlang.system_info(:otp_release)`.
*   `Application.spec(:my_app, :vsn)` para a versão da aplicação \"Deeper\".
*   `Mix.Project.config()[:deps]` para listar dependências (se executando em ambiente Mix, pode não ser ideal para produção). Uma lista mantida de dependências chave pode ser melhor.
*   `:erlang.system_info(:system_version)`, `:os.type()`, `:os.version()`.
*   `:erlang.system_info(:process_count)`, `:erlang.memory()`.
*   Funções do `Deeper.Core.Data.Repo` para verificar o status da conexão DB.

## Endpoints da API de Admin para Informações do Sistema (`/api/v1/admin/system/info`):

### 1. Obter Informações Consolidadas do Sistema

*   **Endpoint:** `GET /api/v1/admin/system/info`
*   **Autenticação:** Requer JWT de Admin.
*   **Resposta de Sucesso (200 OK):**

```json
    {
      \"data\": {
        \"application\": {
          \"name\": \"Deeper API\",
          \"version\": \"1.0.0\", // Da config da app
          \"environment\": \"production\" // Da config da app
        },
        \"elixir_otp\": {
          \"elixir_version\": \"1.15.0\",
          \"otp_version\": \"26.0\"
        },
        \"server_os\": { // Com cautela sobre o que expor
          \"type\": \"linux\", // Exemplo
          \"release\": \"Ubuntu 22.04 LTS\" // Exemplo
        },
        \"erlang_vm\": {
          \"uptime_seconds\": 360000,
          \"process_count\": 500,
          \"memory_total_bytes\": 104857600, // Exemplo
          \"memory_used_bytes\": 60000000  // Exemplo
        },
        \"database\": {
          \"status\": \"connected\",
          \"type\": \"SQLite\",
          \"version\": \"3.39.0\" // Versão do SQLite
        },
        \"key_dependencies\": [ // Lista mantida, não dinâmica de todas as deps
          {\"name\": \"Phoenix Framework\", \"version\": \"1.7.0\"},
          {\"name\": \"DBConnection\", \"version\": \"2.5.0\"}
        ],
        \"current_timestamp_utc\": \"2023-10-28T12:00:00Z\"
      }
    }
```

*   **Lógica do Backend:** Um controller/serviço coleta todas essas informações de várias fontes do sistema Elixir/OTP e do `Repo`.

## Considerações:

*   **Segurança:** Cuidado para não expor informações excessivamente detalhadas ou sensíveis sobre o sistema operacional ou a configuração do servidor que possam ser exploradas. As informações devem ser de alto nível e úteis para diagnóstico.
*   **Dependências:** Listar todas as dependências pode ser verboso. Listar apenas as \"chave\" ou principais pode ser mais útil.
*   **Uso de Memória:** Os valores de memória da VM Erlang podem ser complexos de interpretar (`:erlang.memory/0` retorna uma lista de tuplas). A API deve fornecer um resumo compreensível.

Esta API de informações do sistema ajuda os administradores a entenderem o estado e o ambiente da aplicação \"Deeper\".