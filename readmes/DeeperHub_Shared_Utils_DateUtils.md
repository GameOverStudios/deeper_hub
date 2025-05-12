# Módulo: `DeeperHub.Shared.Utils.DateUtils` 🚀

## 📜 1. Visão Geral do Módulo `DeeperHub.Shared.Utils.DateUtils`

O módulo `DeeperHub.Shared.Utils.DateUtils` fornece um conjunto de funções utilitárias para **manipulação, cálculo e formatação de datas e horas** no sistema DeeperHub. Ele visa simplificar operações comuns relacionadas ao tempo, como adicionar ou subtrair intervalos, calcular diferenças entre datas, formatar datas para exibição e verificar se uma data está dentro de um determinado período.

Este módulo utiliza as estruturas de data e hora nativas do Elixir (`Date`, `Time`, `NaiveDateTime`, `DateTime`) e bibliotecas de calendário para fornecer funcionalidades robustas e conscientes de fuso horário quando necessário. 😊

## 🎯 2. Responsabilidades e Funcionalidades Chave

*   **Manipulação de Datas/Horas:**
    *   Adicionar ou subtrair unidades de tempo (segundos, minutos, horas, dias, semanas, meses, anos) a uma data/hora (`add/3`).
    *   Obter o início ou fim de um período (dia, semana, mês, ano) para uma data/hora específica.
*   **Cálculo de Diferenças:**
    *   Calcular a diferença entre duas datas/horas em uma unidade específica (`diff/3`).
