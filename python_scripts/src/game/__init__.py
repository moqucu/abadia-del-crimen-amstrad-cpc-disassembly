"""
Game package for La Abadia del Crimen.

Game logic, entities, and state management.
"""

from .player import Guillermo
from .objects import Mirror

# InputHandler requires pygame which is optional
try:
    from .input import InputHandler
    __all__ = ['Guillermo', 'Mirror', 'InputHandler']
except ImportError:
    __all__ = ['Guillermo', 'Mirror']
