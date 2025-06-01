#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Script para extrair estrutura de diretórios e arquivos a partir de um arquivo history.json.
Este script analisa o conteúdo do arquivo em busca de referências a caminhos de arquivos e cria
a estrutura de diretórios e arquivos correspondente.
"""

import json
import os
import re
import codecs
from pathlib import Path

def extrair_caminhos_arquivos(conteudo):
    """Extrai caminhos de arquivos do conteúdo usando expressões regulares.
    Filtra apenas os arquivos que começam com 'Deeper/docs/'.
    """
    # Padrão para encontrar referências a caminhos de arquivos como `Deeper/docs/06_file_management/data_access_module_extensions.md`
    # Busca por padrões entre ** ou entre backticks
    padrao_caminho = r'[\*\*`]([A-Za-z0-9_\-\.\/]+\.[a-zA-Z0-9]+)[\*\*`]'
    
    # Encontra todos os matches
    todos_caminhos = re.findall(padrao_caminho, conteudo)
    
    # Filtra apenas os caminhos que começam com 'Deeper/docs/'
    caminhos_filtrados = [caminho for caminho in todos_caminhos if caminho.startswith('Deeper/docs/')]
    
    # Remove duplicados e retorna a lista ordenada
    return sorted(list(set(caminhos_filtrados)))

def extrair_caminhos_arquivos_com_posicao(conteudo):
    """Extrai caminhos de arquivos do conteúdo usando expressões regulares e registra suas posições.
    Retorna uma lista de tuplas (caminho, posicao_inicio).
    """
    # Padrão para encontrar referências a caminhos de arquivos Deeper/docs/
    padrao_caminho = r'[\*\*`](Deeper/docs/[A-Za-z0-9_\-\.\/]+\.[a-zA-Z0-9]+)[\*\*`]'
    
    # Encontra todos os matches com suas posições
    caminhos_com_posicao = []
    for match in re.finditer(padrao_caminho, conteudo):
        caminho = match.group(1)
        posicao = match.start()
        caminhos_com_posicao.append((caminho, posicao))
    
    return caminhos_com_posicao

def encontrar_blocos_markdown(texto):
    """Encontra blocos de código markdown no texto.
    Procura por blocos delimitados por ``` com várias linguagens ou por seções de markdown estruturado.
    """
    # Lista de blocos encontrados
    blocos_encontrados = []
    
    # Detecta o início do primeiro bloco markdown após o caminho do arquivo
    # Primeiro, remove a menção do arquivo do início do texto para evitar confusão
    texto_limpo = re.sub(r'^.*?Deeper/docs/[^\n]*?[\*\`]\s*', '', texto, count=1, flags=re.DOTALL)
    
    # Lista de linguagens para procurar
    linguagens = ['markdown', 'json', 'sql', 'elixir', 'python', 'javascript', 'html', 'css', '']
    
    # Procura por blocos de código com várias linguagens
    for linguagem in linguagens:
        padrao = fr'```{linguagem}\s*\n(.*?)\n\s*```'
        blocos = re.findall(padrao, texto, re.DOTALL)
        
        if blocos:
            # Se for markdown, adicione direto, senão coloque com o delimitador de código correto
            if linguagem == 'markdown' or linguagem == '':
                blocos_encontrados.extend(blocos)
            else:
                # Adiciona os delimitadores de código de volta com a linguagem correta
                for bloco in blocos:
                    if len(bloco.strip()) > 10:  # Garante conteúdo mínimo
                        blocos_encontrados.append(f'```{linguagem}\n{bloco}\n```')
    
    # Se encontrou algum bloco de código, retorna
    if blocos_encontrados and len(''.join(blocos_encontrados).strip()) > 20:
        return blocos_encontrados
    
    # Se não encontrou blocos de código, tenta extrair conteúdo estruturado
    conteudo_markdown = []
    
    # Procura por seções com títulos markdown
    titulos = re.findall(r'(#+\s+.+\n(?:.+\n)*)', texto_limpo, re.DOTALL)
    if titulos:
        conteudo_markdown.extend(titulos)
    
    # Procura por listas markdown
    listas = re.findall(r'((?:[-*+]\s+.+\n)+)', texto_limpo, re.DOTALL)
    if listas:
        conteudo_markdown.extend(listas)
    
    # Procura por tabelas markdown
    tabelas = re.findall(r'(\|.+\|\n\|[-:]+\|[-:]+\|.*?\n(?:\|.+\|\n)*)', texto_limpo, re.DOTALL)
    if tabelas:
        conteudo_markdown.extend(tabelas)
    
    if conteudo_markdown:
        return conteudo_markdown
    
    # Se ainda não encontrou nada, procura por qualquer conteúdo entre menção do arquivo e o próximo separador
    match = re.search(r'(?:\*\*|`|Arquivo:\s+)Deeper/docs/[^\n]*(?:\*\*|`)?\s*\n\n(.*?)(?:(?:\n\n---|\n\n\*\*|\n\nArquivo:|```\s*\n|$))', texto, re.DOTALL)
    if match:
        conteudo = match.group(1).strip()
        if len(conteudo) > 20:  # Conteúdo mínimo significativo
            return [conteudo]
    
    # Se nada funcionar, tenta pegar todo o texto após a menção do arquivo
    texto_apos_mencao = re.sub(r'^.*?Deeper/docs/[^\n]*?(?:\*\*|`)?\s*\n', '', texto, count=1, flags=re.DOTALL)
    if len(texto_apos_mencao.strip()) > 30:  # Conteúdo mínimo significativo
        return [texto_apos_mencao.strip()]
    
    # Se todas as tentativas falharem
    return []

