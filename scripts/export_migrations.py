import os
import re
import glob
import time
import shutil
import datetime

def extrair_codigo_elixir_de_md(caminho_arquivo):
    """Extrai o código Elixir de um arquivo markdown."""
    with open(caminho_arquivo, 'r', encoding='utf-8') as arquivo:
        conteudo = arquivo.read()
        # Procura por blocos de código Elixir no formato ```elixir ... ```
        matches = re.findall(r'```elixir\s+(.*?)```', conteudo, re.DOTALL)
        if matches:
            return matches[0].strip()
    return None

def corrigir_aspas_triplas(codigo):
    """Corrige o problema das aspas triplas escapadas dentro do código."""
    # Substitui \" por " para corrigir aspas escapadas
    codigo_corrigido = codigo.replace('\\"\\"\\"', '"""')
    codigo_corrigido = codigo_corrigido.replace('\\"', '"')
    return codigo_corrigido

def gerar_prefixo_timestamp():
    """Gera um prefixo de timestamp no formato YYYYMMDDHHMMSSMMM (com milissegundos)."""
    now = datetime.datetime.now()
    # Formata a parte principal do timestamp (ano a segundo)
    timestamp_base = now.strftime("%Y%m%d%H%M%S")
    # Obtém os milissegundos (microsegundos // 1000) e formata para 3 dígitos com zeros à esquerda
    milliseconds = f"{now.microsecond // 1000:03d}"
    return f"{timestamp_base}{milliseconds}"

def gerar_sufixo_unico():
    """Gera um sufixo único baseado no timestamp atual."""
    timestamp = int(time.time() * 1000)  # milissegundos
    return f"V{timestamp}"

def obter_proximo_numero_sequencial(diretorio_destino):
    """Obtém o próximo número sequencial baseado nos arquivos já existentes."""
    arquivos_existentes = glob.glob(os.path.join(diretorio_destino, "*.ex"))
    
    maior_numero = 0
    for arquivo in arquivos_existentes:
        try:
            # Tenta extrair o número do início do nome do arquivo
            nome_arquivo = os.path.basename(arquivo)
            partes = nome_arquivo.split('_', 1)
            if len(partes) > 0:
                numero = int(partes[0])
                maior_numero = max(maior_numero, numero)
        except (ValueError, IndexError):
            # Ignora arquivos que não seguem o padrão de numeração
            pass
    
    return maior_numero + 1

