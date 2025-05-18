# Diretrizes de Desenvolvimento Elixir para o Projeto DeeperHub (Guia para IA)

## 1. Introdução

Este documento serve como um guia para o desenvolvimento de software Elixir no projeto DeeperHub, especialmente quando assistido por uma Inteligência Artificial. O objetivo é garantir a produção de código de alta qualidade, manutenível, robusto e que siga as melhores práticas da linguagem Elixir e da plataforma OTP.

**Responda sempre em Português do Brasil.**

## 2. Filosofia de Desenvolvimento

Adote as seguintes filosofias e princípios:

*   **OTP (Open Telecom Platform):**
    *   **Concorrência:** Utilize processos leves (`Task`, `Agent`, `GenServer`) para máxima concorrência e escalabilidade.
    *   **Tolerância a Falhas:** Projete com árvores de supervisão ("let it crash"). Supervisores devem reiniciar componentes problemáticos.
    *   **Distribuição:** Esteja preparado para construir sistemas distribuídos, se a necessidade surgir.
*   **Programação Funcional:**
    *   **Imutabilidade:** Dados são imutáveis.
    *   **Funções Puras:** Prefira funções sem efeitos colaterais.
    *   **Composição:** Construa funcionalidades complexas compondo funções menores, usando o operador pipe (`|>`).
*   **Explicitude e Clareza:** O código deve ser fácil de ler e entender. Evite "mágica" excessiva.
*   **Resolução de Erros:** **NUNCA** simplifique erros após uma tentativa de desenvolvimento falhar. Esforce-se para identificar a causa raiz, resolver o problema e garantir que a funcionalidade opere corretamente. Consulte o arquivo `Debug.md` para evitar erros já conhecidos.

## 3. Estrutura do Projeto e Nomenclatura

Siga esta estrutura para organizar o código:

*   **Raiz dos Módulos da Aplicação:** `lib/deeper_hub/`
*   **Categorias de Módulos (Primeiro Nível):**
    *   Dentro de `lib/deeper_hub/`, crie diretórios para as principais categorias funcionais do sistema.
    *   Exemplos: `core/`, `accounts/`, `data_access/`, `web_interface/`, `services/`.
    *   Estrutura: `lib/deeper_hub/<categoria>/`
*   **Módulos Principais (Subdiretórios):**
    *   Dentro de cada diretório de categoria, crie subdiretórios para cada módulo principal ou contexto.
    *   O nome do subdiretório deve corresponder à parte final do nome do módulo Elixir.
    *   Exemplo: Para o módulo `DeeperHub.Core.Log`, a estrutura será `lib/deeper_hub/core/log/`.
    *   Arquivos Elixir relacionados a este módulo (e.g., `logger.ex`, `formatter.ex`) residirão diretamente dentro deste diretório.
*   **Submódulos:**
    *   Se um módulo principal tiver submódulos logicamente agrupados, crie diretórios adicionais dentro do diretório do módulo principal.
    *   Exemplo: Para `DeeperHub.Core.Log.Sinks.FileSink`, a estrutura seria `lib/deeper_hub/core/log/sinks/file_sink.ex`.
*   **Nomenclatura de Arquivos:**
    *   Use `snake_case` para nomes de arquivos (e.g., `user_service.ex`, `cache_manager.ex`).
*   **Nomenclatura de Módulos Elixir:**
    *   Use `PascalCase` (e.g., `DeeperHub.Core.Log`, `DeeperHub.Accounts.User`).

## 4. Construção de Código

*   **Módulos e Funções:**
    *   **Coesão:** Módulos com propósito único e bem definido.
    *   **Tamanho:** Funções curtas, fazendo uma única coisa.
    *   **Nomes:** Descritivos para módulos, funções e variáveis.
    *   **Privacidade:** Use `defp` para funções auxiliares internas ao módulo.
