defmodule DeeperHub.Core.Data.Migrations.Seeds.BxAntispamDnsblRulesSeed do
  @moduledoc """
  Seed para a tabela bx_antispam_dnsbl_rules.
  Insere os registros iniciais na tabela.
  """

  alias DeeperHub.Core.Data.Repo

  @doc """
  Insere os registros na tabela.
  """
  def run do
    IO.puts("Inserindo registros na tabela bx_antispam_dnsbl_rules...")

        Repo.execute("INSERT INTO bx_antispam_dnsbl_rules (id, chain, zonedomain, postvresp, url, recheck, comment, added, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [1, "spammers", "sbl.spamhaus.org.", "any", "http://www.spamhaus.org/sbl/", "http://www.spamhaus.org/query/bl?ip=%s", "_bx_antispam_rule_note_spamhaus_org", 0, 1])
    Repo.execute("INSERT INTO bx_antispam_dnsbl_rules (id, chain, zonedomain, postvresp, url, recheck, comment, added, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [2, "spammers", "dnsbl.tornevall.org.", "230", "http://dnsbl.tornevall.org/", "", "_bx_antispam_rule_note_dnsbl_tornevall_org", 0, 0])
    Repo.execute("INSERT INTO bx_antispam_dnsbl_rules (id, chain, zonedomain, postvresp, url, recheck, comment, added, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [3, "uridns", "multi.surbl.org.", "any", "http://www.surbl.org/", "https://surbl.org/surbl-analysis", "_bx_antispam_rule_note_surbl_org", 0, 1])
    Repo.execute("INSERT INTO bx_antispam_dnsbl_rules (id, chain, zonedomain, postvresp, url, recheck, comment, added, active) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)", [4, "spammers", "zomgbl.spameatingmonkey.net.", "any", "http://spameatingmonkey.com/index.html", "", "_bx_antispam_rule_note_zomgbl_spameatingmonkey_net", 0, 0])

    IO.puts("Registros inseridos com sucesso!")
  end
end
