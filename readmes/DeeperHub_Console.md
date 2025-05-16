# Módulo: `Deeper_Hub.Console` 💻

## 📜 1. Visão Geral do Módulo `Deeper_Hub.Console`

O módulo `Deeper_Hub.Console` fornece uma interface de linha de comando (CLI) interativa e baseada em scripts para administrar, monitorar e interagir com o sistema Deeper_Hub. Ele é projetado para desenvolvedores, administradores de sistema e equipes de operações para executar tarefas administrativas, diagnósticos, gerenciamento de configuração e outras operações que não são tipicamente expostas através da UI principal ou API. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Execução de Comandos:**
    *   Permitir o registro e execução de comandos customizados (ex: `users:list`, `cache:clear`, `db:migrate`).
    *   Parsing de argumentos e opções para comandos.
*   **Sessão Interativa (REPL-like):**
    *   Fornecer um shell interativo para executar comandos.
    *   Histórico de comandos.
    *   Autocompletar comandos e argumentos (opcional).
*   **Execução de Scripts:**
    *   Capacidade de executar sequências de comandos a partir de um arquivo de script.
*   **Gerenciamento de Comandos:**
    *   Listar comandos disponíveis.
    *   Exibir ajuda detalhada para cada comando, incluindo uso, argumentos e opções.
*   **Saída Formatada:**
    *   Apresentar a saída dos comandos de forma legível (texto simples, tabelas, JSON, etc.).
*   **Controle de Acesso (Integração com RBAC):**
    *   Verificar se o usuário (ou contexto de execução) tem permissão para executar um comando específico, integrando-se com `Deeper_Hub.RBAC`.
*   **Auditoria:**
    *   Registrar a execução de comandos (especialmente os críticos) no `Deeper_Hub.Audit`.
*   **Configuração:**
    *   Permitir a configuração do prompt, tamanho do histórico, etc.
*   **Notificações (Opcional):**
    *   Notificar administradores sobre a execução de comandos críticos.
*   **Extensibilidade:**
    *   Facilitar a adição de novos comandos por outros módulos da aplicação.

## 🏗️ 3. Arquitetura e Design

O `Deeper_Hub.Console` atuará como um orquestrador para o processamento de comandos.

*   **Interface Pública (`Deeper_Hub.Console.ConsoleFacade` ou `Deeper_Hub.Console`):** Ponto de entrada para iniciar o console interativo, executar scripts ou comandos programaticamente.
*   **Registro de Comandos (`Deeper_Hub.Console.Services.CommandRegistry`):** Um GenServer ou ETS para manter uma lista de todos os comandos registrados, seus metadados e os módulos que os implementam.
*   **Executor de Comandos (`Deeper_Hub.Console.Services.CommandRunner`):** Responsável por parsear a entrada, encontrar o comando no registro, verificar permissões e executar o comando.
*   **Comportamento de Comando (`Deeper_Hub.Console.CommandBehaviour`):** Um comportamento que todos os módulos de comando devem implementar (ex: `run/2`, `help/0`, `options/0`).
*   **Módulos de Comando Específicos (ex: `Deeper_Hub.Console.Commands.UserCommands`, `Deeper_Hub.Console.Commands.CacheCommands`):** Implementam a lógica para comandos específicos.
*   **Serviço de Saída (`Deeper_Hub.Console.Services.OutputService`):** Formata e exibe a saída dos comandos.
*   **Integrações:**
    *   `Deeper_Hub.RBAC`: Para verificar permissões de execução de comandos.
    *   `Deeper_Hub.Audit`: Para logar a execução de comandos.
    *   `Deeper_Hub.Core.ConfigManager`: Para configurações do console.
    *   `Deeper_Hub.Notifications` (Opcional): Para alertar sobre comandos críticos.

**Padrões de Design:**

*   **Command:** Encapsula uma solicitação como um objeto, permitindo parametrizar clientes com diferentes solicitações, enfileirar ou logar solicitações, e suportar operações que podem ser desfeitas.
*   **Registry:** Para gerenciar os comandos disponíveis.
*   **Facade:** Para simplificar a interface do console.

### 3.1. Componentes Principais