def modificar_codigo_migracao(codigo, sufixo):
    """Modifica completamente o código da migração para torná-lo único."""
    # 1. Modificar o nome do módulo
    padrao_modulo = r'defmodule\s+([A-Za-z0-9_.]+)\s+do'
    match = re.search(padrao_modulo, codigo)
    
    if match:
        nome_modulo_completo_original = match.group(1)
        # Extrai apenas a parte final do nome do módulo original
        nome_modulo_base_real = nome_modulo_completo_original.split('.')[-1]
        novo_nome_modulo = f"DeeperHub.Core.Data.Migrations.{nome_modulo_base_real}"
        
        # Substitui o nome do módulo
        codigo_modificado = re.sub(
            r"defmodule\s+([A-Z][\w\.]*)",
            f"defmodule {novo_nome_modulo}",
            codigo,
            1 # Substitui apenas a primeira ocorrência
        )

        # Corrigir aliases e requires para usar DeeperHub

        # Correção específica para Repo
        codigo_modificado = re.sub(
            r"alias\s+(DeeperHub\.|Deeper\.)Core\.Data\.Repo",
            r"alias DeeperHub.Core.Data.Repo",
            codigo_modificado
        )
        codigo_modificado = re.sub(
            r"alias\s+(DeeperHub\.|Deeper\.)Data\.Repo", # Caso mais curto
            r"alias DeeperHub.Core.Data.Repo",
            codigo_modificado
        )

        # Correção específica para Logger (assumindo DeeperHub.Logger)
        codigo_modificado = re.sub(
            r"alias\s+(DeeperHub\.|Deeper\.)Core\.Logger",
            r"alias DeeperHub.Core.Logger",
            codigo_modificado
        )
        codigo_modificado = re.sub(
            r"require\s+(DeeperHub\.|Deeper\.)Core\.Logger",
            r"require DeeperHub.Core.Logger",
            codigo_modificado
        )
        # Se o logger for apenas DeeperHub.Logger, pode ser mais simples:
        codigo_modificado = re.sub(
            r"alias\s+Deeper\.Logger",
            r"alias DeeperHub.Core.Logger",
            codigo_modificado
        )
        codigo_modificado = re.sub(
            r"require\s+Deeper\.Logger",
            r"require DeeperHub.Core.Logger",
            codigo_modificado
        )

        # Correções gerais para outros módulos Deeper.*
        codigo_modificado = re.sub(
            r"alias\s+Deeper\.([\w\.]+)",
            r"alias DeeperHub.\1",
            codigo_modificado
        )
        codigo_modificado = re.sub(
            r"require\s+Deeper\.([\w\.]+)",
            r"require DeeperHub.\1",
            codigo_modificado
        )

        # Adicionar comentário sobre a origem e timestamp no início do módulo
        timestamp_atual_fmt = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        comentario_cabecalho = f"# Migração gerada com ID único: {sufixo} em {timestamp_atual_fmt}\n"
        codigo_modificado = comentario_cabecalho + codigo_modificado.replace("do\n", f"do\n  # Migração gerada com ID único: {sufixo} em {timestamp_atual_fmt}\n", 1)
        
        return codigo_modificado, nome_modulo_base_real
    
    return codigo, None # Fallback corrigido

def limpar_diretorio_destino(diretorio_destino):
    """Limpa o diretório de destino, removendo todos os arquivos .ex."""
    # Verificar se o diretório existe
    if not os.path.exists(diretorio_destino):
        os.makedirs(diretorio_destino)
        return
    
    # Backup do diretório antes de limpar
    backup_dir = f"{diretorio_destino}_backup_{int(time.time())}"
    if os.path.exists(diretorio_destino):
        shutil.copytree(diretorio_destino, backup_dir)
        print(f"Backup do diretório de migrações criado em: {backup_dir}")
    
    # Remover arquivos .ex
    for arquivo in os.listdir(diretorio_destino):
        if arquivo.endswith('.ex'):
            os.remove(os.path.join(diretorio_destino, arquivo))
    
    print(f"Diretório de destino limpo: {diretorio_destino}")