*   **Formatação de Datas/Horas:**
    *   Formatar `DateTime`, `NaiveDateTime`, ou `Date` em strings legíveis usando formatos predefinidos (curto, médio, longo) ou customizados (`format_datetime/3`).
    *   Formatar durações (em segundos ou outra unidade) em strings amigáveis (ex: \"1h 10m\", \"2 dias e 3 horas\") (`format_duration/2`).
*   **Verificação de Intervalos:**
    *   Verificar se uma data/hora está entre duas outras datas/horas (`is_between/3`).
    *   Verificar se uma data/hora está no passado ou no futuro.
    *   Verificar se um período de tempo se sobrepõe a outro.
*   **Conversões e Utilitários de Fuso Horário (Timezone):**
    *   Converter `NaiveDateTime` para `DateTime` em um fuso horário específico (e vice-versa), se o sistema lidar com múltiplos fusos horários de forma explícita.
    *   Obter o fuso horário padrão da aplicação.
*   **Geração de Timestamps:**
    *   Fornecer funções convenientes para obter o timestamp atual em UTC ou em formatos específicos.

## 🏗️ 3. Arquitetura e Design

### 3.1. Componentes Principais

*   **`DeeperHub.Shared.Utils.DateUtils` (Módulo Funcional):**
    *   Contém todas as funções de utilidade para datas e horas.
    *   Utiliza os módulos `Date`, `Time`, `NaiveDateTime`, `DateTime` do Elixir.
    *   Pode usar bibliotecas como `Calendar` ou `Timex` para funcionalidades mais avançadas de manipulação de calendário e fuso horário se as funções nativas não forem suficientes.

### 3.2. Estrutura de Diretórios

```
lib/deeper_hub/shared/utils/date_utils.ex
```

### 3.3. Decisões de Design Importantes

*   **Consistência com Tipos Nativos:** Priorizar o uso e retorno dos tipos de data/hora nativos do Elixir (`Date`, `NaiveDateTime`, `DateTime`).
*   **Consciência de Fuso Horário:** Para operações que envolvem `DateTime`, ser explícito sobre fusos horários. Armazenar datas/horas no banco de dados preferencialmente em UTC e converter para o fuso horário do usuário apenas para exibição.
*   **Clareza da API:** Nomes de funções e parâmetros devem ser intuitivos.
*   **Imutabilidade:** Funções que modificam datas (como `add/3`) devem retornar uma nova estrutura de data/hora, não modificar a original.

## 🛠️ 4. Casos de Uso Principais

*   **Calcular Data de Expiração de um Token:**
    *   `token_creation_time = DateTime.utc_now()`
    *   `expiry_time = DateUtils.add(token_creation_time, 7, :day)`
*   **Exibir Data de Criação de um Post de Forma Amigável:**
    *   `formatted_date = DateUtils.format_datetime(post.inserted_at, :medium, user_locale)`
*   **Verificar se um Evento Agendado Já Começou:**
    *   `now = DateTime.utc_now()`
    *   `has_started = DateTime.compare(now, event.start_time) != :lt` (ou usando `is_between/3` de forma mais abstrata).
*   **Calcular Há Quanto Tempo um Comentário foi Postado:**
    *   `time_ago_in_seconds = DateUtils.diff(comment.inserted_at, DateTime.utc_now(), :seconds)`
    *   `friendly_time_ago = DateUtils.format_duration(time_ago_in_seconds, :short)` (ex: \"5m atrás\", \"2h atrás\")

## 🌊 5. Fluxos Importantes

Não aplicável (módulo funcional).

## 📡 6. API (Funções Públicas do Módulo)

*(Baseado na documentação original e expandindo)*

### 6.1. `DeeperHub.Shared.Utils.DateUtils.add(datetime :: Date.t() | NaiveDateTime.t() | DateTime.t(), amount :: integer(), unit :: :second | :minute | :hour | :day | :week | :month | :year) :: Date.t() | NaiveDateTime.t() | DateTime.t()`

*   **Descrição:** Adiciona uma quantidade de `unit` a `datetime`. Retorna o mesmo tipo que foi passado.
*   **Exemplo:** `DateUtils.add(DateTime.utc_now(), -3, :month)` (subtrai 3 meses).

### 6.2. `DeeperHub.Shared.Utils.DateUtils.diff(start_datetime, end_datetime, unit :: :second | :minute | :hour | :day | :week | :month | :year) :: float() | integer()`

*   **Descrição:** Calcula a diferença entre `end_datetime` e `start_datetime` na `unit` especificada.
*   Pode retornar float para unidades como `:hour` ou `:day` se houver frações.
*   **Exemplo:** `DateUtils.diff(~N[2023-01-01 10:00:00], ~N[2023-01-01 11:30:00], :minute)` -> `90`.

### 6.3. `DeeperHub.Shared.Utils.DateUtils.format_datetime(datetime, format_type :: :short | :medium | :long | :full | String.t(), locale :: String.t() \\\\ \"en\") :: String.t()`

*   **Descrição:** Formata `datetime` para uma string. `locale` pode ser \"pt-BR\", \"en-US\", etc. Se `format_type` for uma string, ela é usada como um formato customizado (ex: `\"{YYYY}-{0M}-{0D} {h24}:{0m}:{0s}\"`).
*   **Exemplo:** `DateUtils.format_datetime(DateTime.utc_now(), :long, \"pt-BR\")`.

### 6.4. `DeeperHub.Shared.Utils.DateUtils.format_duration(duration_seconds :: non_neg_integer(), format_type :: :short | :medium | :long | :human) :: String.t()`

*   **Descrição:** Formata uma duração em segundos para uma string legível.
    *   `:short`: \"1d 2h 3m 4s\"
    *   `:medium`: \"1 day, 2 hours, 3 minutes, 4 seconds\"
    *   `:long`: Similar a medium, mas pode ser mais verboso.
    *   `:human`: \"há 5 minutos\", \"em 2 horas\" (requer um ponto de referência, ou assume \"atrás\").
*   **Exemplo:** `DateUtils.format_duration(90061, :medium)` -> `\"1 day, 1 hour, 1 minute, 1 second\"` (aproximado).

### 6.5. `DeeperHub.Shared.Utils.DateUtils.is_between?(datetime_to_check, start_datetime, end_datetime, inclusive_ends :: boolean() \\\\ true) :: boolean()`

*   **Descrição:** Verifica se `datetime_to_check` está entre `start_datetime` e `end_datetime`.
*   **`inclusive_ends`:** Se `true`, os limites são inclusivos (`<=`, `>=`). Se `false`, exclusivos (`<`, `>`).

### 6.6. `DeeperHub.Shared.Utils.DateUtils.start_of(datetime, unit :: :day | :week | :month | :year) :: Date.t() | NaiveDateTime.t() | DateTime.t()` (Nova Sugestão)

*   **Descrição:** Retorna o início da unidade de tempo para a data/hora fornecida.
*   **Exemplo:** `DateUtils.start_of(~N[2023-05-12 15:30:00], :month)` -> `~N[2023-05-01 00:00:00]`.

### 6.7. `DeeperHub.Shared.Utils.DateUtils.end_of(datetime, unit :: :day | :week | :month | :year) :: Date.t() | NaiveDateTime.t() | DateTime.t()` (Nova Sugestão)

*   **Descrição:** Retorna o fim (último microssegundo) da unidade de tempo para a data/hora fornecida.
*   **Exemplo:** `DateUtils.end_of(~N[2023-05-12 15:30:00], :day)` -> `~N[2023-05-12 23:59:59.999999]`.

### 6.8. `DeeperHub.Shared.Utils.DateUtils.to_iso8601(datetime :: DateTime.t()) :: String.t()` (Nova Sugestão)

*   **Descrição:** Formata um `DateTime` para o padrão ISO8601 (ex: `\"2023-05-12T10:30:00.123Z\"`).

### 6.9. `DeeperHub.Shared.Utils.DateUtils.from_iso8601(iso_string :: String.t()) :: {:ok, DateTime.t()} | {:error, term()}` (Nova Sugestão)

*   **Descrição:** Parseia uma string ISO8601 para um `DateTime`.

### 6.10. `DeeperHub.Shared.Utils.DateUtils.utc_now_trimmed_to_second() :: DateTime.t()` (Nova Sugestão)

*   **Descrição:** Retorna `DateTime.utc_now()` com os microssegundos zerados, útil para comparações ou armazenamento.

## ⚙️ 7. Configuração

Este módulo geralmente não tem configurações complexas, mas poderia obter do `Core.ConfigManager`:
*   `[:shared, :utils, :date, :default_locale_for_formatting]` (String): Locale padrão para `format_datetime/3`. (Padrão: `\"en\"`)
*   `[:shared, :utils, :date, :default_timezone]` (String): Fuso horário padrão da aplicação (ex: `\"Etc/UTC\"`, `\"America/Sao_Paulo\"`). (Padrão: `\"Etc/UTC\"`)

## 🔗 8. Dependências

### 8.1. Módulos Internos

*   `DeeperHub.Core.ConfigManager` (opcional, para configurações padrão).

### 8.2. Bibliotecas Externas

*   `Calendar` (do Elixir): Usado internamente por `Date`, `DateTime`, etc.
*   `Timex` (opcional): Uma biblioteca popular para manipulação de datas e horas mais avançada, se as funcionalidades nativas não forem suficientes. No entanto, para os utilitários listados, a biblioteca padrão Elixir já oferece bastante.

## 🤝 9. Como Usar / Integração

Simplesmente chame as funções do módulo onde a manipulação de data/hora for necessária.
```elixir
alias DeeperHub.Shared.Utils.DateUtils

def token_expired?(token_created_at, ttl_days) do
  expiry_date = DateUtils.add(token_created_at, ttl_days, :day)
  DateTime.compare(DateTime.utc_now(), expiry_date) == :gt
end

def display_event_duration(start_time, end_time) do
  duration_seconds = DateUtils.diff(start_time, end_time, :second)
  DateUtils.format_duration(duration_seconds, :medium)
end
```

## ✅ 10. Testes e Observabilidade

### 10.1. Testes

*   Testes unitários para cada função com uma variedade de entradas, incluindo:
    *   Diferentes tipos de data/hora (`Date`, `NaiveDateTime`, `DateTime`).
    *   Casos de borda (ex: adicionar a um fim de mês, anos bissextos).
    *   Diferentes unidades e formatos.
    *   Valores `nil` ou inválidos (se a função os aceitar e tiver comportamento definido).
*   Localização: `test/deeper_hub/shared/utils/date_utils_test.exs`.

### 10.2. Métricas / 10.3. Logs / 10.4. Telemetria

Geralmente não aplicável para um módulo de utilitários puros, a menos que uma função específica seja identificada como crítica para performance e precise de instrumentação.

## ❌ 11. Tratamento de Erros

*   Funções devem levantar `ArgumentError` ou `FunctionClauseError` para tipos de entrada inválidos.
*   Funções de parsing (como `from_iso8601`) devem retornar `{:ok, value} | {:error, reason}`.
*   A documentação de cada função deve especificar seu comportamento de erro.

## 🛡️ 12. Considerações de Segurança

*   **Timezone:** A principal consideração é o manuseio correto de fusos horários. Confusões de fuso horário podem levar a bugs lógicos e, em alguns casos, a vulnerabilidades (ex: expiração incorreta de tokens ou sessões). Sempre que possível, trabalhe com `DateTime` em UTC internamente e converta para o fuso horário do usuário apenas na camada de apresentação.
*   **Entrada do Usuário:** Se datas/horas vierem de entrada do usuário, elas devem ser parseadas e validadas rigorosamente antes de serem usadas em cálculos.

## 🧑‍💻 13. Contribuição

*   Ao adicionar novas funções, garanta que elas lidem corretamente com os diferentes tipos de data/hora do Elixir e sejam conscientes de fusos horários se usarem `DateTime`.
*   Adicione testes unitários completos para todas as novas funcionalidades.

## 🔮 14. Melhorias Futuras e TODOs

*   [ ] Adicionar mais funções de conveniência (ex: `is_weekend?`, `days_in_month`, `next_business_day`).
*   [ ] Melhorar a função `format_duration` para suportar internacionalização (ex: \"1 dia\" vs \"1 day\").
*   [ ] Considerar a integração com `Timex` para funcionalidades de calendário mais complexas se necessário (ex: feriados, recorrências complexas).
*   [ ] Funções para calcular \"tempo relativo\" (ex: \"há 5 minutos\", \"amanhã\", \"na próxima semana\") de forma mais robusta e internacionalizada.

---

*Última atualização: 2025-05-12*

---

Os utilitários de data são sempre úteis!

Próximo? `MapUtils` ou `ListUtils` para continuar nos utilitários, ou podemos voltar para um módulo Core mais complexo como `DeeperHub.Core.BackgroundTaskManager` (que já começamos) ou `DeeperHub.Notifications`?"""),
            ],
        ),
        types.Content(
            role="user",
            parts=[
                types.Part.from_text(text="""continue"""),
            ],
        ),
        types.Content(
            role="model",
            parts=[
                types.Part.from_text(text="""Ok, já documentamos o `DeeperHub.Core.BackgroundTaskManager`.

Vamos então para outro módulo Core essencial: `DeeperHub.Notifications`. Este módulo é responsável por toda a comunicação proativa do sistema com os usuários.

---

