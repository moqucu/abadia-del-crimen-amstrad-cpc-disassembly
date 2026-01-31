"""
Game package for La Abadia del Crimen.

Game logic, entities, and state management.
"""

from .player import Guillermo
from .objects import Mirror

# Keyboard requires pygame which is optional
try:
    from .input import Keyboard
    __all__ = ['Guillermo', 'Mirror', 'Keyboard']
except ImportError:
    __all__ = ['Guillermo', 'Mirror']
