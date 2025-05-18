#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import os
import sys
import time
import threading
import importlib
import traceback
from watchdog.observers import Observer
from watchdog.events import FileSystemEventHandler

class ModuleReloader:
    """
    Sistema de hot reload para módulos Python.
    Monitora alterações em arquivos e recarrega os módulos automaticamente.
    """
    
    def __init__(self, watch_dir, modules_to_watch=None, callback=None):
        """
        Inicializa o recarregador de módulos.
        
        Args:
            watch_dir (str): Diretório a ser monitorado
            modules_to_watch (list): Lista de nomes de módulos para monitorar
            callback (function): Função a ser chamada após o recarregamento
        """
        self.watch_dir = os.path.abspath(watch_dir)
        self.modules_to_watch = modules_to_watch or []
        self.callback = callback
        self.observer = None
        self.last_reload_time = {}
        self.reload_lock = threading.Lock()
        
    def start(self):
        """Inicia o monitoramento de arquivos."""
        event_handler = ModuleChangeHandler(self)
        self.observer = Observer()
        self.observer.schedule(event_handler, self.watch_dir, recursive=True)
        self.observer.start()
        print(f"🔄 Hot reload ativado. Monitorando diretório: {self.watch_dir}")
        return self
        
    def stop(self):
        """Para o monitoramento de arquivos."""
        if self.observer:
            self.observer.stop()
            self.observer.join()
            print("🛑 Hot reload desativado.")
            
    def reload_module(self, module_name):
        """
        Recarrega um módulo específico.
        
        Args:
            module_name (str): Nome do módulo a ser recarregado
        """
        with self.reload_lock:
            # Evita recarregar o mesmo módulo várias vezes em um curto período
            current_time = time.time()
            if module_name in self.last_reload_time:
                if current_time - self.last_reload_time[module_name] < 1.0:
                    return
                    
            self.last_reload_time[module_name] = current_time
            
            try:
                # Verifica se o módulo está carregado
                if module_name in sys.modules:
                    print(f"🔄 Recarregando módulo: {module_name}")
                    # Recarrega o módulo
                    importlib.reload(sys.modules[module_name])
                    
                    # Chama o callback se fornecido
                    if self.callback:
                        self.callback(module_name)
            except Exception as e:
                print(f"❌ Erro ao recarregar módulo {module_name}: {e}")
                traceback.print_exc()
                
class ModuleChangeHandler(FileSystemEventHandler):
    """Manipulador de eventos para detectar alterações em arquivos."""
    
    def __init__(self, reloader):
        """
        Inicializa o manipulador de eventos.
        
        Args:
            reloader (ModuleReloader): Instância do recarregador de módulos
        """
        self.reloader = reloader
        
    def on_modified(self, event):
        """
        Chamado quando um arquivo é modificado.
        
        Args:
            event: Evento de modificação
        """
        if event.is_directory:
            return
            
        # Verifica se é um arquivo Python
        if not event.src_path.endswith('.py'):
            return
            
        # Converte o caminho do arquivo para o nome do módulo
        file_path = os.path.abspath(event.src_path)
        if not file_path.startswith(self.reloader.watch_dir):
            return
            
        rel_path = os.path.relpath(file_path, self.reloader.watch_dir)
        module_path = os.path.splitext(rel_path)[0].replace(os.path.sep, '.')
        
        # Se modules_to_watch estiver vazio, recarrega todos os módulos
        # Caso contrário, verifica se o módulo está na lista
        if not self.reloader.modules_to_watch or module_path in self.reloader.modules_to_watch:
            self.reloader.reload_module(module_path)
            
def setup_hot_reload(watch_dir, modules_to_watch=None, callback=None):
    """
    Configura e inicia o sistema de hot reload.
    
    Args:
        watch_dir (str): Diretório a ser monitorado
        modules_to_watch (list): Lista de nomes de módulos para monitorar
        callback (function): Função a ser chamada após o recarregamento
        
    Returns:
        ModuleReloader: Instância do recarregador de módulos
    """
    reloader = ModuleReloader(watch_dir, modules_to_watch, callback)
    return reloader.start()