*   **`Deeper_Hub.Console.ConsoleFacade`:** Ponto de entrada.
*   **`Deeper_Hub.Console.Services.CommandRegistry`:** Gerencia os comandos disponíveis.
*   **`Deeper_Hub.Console.Services.CommandRunner`:** Executa os comandos.
*   **`Deeper_Hub.Console.CommandBehaviour`:** Contrato para módulos de comando.
*   **Módulos em `Deeper_Hub.Console.Commands.*`:** Implementações de comandos.
*   **`Deeper_Hub.Console.Config.ConsoleConfig`:** Gerencia configurações do console.
*   **`Deeper_Hub.Console.Integrations.*`:** Módulos para integração com Auditoria, Notificações.
*   **`Deeper_Hub.Console.Supervisor`:** Supervisiona os processos do console.

### 3.3. Decisões de Design Importantes

*   **Descoberta de Comandos:** Como os comandos são descobertos e registrados (ex: manual, automático via macros ou introspecção).
*   **Parsing de Argumentos:** Escolha de uma biblioteca ou implementação customizada para parsear argumentos e opções da linha de comando.
*   **Interatividade vs. Scripting:** Garantir que a execução de comandos funcione bem tanto em modo interativo quanto em scripts.

## 🛠️ 4. Casos de Uso Principais

*   **Desenvolvedor Inicia Sessão Interativa:** Um desenvolvedor inicia `iex -S mix` e depois `Deeper_Hub.Console.start_interactive()` para acessar o console.
*   **Administrador Lista Usuários Ativos:** No console interativo, o admin digita `user:list --status active --limit 10`.
*   **Script de Manutenção Limpa Cache:** Um script `maintenance.exs` contém `Deeper_Hub.Console.execute(\"cache:clear\", [\"all\"])` e é executado via `mix run priv/scripts/maintenance.exs`.
*   **Operador Verifica Status de um Serviço:** No console, digita `service:status --name auth_service`.
*   **Desenvolvedor Registra Novo Comando:** Cria um módulo que implementa `CommandBehaviour` e o registra usando `Deeper_Hub.Console.register_command(MyNewCommandModule)`.

## 🌊 5. Fluxos Importantes (Opcional)

**Fluxo de Execução de um Comando Interativo:**

1.  Usuário digita um comando (ex: `user:get --id 123`) no prompt do console interativo.
2.  O loop do console interativo captura a entrada.
3.  A entrada é passada para `Deeper_Hub.Console.Services.CommandRunner.execute_line(input_string)`.
4.  `CommandRunner` parseia a `input_string` para identificar o nome do comando (`user:get`), argumentos e opções (`--id 123`).
5.  `CommandRunner` consulta `Deeper_Hub.Console.Services.CommandRegistry.find_command(\"user:get\")` para obter o módulo handler do comando.
6.  Se o comando for encontrado, `CommandRunner` (ou um subcomponente de autorização) verifica as permissões do usuário atual (contexto do console) para executar este comando, consultando `Deeper_Hub.RBAC`.
7.  Se autorizado, o evento de tentativa de execução é logado no `Deeper_Hub.Audit`.
8.  `CommandRunner` chama a função `run/2` do módulo handler do comando (ex: `Deeper_Hub.Console.Commands.UserCommands.run(\"get\", %{id: \"123\"})`).
9.  O módulo do comando executa sua lógica, interagindo com outras fachadas do sistema (ex: `Deeper_Hub.Accounts.get_user(\"123\")`).
10. O comando retorna um resultado (ex: `{:ok, user_data}` ou `{:error, \"Usuário não encontrado\"}`).
11. `CommandRunner` recebe o resultado.
12. O resultado da execução (sucesso/falha, dados de retorno) é logado no `Deeper_Hub.Audit`.
13. O resultado é formatado por `Deeper_Hub.Console.Services.OutputService` e exibido para o usuário.
14. O loop do console interativo aguarda a próxima entrada.

## 📡 6. API (Se Aplicável)

### 6.1. `Deeper_Hub.Console.execute/3` (Programático)

