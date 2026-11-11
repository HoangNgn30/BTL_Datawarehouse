"""Compatibility entry point. Canonical API: dw-dm/main.py.
Old experimental API contracts have been retired; see SETUP.md.
"""
import importlib.util
import sys
from pathlib import Path
root = Path(__file__).resolve().parents[1] / 'dw-dm'
sys.path.insert(0, str(root))
spec = importlib.util.spec_from_file_location('warehouse_canonical', root / 'main.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
app = module.app