def exportar_migracoes(diretorio_base, diretorio_destino, limpar_destino=True):
    """
    Percorre recursivamente o diretório base, encontra diretórios de migrations,
    extrai o código Elixir dos arquivos .md e exporta para o diretório de destino.
    """
    # Limpar diretório de destino se solicitado
    if limpar_destino:
        limpar_diretorio_destino(diretorio_destino)
    
    # Criar diretório de destino se não existir
    if not os.path.exists(diretorio_destino):
        os.makedirs(diretorio_destino)
        print(f"Diretório de destino criado: {diretorio_destino}")

    # Contadores para estatísticas
    arquivos_md_encontrados = 0
    migracoes_exportadas = 0
    generated_migrations_list = []

    # --- FASE 1: Coletar, analisar, agrupar por nome base e selecionar o melhor .md --- 
    print("\nFASE 1: Coletando e analisando arquivos de migração fonte (.md)...")
    migracoes_agrupadas_por_nome_base = {}
    # Formato: { nome_base_limpo: [ (caminho_md, codigo_elixir_corrigido, num_linhas, diretorio_origem_md), ... ] }

    for raiz, _, arquivos_na_pasta in os.walk(diretorio_base):
        if os.path.basename(raiz) == "migrations":
            # print(f"  Analisando diretório de migrations: {raiz}") # Opcional: mais verboso
            for arquivo_md_nome in arquivos_na_pasta:
                if arquivo_md_nome.endswith('.md'):
                    arquivos_md_encontrados += 1
                    caminho_completo_md = os.path.join(raiz, arquivo_md_nome)
                    
                    # Gerar nome base limpo
                    nome_sem_extensoes = os.path.splitext(os.path.splitext(arquivo_md_nome)[0])[0]
                    nome_limpo_de_prefixo = re.sub(r"^\d+[-_]*", "", nome_sem_extensoes)
                    nome_snake_case = re.sub(r'(?<!^)(?=[A-Z])', '_', nome_limpo_de_prefixo).lower()
                    nome_snake_case = re.sub(r'\s+', '_', nome_snake_case)
                    nome_base_limpo = re.sub(r'[^a-z0-9_]+', '', nome_snake_case).strip('_')
                    if not nome_base_limpo: # Fallback para nome base vazio
                        nome_base_limpo = f"migration_from_{os.path.splitext(arquivo_md_nome)[0]}"

                    codigo_elixir = extrair_codigo_elixir_de_md(caminho_completo_md)
                    if codigo_elixir:
                        codigo_corrigido_temp = corrigir_aspas_triplas(codigo_elixir)
                        num_linhas = len(codigo_corrigido_temp.splitlines())
                        
                        if nome_base_limpo not in migracoes_agrupadas_por_nome_base:
                            migracoes_agrupadas_por_nome_base[nome_base_limpo] = []
                        migracoes_agrupadas_por_nome_base[nome_base_limpo].append(
                            (caminho_completo_md, codigo_corrigido_temp, num_linhas, raiz)
                        )
                        # print(f"    Analisado: {caminho_completo_md} (Nome base: {nome_base_limpo}, Linhas: {num_linhas})") # Opcional
                    else:
                        print(f"  Aviso: Nenhum código Elixir encontrado em {caminho_completo_md}")
    
    print(f"Total de arquivos .md encontrados e analisados: {arquivos_md_encontrados}")

    # --- FASE 2: Selecionar a melhor versão para cada nome de migração base --- 
    print("\nFASE 2: Selecionando a melhor versão para cada nome de migração base...")
    arquivos_para_processar_final = []
    # Formato: [ (codigo_elixir_selecionado, nome_base_limpo, diretorio_origem_md_selecionado, caminho_md_original_selecionado) ]

    for nome_base, candidatos in migracoes_agrupadas_por_nome_base.items():
        if not candidatos:
            continue
        
        melhor_candidato = candidatos[0] # Inicializa com o primeiro
        if len(candidatos) > 1:
            print(f"  Conflito para nome base '{nome_base}':")
            for c_path, _, c_lines, _ in candidatos:
                print(f"    - Candidato: {c_path} (Linhas: {c_lines})")
            # Ordena por número de linhas (decrescente), depois pelo caminho do arquivo (para desempate estável)
            candidatos.sort(key=lambda x: (x[2], x[0]), reverse=True) 
            melhor_candidato = candidatos[0]
            print(f"    Selecionado por mais linhas: {melhor_candidato[0]} (Linhas: {melhor_candidato[2]})")
        
        arquivos_para_processar_final.append(
            (melhor_candidato[1], nome_base, melhor_candidato[3], melhor_candidato[0])
        )
    print(f"Total de migrações únicas (após desempate por nome base) a serem processadas: {len(arquivos_para_processar_final)}")

    # --- FASE 3: Gerar e escrever arquivos de migração selecionados (.ex) --- 
    print("\nFASE 3: Gerando e escrevendo arquivos de migração selecionados (.ex)...")
    for codigo_elixir_selecionado, nome_base_final, diretorio_origem_md, caminho_md_orig in arquivos_para_processar_final:
        # Gerar sufixo único para o módulo Elixir (mantido para unicidade do nome do módulo)
        sufixo_unico_modulo = gerar_sufixo_unico()
        codigo_final_para_escrita, nome_base_modulo_pascal = modificar_codigo_migracao(codigo_elixir_selecionado, sufixo_unico_modulo)
        
        # Gerar prefixo de timestamp para o nome do arquivo
        prefixo_timestamp = gerar_prefixo_timestamp()
        nome_arquivo_destino_final = f"{prefixo_timestamp}_{nome_base_final}.ex"
        caminho_destino_final = os.path.join(diretorio_destino, nome_arquivo_destino_final)

        # Lógica para decidir se o arquivo deve ser escrito, comparando com existente no destino
        escrever_arquivo = True
        if os.path.exists(caminho_destino_final):
            print(f"  Aviso: Arquivo de destino final já existe: {caminho_destino_final} (originado de {caminho_md_orig})")
            try:
                with open(caminho_destino_final, 'r', encoding='utf-8') as f_existente:
                    conteudo_existente = f_existente.read()
                linhas_existente = len(conteudo_existente.splitlines())
                linhas_novo = len(codigo_final_para_escrita.splitlines())

                print(f"    Linhas no arquivo existente: {linhas_existente}")
                print(f"    Linhas no novo arquivo (a ser gerado): {linhas_novo}")

                if linhas_novo <= linhas_existente:
                    print(f"    Mantendo arquivo existente no destino (tem mais ou igual número de linhas).")
                    escrever_arquivo = False
                else:
                    print(f"    Substituindo arquivo existente no destino (novo arquivo tem mais linhas).")
            except Exception as e:
                print(f"    Erro ao comparar com arquivo existente no destino: {e}. Substituindo por segurança.")
        
        if escrever_arquivo:
            with open(caminho_destino_final, 'w', encoding='utf-8') as arquivo_destino_obj:
                arquivo_destino_obj.write(codigo_final_para_escrita)
            print(f"  Migração exportada: {caminho_destino_final} (originada de {caminho_md_orig})")
            if nome_base_modulo_pascal: # Ensure we got a module name
                generated_migrations_list.append((prefixo_timestamp, nome_base_modulo_pascal))
            migracoes_exportadas += 1
        else:
            print(f"  Migração não exportada (versão existente no destino mantida/preferida): {caminho_destino_final} (para {caminho_md_orig})")
    
    # Exibir estatísticas
    # --- FASE 4: Gerar arquivo migrations.txt ---
    if generated_migrations_list:
        caminho_migrations_txt = os.path.join(diretorio_destino, "migrations.txt")
        try:
            # Ordenar a lista pelo timestamp para garantir uma ordem consistente
            generated_migrations_list.sort(key=lambda x: x[0])
            
            with open(caminho_migrations_txt, 'w', encoding='utf-8') as f_txt:
                f_txt.write("[\n")
                for i, (timestamp, module_name) in enumerate(generated_migrations_list):
                    # module_name é o nome_base_modulo_pascal, e.g., CreateUsersTable
                    line = f'  {{\"{timestamp}\", DeeperHub.Core.Data.Migrations.{module_name}}}'
                    if i < len(generated_migrations_list) - 1:
                        line += ","
                    f_txt.write(line + "\n")
                f_txt.write("]\n")
            print(f"  Arquivo de lista de migrações gerado: {caminho_migrations_txt}")
        except Exception as e:
            print(f"  Erro ao gerar o arquivo migrations.txt: {e}")

    print(f"\nResumo da operação:")
    print(f"Arquivos .md encontrados e analisados: {arquivos_md_encontrados}")
    print(f"Migrações exportadas para .ex: {migracoes_exportadas}")

# Configurações
diretorio_base = "lib"
diretorio_destino = "lib/deeper_hub/core/data/migrations"

# Executar a função principal
if __name__ == "__main__":
    print(f"Iniciando exportação de migrações...")
    print(f"Diretório base: {diretorio_base}")
    print(f"Diretório destino: {diretorio_destino}")
    
    # Perguntar se deseja limpar o diretório de destino
    limpar = input("Deseja limpar o diretório de destino antes de exportar? (S/N): ").strip().upper() == 'S'
    
    exportar_migracoes(diretorio_base, diretorio_destino, limpar_destino=limpar)
    print("Processo concluído!")