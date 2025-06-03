import os
import re

def corrigir_palavras_reservadas_em_migracao():
    """
    Corrige arquivos de migração para escapar palavras reservadas do SQLite.
    """
    # Diretório das migrações
    migrations_dir = os.path.join("..", "lib", "deeper_hub", "core", "data", "migrations")
    
    # Palavras reservadas do SQLite que precisamos verificar
    palavras_reservadas = [
        "order", "group", "limit", "select", "where", "from", "table", 
        "index", "primary", "key", "constraint", "references"
    ]
    
    # Contador de arquivos corrigidos
    arquivos_corrigidos = 0
    colunas_corrigidas = 0
    
    # Percorrer todos os arquivos .ex no diretório de migrações
    print(f"Verificando arquivos de migração em: {migrations_dir}")
    
    for arquivo in os.listdir(migrations_dir):
        if arquivo.endswith(".ex"):
            arquivo_path = os.path.join(migrations_dir, arquivo)
            
            # Ler o conteúdo do arquivo
            with open(arquivo_path, 'r', encoding='utf-8') as f:
                conteudo = f.read()
            
            # Flag para verificar se o arquivo foi modificado
            modificado = False
            
            # Verificar cada palavra reservada
            for palavra in palavras_reservadas:
                # Padrão para encontrar a palavra reservada como nome de coluna
                # Exemplo: order INTEGER NOT NULL
                padrao = rf'(\s+)({palavra})(\s+[A-Z]+\s+(?:NOT\s+)?NULL)'
                
                # Contar ocorrências
                ocorrencias = len(re.findall(padrao, conteudo, re.IGNORECASE))
                
                if ocorrencias > 0:
                    # Substituir a palavra reservada por versão entre aspas duplas
                    novo_conteudo = re.sub(padrao, r'\1"\2"\3', conteudo, flags=re.IGNORECASE)
                    
                    if novo_conteudo != conteudo:
                        conteudo = novo_conteudo
                        modificado = True
                        colunas_corrigidas += ocorrencias
                        print(f"  - Arquivo {arquivo}: Corrigida(s) {ocorrencias} ocorrência(s) da palavra reservada '{palavra}'")
            
            # Se o arquivo foi modificado, salvar as alterações
            if modificado:
                with open(arquivo_path, 'w', encoding='utf-8') as f:
                    f.write(conteudo)
                arquivos_corrigidos += 1
    
    print(f"\nResumo:")
    print(f"  - Total de arquivos corrigidos: {arquivos_corrigidos}")
    print(f"  - Total de colunas corrigidas: {colunas_corrigidas}")
    
    return arquivos_corrigidos, colunas_corrigidas

if __name__ == "__main__":
    print("Iniciando correção de palavras reservadas em arquivos de migração...")
    arquivos_corrigidos, colunas_corrigidas = corrigir_palavras_reservadas_em_migracao()
    
    if arquivos_corrigidos > 0:
        print(f"\nForam corrigidos {arquivos_corrigidos} arquivos com um total de {colunas_corrigidas} ocorrências de palavras reservadas.")
        print("As palavras reservadas agora estão entre aspas duplas para evitar erros de sintaxe SQL.")
    else:
        print("\nNenhum arquivo precisou ser corrigido. Todos os arquivos de migração estão corretos.")
