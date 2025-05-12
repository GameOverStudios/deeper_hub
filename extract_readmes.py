import re
import os

def extract_readmes_from_history(history_file, output_dir='.'):
    """
    Extrai READMEs de documentação de um arquivo de conversa com IA
    Cada README começa com um padrão específico do módulo e termina com '*Última atualização: 2025-05-10*'
    ou com o início do próximo módulo
    """
    # Cria o diretório de saída se não existir
    os.makedirs(output_dir, exist_ok=True)
    
    # Lê o arquivo com a conversa
    try:
        with open(history_file, 'r', encoding='utf-8') as f:
            content = f.read()
    except Exception as e:
        print(f"Erro ao ler o arquivo {history_file}: {e}")
        return
    
    # Primeiro, encontre todos os padrões que parecem ser um módulo DeeperHub
    module_patterns = [
        r'# Módulo: `([^`]+)` 🚀',
        r'# Módulo: `(Elixir\.DeeperHub\.[A-Za-z\.]+)`',
        r'# Módulo: `(DeeperHub\.[A-Za-z\.]+)`'
    ]
    
    modules = []
    for pattern in module_patterns:
        matches = re.finditer(pattern, content)
        for match in matches:
            module_name = match.group(1)
            start_pos = match.start()
            modules.append((module_name, start_pos))
    
    # Ordena os módulos encontrados por posição no arquivo
    modules.sort(key=lambda x: x[1])
    
    # Para cada módulo, determina onde termina seu conteúdo
    count = 0
    for i, (module_name, start_pos) in enumerate(modules):
        # Obtém o texto desde o início deste módulo
        module_text = content[start_pos:]
        
        # Define o padrão de fim: ou é o próximo módulo ou o padrão "*Última atualização: 2025-05-10*"
        end_pos = len(module_text)
        
        # Procura pelo padrão de última atualização
        update_pattern = r'\*Última atualização: 2025-05-10\*'
        update_match = re.search(update_pattern, module_text)
        if update_match:
            end_match_pos = update_match.end()
            # Certifica-se de incluir a linha de atualização
            end_pos = min(end_pos, end_match_pos)
        
        # Procura pelo próximo módulo, se houver
        if i < len(modules) - 1:
            next_module_pos = modules[i+1][1] - start_pos
            if next_module_pos > 0:  # Se o próximo módulo vem depois do atual
                end_pos = min(end_pos, next_module_pos)
        
        # Extrai o conteúdo completo do módulo
        full_content = module_text[:end_pos]
        
        # Para nome de arquivo: normaliza o nome do módulo
        safe_filename = module_name.replace('.', '_').replace('/', '_').replace('\\', '_')
        file_path = os.path.join(output_dir, f"{safe_filename}.md")
        
        # Salva o README em um arquivo
        try:
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(full_content)
            print(f"README salvo: {file_path}")
            count += 1
        except Exception as e:
            print(f"Erro ao salvar o arquivo {file_path}: {e}")
    
    print(f"\nTotal de READMEs extraídos: {count}")
    if count == 0:
        print("Nenhum README encontrado. Verifique se o arquivo contém os padrões esperados.")
        print("Padrões de módulo procurados:")
        for pattern in module_patterns:
            print(f"  - {pattern}")

if __name__ == "__main__":
    history_file = "c:\\New\\history2.json"
    output_dir = "c:\\New\\readmes"
    
    print(f"Extraindo READMEs de {history_file}...")
    extract_readmes_from_history(history_file, output_dir)
