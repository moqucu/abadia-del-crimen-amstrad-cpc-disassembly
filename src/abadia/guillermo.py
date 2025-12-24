class Guillermo:
    """
    Representation of the main character, Friar Guillermo (William of Baskerville).
    """

    def __init__(self):
        # Animation counter (0-3). 
        # In the original game, this is stored at memory address 0x3036.
        # It increments during movement and is used to throttle AI pathfinding.
        self.animation_counter = 0