def extrair_conteudo_markdown_para_arquivo(conteudo_completo, caminho_arquivo, todos_caminhos_com_posicao):
    """Extrai o conteúdo markdown relacionado a um arquivo específico.
    
    Args:
        conteudo_completo: O conteúdo completo do arquivo JSON.
        caminho_arquivo: O caminho do arquivo para o qual queremos extrair o conteúdo.
        todos_caminhos_com_posicao: Lista de tuplas (caminho, posição) com todos os caminhos ordenados por posição.
    
    Returns:
        str: O conteúdo markdown relacionado ao arquivo.
    """
    # Encontrar a posição do arquivo atual no texto
    padrao_caminho = rf'(?:\*\*|`|Arquivo:\s+)({re.escape(caminho_arquivo)})(?:\*\*|`)?'
    matches = list(re.finditer(padrao_caminho, conteudo_completo))
    if not matches:
        return f"# {os.path.basename(caminho_arquivo)}\n\nArquivo mencionado na conversa, mas não foi possível encontrar sua posição."
    
    # Pegar a primeira ocorrência do arquivo
    match = matches[0]
    posicao_inicio = match.start()
    posicao_fim_match = match.end()
    
    # Determinar o fim do conteúdo (próxima menção de arquivo Deeper/docs/ ou fim do texto)
    fim_conteudo = len(conteudo_completo)
    indice_atual = next((i for i, (c, p) in enumerate(todos_caminhos_com_posicao) if c == caminho_arquivo and p >= posicao_inicio), -1)
    
    if indice_atual >= 0 and indice_atual < len(todos_caminhos_com_posicao) - 1:
        # Pegar a posição do próximo arquivo
        _, proximo_pos = todos_caminhos_com_posicao[indice_atual + 1]
        fim_conteudo = proximo_pos
    
    # Extrair o trecho completo entre o início da menção e o próximo arquivo (ou fim do texto)
    trecho_completo = conteudo_completo[posicao_inicio:fim_conteudo].strip()
    
    # Primeiro tentamos encontrar blocos markdown no trecho após a menção do arquivo
    trecho_apos_match = conteudo_completo[posicao_fim_match:fim_conteudo].strip()
    
    # Usar a função encontrar_blocos_markdown para buscar o conteúdo
    blocos_markdown = encontrar_blocos_markdown(trecho_apos_match)
    
    if blocos_markdown:
        # Processa e concatena os blocos encontrados
        conteudo_final = "\n\n".join(blocos_markdown)
        
        # Processa o conteúdo final para remover artefatos e normalizar formatação
        conteudo_final = re.sub(r'\n\s*Continue\?\s*', '', conteudo_final, flags=re.MULTILINE)
        conteudo_final = re.sub(r'^\s*Assistant:\s*', '', conteudo_final, flags=re.MULTILINE)
        
        return conteudo_final.strip()
    
    # Se não encontrou blocos markdown, tenta usar todo o trecho após a menção do arquivo
    if len(trecho_apos_match.strip()) > 30:  # Conteúdo mínimo significativo
        # Limpa artefatos
        conteudo_resultante = re.sub(r'\n\s*Continue\?\s*', '', trecho_apos_match, flags=re.MULTILINE)
        conteudo_resultante = re.sub(r'^\s*Assistant:\s*', '', conteudo_resultante, flags=re.MULTILINE)
        return conteudo_resultante.strip()
    
    # Se todas as tentativas falharem, retorna um texto padrão
    return f"# {os.path.basename(caminho_arquivo)}\n\nArquivo mencionado na conversa, mas sem conteúdo específico extraído."