*   **Descrição:** Executa um comando do console programaticamente.
*   **`@spec`:** `execute(command_name :: String.t(), args :: list(String.t()), opts :: Keyword.t() | map()) :: {:ok, result :: any()} | {:error, reason :: any()}`
*   **Parâmetros:**
    *   `command_name` (String): O nome completo do comando (ex: `\"user:list\"`).
    *   `args` (list(String)): Lista de argumentos posicionais para o comando.
    *   `opts` (Keyword.t() | map()): Opções nomeadas para o comando (ex: `[status: \"active\"]` ou `%{status: \"active\"}`).
*   **Retorno:**
    *   `{:ok, result}`: Se o comando for executado com sucesso, `result` é a saída do comando.
    *   `{:error, reason}`: Se ocorrer um erro (comando não encontrado, falha na execução, permissão negada).
*   **Exemplo de Uso (Elixir):**
    ```elixir
    case Deeper_Hub.Console.execute(\"user:list\", [], status: \"inactive\", limit: 5) do
      {:ok, users_string} -> IO.puts(users_string)
      {:error, err} -> Logger.error(\"Falha ao executar comando do console: #{inspect(err)}\")
    end
    ```

### 6.2. `Deeper_Hub.Console.start_interactive/1`

*   **Descrição:** Inicia uma sessão de console interativo.
*   **`@spec`:** `start_interactive(opts :: Keyword.t()) :: :ok | no_return()`
*   **Parâmetros:**
    *   `opts` (Keyword.t()): Opções para a sessão interativa.
        *   `:user_id` (String): ID do usuário para contexto de permissão (opcional).
*   **Retorno:** Geralmente não retorna, pois entra em um loop de leitura de comandos. Retorna `:ok` se conseguir iniciar.
*   **Exemplo de Uso (IEx):**
    ```iex
    iex> Deeper_Hub.Console.start_interactive(user_id: \"admin_user\")
    Deeper_Hub Console (admin_user) > help
    ...
    Deeper_Hub Console (admin_user) > exit
    :ok
    ```

## ⚙️ 7. Configuração

*   **ConfigManager (`Deeper_Hub.Core.ConfigManager`):**
    *   `[:console, :prompt_template]`: Template para o prompt interativo (ex: `\"Deeper_Hub (#{user_id}) > \"`). (Padrão: `\"Deeper_Hub > \"`)
    *   `[:console, :history_size]`: Número de comandos a serem mantidos no histórico da sessão interativa. (Padrão: `100`)
    *   `[:console, :default_output_format]`: Formato padrão para a saída dos comandos (:text, :json). (Padrão: `:text`)
    *   `[:console, :log_command_execution]`: (Boolean) Se deve auditar a execução de todos os comandos. (Padrão: `true`)
    *   `[:console, :critical_commands_notify_list]`: Lista de emails/canais para notificar sobre execução de comandos críticos.

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `Deeper_Hub.Core.ConfigManager`: Para configurações.
*   `Deeper_Hub.Core.Logger`: Para logging.
*   `Deeper_Hub.Audit`: Para registrar a execução de comandos.
*   `Deeper_Hub.RBAC`: Para verificar permissões de execução de comandos.
*   `Deeper_Hub.Notifications` (Opcional): Para notificar sobre comandos críticos.
*   Todos os módulos que expõem comandos (ex: `Deeper_Hub.Accounts`, `Deeper_Hub.Cache.CacheFacade` se tiver comando `cache:clear`).

### 8.2. Bibliotecas Externas

*   Opcionalmente, bibliotecas para parsing de argumentos de CLI mais robusto (ex: `Optimist`).
*   Opcionalmente, bibliotecas para formatação de tabelas em modo texto (ex: `TableRex`).

## 🤝 9. Como Usar / Integração

*   **Para Desenvolvedores/Admins:** Iniciar via `Deeper_Hub.Console.start_interactive()`.
*   **Para Scripts:** Usar `Deeper_Hub.Console.execute/3`.
*   **Para Adicionar Novos Comandos:**
    1.  Criar um módulo que implemente `Deeper_Hub.Console.CommandBehaviour`.
    2.  Registrar o comando durante a inicialização da aplicação ou do módulo:
        ```elixir
        # Em application.ex ou no start/2 de um supervisor do módulo
        Deeper_Hub.Console.register_command(MeuModulo.MeuComando)
        ```

