This directory is for static assets that should be distributed with the package.
Access them in code using:
    from importlib import resources
    with resources.files("abadia.resources").joinpath("readme.txt").open("r") as f:
        data = f.read()
