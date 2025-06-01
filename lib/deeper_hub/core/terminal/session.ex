defmodule DeeperHub.Core.Terminal.Session do
  @moduledoc """
  Representa o estado de uma sessão de terminal interativo.
  """
  defstruct id: nil,
            port: nil, # O Port para o processo iex
            created_at: nil,
            last_command: nil,
            # Para o streaming, guardamos o PID do cliente que receberá os chunks
            client_pid: nil,
            # Referência ao timer de segurança do GenServer para esta sessão/comando
            safety_timer_ref: nil

  @type t :: %__MODULE__{
          id: String.t() | nil,
          port: port() | nil,
          created_at: DateTime.t() | nil,
          last_command: map() | nil,
          client_pid: pid() | nil,
          safety_timer_ref: reference() | nil
        }
end