**Exemplo de um Módulo de Comando:**
```elixir
defmodule Deeper_Hub.Console.Commands.MySampleCommand do
  @behaviour Deeper_Hub.Console.CommandBehaviour

  @impl Deeper_Hub.Console.CommandBehaviour
  def name, do: \"sample:hello\"

  @impl Deeper_Hub.Console.CommandBehaviour
  def description, do: \"Um comando de exemplo que diz olá.\"

  @impl Deeper_Hub.Console.CommandBehaviour
  def usage, do: \"sample:hello [nome]\"

  @impl Deeper_Hub.Console.CommandBehaviour
  def options, do: [
    # switches: [debug: :boolean],
    # aliases: [d: :debug]
  ]

  @impl Deeper_Hub.Console.CommandBehaviour
  def run(args, _opts) do
    # args é uma lista de strings
    # opts é um mapa de opções parseadas
    name = List.first(args) || \"Mundo\"
    output = \"Olá, #{name}!\"
    {:ok, output}
  end
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testar o registro e descoberta de comandos.
*   Testar o parsing de argumentos e opções para diferentes comandos.
*   Testar a execução de comandos com sucesso e falha.
*   Testar a verificação de permissões (RBAC).
*   Testar a formatação de saída.
*   Localização: `test/deeper_hub/console/`

### 10.2. Métricas

*   `deeper_hub.console.command.executed.count` (Contador): Número de comandos executados. Tags: `command_name`, `status` (ok/error).
*   `deeper_hub.console.command.execution.duration_ms` (Histograma): Duração da execução de comandos. Tags: `command_name`.
*   `deeper_hub.console.permission_denied.count` (Contador): Número de tentativas de execução de comando negadas por permissão. Tags: `command_name`, `user_id`.

### 10.3. Logs

*   `Logger.info(\"Comando '#{cmd}' executado por '#{user_id}' com args: #{inspect(args)}, opts: #{inspect(opts)}. Resultado: #{status}\", module: Deeper_Hub.Console.Services.CommandRunner)`
*   Logs de auditoria via `Deeper_Hub.Audit` para cada execução de comando.

### 10.4. Telemetria

*   `[:deeper_hub, :console, :command, :execute, :start | :stop | :exception]`: Para a execução de cada comando. Payload: `%{command_name: name, args: args, opts: opts, user_id: id}`.

## ❌ 11. Tratamento de Erros

*   Comandos não encontrados devem retornar uma mensagem clara.
*   Falhas na execução de comandos devem retornar `{:error, reason}` e a razão deve ser exibida ao usuário.
*   Tentativas de execução sem permissão devem ser bloqueadas e logadas.

## 🛡️ 12. Considerações de Segurança

*   **Controle de Acesso:** A integração com RBAC é fundamental. Comandos que realizam operações sensíveis devem ter permissões estritas.
*   **Auditoria:** Todas as execuções de comandos, especialmente os que modificam dados ou configurações, devem ser auditadas.
*   **Validação de Entrada:** Mesmo sendo uma interface interna, os argumentos e opções dos comandos devem ser validados para evitar comportamento inesperado.
*   **Exposição de Dados Sensíveis:** A saída dos comandos deve ter cuidado para não expor dados sensíveis desnecessariamente. Usar o `Deeper_Hub.Security.DataMasking` se necessário.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novos comandos, siga o `CommandBehaviour`.
*   Garanta que a ajuda do comando (`usage`, `description`, `options`) seja clara e completa.
*   Adicione verificações de permissão (RBAC) apropriadas para novos comandos.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Implementar autocompletar para comandos e argumentos no modo interativo.
*   [ ] Suporte para subcomandos (ex: `user admin add ...`).
*   [ ] Permitir que comandos gerem saída em formatos diferentes (JSON, YAML) via uma opção `--format`.
*   [ ] Melhorar o tratamento de erros e a exibição de stack traces no console.
*   [ ] Adicionar um comando `console:history` para ver o histórico de comandos da sessão.

---

*Última atualização: YYYY-MM-DD*

---

Próximo: `Deeper_Hub.Biometrics`?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue
"""),
                types.Part.from_text(text="""continue
"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, vamos para o README do `Deeper_Hub.Biometrics`. Este é um módulo interessante e com bastante potencial!

---

