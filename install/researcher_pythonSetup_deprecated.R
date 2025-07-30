#### FOR PHILIPP: CREATE PYTHON 3.9 VIRTUAL ENVIRONMENT FROM R ####
# Instead of using reticulate functions, we are running these commands from shell (which worked, even though I do not really understand why)
python_path <- "C:/Users/siifz01/AppData/Local/Programs/Python/Python39/python.exe" # needs to be 64bit
venv_path <- "Z:/15/A_44_RL/Projekt 3 NIRS2BIDS/Programmierung/NIRS2BIDS/py39Env"

# 1. Create virtual environment on network drive
system2(python_path, args = c("-m", "venv", shQuote(venv_path)))

# 2. Activate environment and upgrade pip, setuptools, wheel
#    Since activation scripts are shell-specific and tricky from R,
#    you can run pip directly using the venv's python.exe
venv_python <- file.path(venv_path, "Scripts", "python.exe")

# Upgrade pip, setuptools, wheel inside venv
system2(venv_python, args = c("-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel"))
# 3. Install packages in the venv
system2(venv_python, args = c("-m", "pip", "install", "mne", "mne-bids", "h5py", "pathlib"))

# Check if 64 bit
system2(python_path, args = "-c \"import struct; print(struct.calcsize('P') * 8)\"")
