import pygame

class Keyboard:
    """
    Handles keyboard input state for the game.
    Wraps pygame's key handling to provide higher-level game actions.
    """

    def __init__(self):
        # Ensure pygame is initialized (safe to call multiple times)
        if not pygame.get_init():
            pygame.init()

    def get_state(self):
        """
        Returns the full state of all keys.
        Useful if you want to snapshot input for a specific frame.
        """
        # pumping events is required for get_pressed to return up-to-date values
        pygame.event.pump()
        return pygame.key.get_pressed()

    def is_pressed(self, key_name: str) -> bool:
        """
        Check if a specific key is currently held down.
        key_name: 'a', 'b', 'q', 'r', 'space', 'up', etc.
        """
        keys = self.get_state()
        
        # Map string names to pygame constants if needed, 
        # but pygame.key.key_code(name) handles most standard names.
        try:
            key_code = pygame.key.key_code(key_name)
            return keys[key_code]
        except ValueError:
            return False

    def is_qr_pressed(self) -> bool:
        """
        Specific check for the 'Q' and 'R' keys being pressed simultaneously.
        In the original game, this combination (often with the mirror) trigger events.
        """
        keys = self.get_state()
        return keys[pygame.K_q] and keys[pygame.K_r]

    def is_pause_pressed(self) -> bool:
        """Check if the Delete key is pressed to pause the game."""
        keys = self.get_state()
        return keys[pygame.K_DELETE]

    def is_save_pressed(self) -> bool:
        """Check if Ctrl + F is pressed to save the game."""
        keys = self.get_state()
        mods = pygame.key.get_mods()
        return (mods & pygame.KMOD_CTRL) and keys[pygame.K_f]

    def is_load_pressed(self) -> bool:
        """Check if Shift + F is pressed to load the game."""
        keys = self.get_state()
        mods = pygame.key.get_mods()
        return (mods & pygame.KMOD_SHIFT) and keys[pygame.K_f]

    def update(self):
        """
        Call this once per frame to process the internal event queue.
        """
        pygame.event.pump()