def criar_estrutura_diretorios_arquivos(caminhos, conteudo_completo, todos_caminhos_com_posicao, diretorio_base="."):
    """Cria a estrutura de diretórios e arquivos a partir dos caminhos encontrados."""
    
    # Contadores para estatísticas
    arquivos_criados = 0
    arquivos_atualizados = 0
    
    for caminho in caminhos:
        # Normaliza o caminho para o SO atual
        caminho_normalizado = caminho.replace('/', os.path.sep)
        caminho_completo = Path(diretorio_base) / caminho_normalizado
        
        # Cria os diretórios se não existirem
        os.makedirs(caminho_completo.parent, exist_ok=True)
        
        # Extrai o conteúdo markdown relacionado ao arquivo
        conteudo_arquivo = extrair_conteudo_markdown_para_arquivo(conteudo_completo, caminho, todos_caminhos_com_posicao)
        
        # Verifica se o arquivo já existe
        arquivo_existe = caminho_completo.exists()
        conteudo_existente = ""
        
        # Se existe, lê o conteúdo atual
        if arquivo_existe:
            try:
                with codecs.open(caminho_completo, 'r', 'utf-8') as f:
                    conteudo_existente = f.read()
            except Exception as e:
                print(f"Erro ao ler o arquivo {caminho_completo}: {e}")
                continue
        
        # Escreve o conteúdo no arquivo
        try:
            with codecs.open(caminho_completo, 'w', 'utf-8') as f:
                # Se o arquivo existe, mantém o conteúdo e adiciona o novo
                if arquivo_existe:
                    f.write(conteudo_existente)
                    # Adiciona um separador se o conteúdo existente não termina com um e não está vazio
                    if not conteudo_existente.endswith("---\n") and conteudo_existente.strip():
                        f.write("\n\n---\n\n")
                    arquivos_atualizados += 1
                else:
                    arquivos_criados += 1
                
                # Escreve o novo conteúdo
                f.write(conteudo_arquivo)
        except Exception as e:
            print(f"Erro ao escrever no arquivo {caminho_completo}: {e}")
            continue
    
    return arquivos_criados, arquivos_atualizados

def main():
    """Função principal."""
    
    # Obtém o caminho absoluto do diretório do script
    diretorio_script = os.path.dirname(os.path.abspath(__file__))
    
    # Caminho para o arquivo history.json
    caminho_history = os.path.join(diretorio_script, 'history6.json')
    
    # Verifica se o arquivo existe
    if not os.path.exists(caminho_history):
        print(f"Erro: Arquivo {caminho_history} não encontrado.")
        return
    
    # Lê o conteúdo do arquivo history.json
    try:
        with codecs.open(caminho_history, 'r', 'utf-8') as f:
            conteudo = f.read()
    except Exception as e:
        print(f"Erro ao ler o arquivo history.json: {e}")
        return
    
    # Extrai os caminhos dos arquivos mencionados com suas posições
    todos_caminhos_com_posicao = extrair_caminhos_arquivos_com_posicao(conteudo)
    
    # Filtra apenas os caminhos que começam com 'Deeper/docs/'
    caminhos_arquivos = sorted(list(set([caminho for caminho, _ in todos_caminhos_com_posicao if caminho.startswith('Deeper/docs/')])))
    
    if not caminhos_arquivos:
        print("Nenhum caminho de arquivo válido encontrado no conteúdo.")
        return
    
    # Cria a estrutura de diretórios e arquivos
    print(f"Encontrados {len(caminhos_arquivos)} caminhos de arquivos válidos.")
    arquivos_criados, arquivos_atualizados = criar_estrutura_diretorios_arquivos(
        caminhos_arquivos, 
        conteudo, 
        todos_caminhos_com_posicao, 
        diretorio_script
    )
    
    # Exibe estatísticas
    print(f"Arquivos criados: {arquivos_criados}")
    print(f"Arquivos atualizados: {arquivos_atualizados}")

if __name__ == "__main__":
    main()