*   **Structs (`defstruct`):** Use para estruturas de dados com campos conhecidos.
*   **Pattern Matching:** Utilize extensivamente em cabeçalhos de função, `case`, `with`, e atribuições.
*   **Guard Clauses (`when`):** Para adicionar condições ao pattern matching.
*   **`with` Statement:** Para sequências de operações que podem falhar, evitando `case` aninhados.
*   **Tratamento de Erros:**
    *   Padrão: `{:ok, value}` e `{:error, reason}`.
    *   Exceções: Para erros verdadeiramente excepcionais, não para controle de fluxo.
*   **Documentação:**
    *   `@moduledoc`: Para todos os módulos.
    *   `@doc`: Para todas as funções públicas.
    *   Inclua exemplos executáveis (doctests) sempre que possível.
*   **Testes (ExUnit):**
    *   Escreva testes abrangentes: unidade, integração.
    *   Doctests são uma forma de teste.
*   **Concorrência:**
    *   `Task`: Para operações concorrentes de curta duração.
    *   `Agent`: Para gerenciar estado simples concorrentemente.
    *   `GenServer`: Para lógica de servidor mais complexa e estado.
*   **Limite de Linhas por Arquivo:**
    *   Mantenha arquivos com aproximadamente **300 linhas no máximo**.
    *   Se um arquivo exceder este limite, avalie a divisão em múltiplos arquivos ou submódulos, agrupados por funcionalidade específica.
*   **Foco no Essencial:**
    *   Crie **somente** módulos, funções e funcionalidades que o sistema efetivamente utilizará.
    *   Evite código extra, "over-engineering" ou funcionalidades "para o futuro" que não tenham uma demanda imediata. O objetivo é um sistema enxuto e otimizado.
*   **Coesão e Baixo Acoplamento:**
    *   Garanta que os módulos sejam bem relacionados, mas com o menor acoplamento possível. Interfaces claras entre contextos/módulos são cruciais.

## 5. Template de Módulo Elixir

Use o seguinte template como base para a criação de novos módulos. Adapte conforme a necessidade (e.g., se for um `GenServer`, `Supervisor`, ou um módulo simples).

```elixir
# lib/deeper_hub/categoria/nome_do_modulo/arquivo_principal.ex
defmodule DeeperHub.Categoria.NomeDoModulo do
  @moduledoc """
  Descrição concisa do que este módulo faz.
  Este módulo é responsável por [objetivo principal].

  Ele interage com [outros módulos/contextos, se aplicável] e gerencia [tipos de dados/recursos].
  """

  # import ModuloExternoOuHelper, only: [funcao_especifica: 1]
  # alias DeeperHub.OutraCategoria.OutroModulo

  # @behaviour MeuComportamento # Se estiver implementando um comportamento

  @typedoc """
  Descrição do tipo principal que este módulo manipula ou define.
  """
  # @type t :: %__MODULE__{
  #         id: String.t() | nil,
  #         name: String.t(),
  #         created_at: DateTime.t() | nil,
  #         # ... outros campos
  #       }

  # defstruct id: nil,
  #           name: "",
  #           created_at: nil
            # ... outros campos com valores padrão

  @doc """
  Descrição da função pública.
  Recebe [parâmetros] e retorna [resultado ou {:ok, resultado} / {:error, razao}].

  ## Examples

      iex> DeeperHub.Categoria.NomeDoModulo.funcao_publica(argumento)
      :resultado_esperado_ou_ok_tupla

  """
  @spec funcao_publica(tipo_parametro :: any()) :: {:ok, any()} | {:error, atom() | String.t()} | any()
  def funcao_publica(parametro) do
    # Lógica da função
    processar_internamente(parametro)
  end

  # --- Funções Privadas ---

  @doc false
  # @specp processar_internamente(tipo_parametro :: any()) :: {:ok, any()} | {:error, atom()}
  defp processar_internamente(parametro) do
    # Lógica interna
    {:ok, "Resultado para: #{inspect(parametro)}"}
  end

  # Se for um GenServer, adicione callbacks:
  # --- GenServer Callbacks ---
  # @impl GenServer
  # def init(args) do
  #   {:ok, %{}} # Estado inicial
  # end

  # @impl GenServer
  # def handle_call(:minha_chamada, _from, state) do
  #   reply = {:ok, "resposta"}
  #   {:reply, reply, state}
  # end

  # @impl GenServer
  # def handle_cast({:meu_cast, dados}, state) do
  #   # Processar dados
  #   new_state = Map.put(state, :dados, dados)
  #   {:noreply, new_state}
  # end
end
```

