class Mirror:
    """
    Representation of the secret mirror in the abbey.
    In the original game, this state is tracked at memory address 0x2D8C.
    Value 1 = closed, Value 0 = open.
    """

    def __init__(self):
        self.is_open = False

    def set_state(self, is_open: bool):
        """
        Explicitly set the mirror's state.
        """
        self.is_open = is_open
        self._log_state()

    def open(self):
        """Open the mirror."""
        self.is_open = True
        self._log_state()

    def close(self):
        """Close the mirror."""
        self.is_open = False
        self._log_state()

    def _log_state(self):
        state_str = "OPEN" if self.is_open else "CLOSED"
        print(f"Mirror is now {state_str}")
