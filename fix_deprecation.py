#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Script para corrigir o aviso de depreciação no arquivo extract_structure.py
"""

import re

# Abre o arquivo para leitura
with open('extract_structure.py', 'r', encoding='utf-8') as file:
    content = file.readlines()

# Modifica a linha com o aviso de depreciação
for i, line in enumerate(content):
    if "texto_limpo = re.sub(r'^.*?Deeper/docs/[^\\n]*?[\\*\\`]\\s*', '', texto, 1, re.DOTALL)" in line:
        content[i] = "    texto_limpo = re.sub(r'^.*?Deeper/docs/[^\\n]*?[\\*\\`]\\s*', '', texto, count=1, flags=re.DOTALL)\n"
        print(f"Linha {i+1} corrigida!")

# Escreve o conteúdo modificado de volta no arquivo
with open('extract_structure.py', 'w', encoding='utf-8') as file:
    file.writelines(content)

print("Correção concluída com sucesso!")