## 6. Processo de Revisão e Qualidade

**Após concluir a implementação ou modificação de CADA arquivo, realize uma revisão rigorosa seguindo os pontos abaixo:**

1.  **Remover código não utilizado:**
    *   Variáveis declaradas mas não utilizadas.
    *   Funções (`def` ou `defp`) definidas mas nunca chamadas (verifique chamadas locais e de outros módulos, se aplicável).
    *   Importações (`import`) e aliases (`alias`) não utilizados.
    *   Parâmetros de funções que não são utilizados no corpo da função (considere se o parâmetro é realmente necessário ou se a assinatura da função pode ser simplificada).

2.  **Verificar implementações incompletas:**
    *   Funções declaradas (assinatura existe) mas não implementadas (corpo faltando ou apenas `raise "Not implemented"`).
    *   Chamadas a funções que não existem (verifique typos e disponibilidade das funções).
    *   Comentários `TODO:`, `FIXME:`, ou similares deixados no código que indicam trabalho pendente.
    *   Implementações parciais de interfaces ou comportamentos (`@behaviour`). Garanta que todos os callbacks obrigatórios estão implementados.

3.  **Corrigir problemas de tipagem (se usando `@spec`):**
    *   Especificações de tipo (`@spec`) incorretas ou incompletas para funções públicas e privadas (`@specp`).
    *   Tipos de retorno de função incompatíveis com a especificação declarada.
    *   Parâmetros passados para funções com tipos incorretos, ou tipos de parâmetros nas especificações que não correspondem à lógica da função.

4.  **Eliminar avisos de compilação e análise estática:**
    *   Resolva **todos** os warnings emitidos pelo compilador Elixir (`mix compile`).
    *   Corrija quaisquer problemas de depreciação indicados.
    *   Se o Dialyzer estiver configurado, elimine todos os seus avisos.

**Checklist Rápido Pós-Implementação/Modificação:**

Use esta checklist após cada implementação ou correção significativa:

- [ ] Todas as variáveis declaradas são utilizadas?
- [ ] Todos os `import` e `alias` são necessários e utilizados?
- [ ] Todos os parâmetros de todas as funções são utilizados dentro delas?
- [ ] Todas as funções declaradas (especialmente as públicas e callbacks) estão completamente implementadas?
- [ ] Não existem chamadas a funções inexistentes ou com typos?
- [ ] Todas as especificações de tipo (`@spec`) estão corretas e consistentes com a implementação?
- [ ] O comando `mix compile` executa sem NENHUM warning?
- [ ] O código está formatado corretamente (execute `mix format`)?
- [ ] Os testes (novos ou existentes) cobrem todas as funcionalidades implementadas/modificadas e estão passando?
- [ ] A documentação (`@moduledoc`, `@doc`) está atualizada e reflete a implementação atual, incluindo exemplos?

**Consulta ao `Debug.md`:**
Antes de iniciar uma nova tarefa de desenvolvimento ou correção, **consulte o arquivo `Debug.md`** na raiz do projeto. Ele contém um histórico de erros já encontrados e suas soluções, ajudando a evitar a repetição de problemas.


***IMPORTANTE*** Execute comandos para o prompt do widnows e antes de criar um arquivo dentro de uma pasta que não existe execute um comando no prommt do windows para a criação da pasta

***IMPORTANTE*** Nunca use mock para testes

***IMPORTANTE*** todas as vezes antes de criar um arquivo precisa verificar se já nao existe o diretorio e executar um comando prompt do widnows para criação do diretorio caso nao exista
