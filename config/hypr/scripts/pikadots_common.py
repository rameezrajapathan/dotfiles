import json
import os

HOME = os.path.expanduser("~")
SETTINGS = os.path.join(HOME, ".config/pikadots/settings.json")


def load_json(path, fallback=None):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return {} if fallback is None else fallback


def settings_section(section=None):
    data = load_json(SETTINGS)
    if not isinstance(data, dict):
        data = {}
    if section is None:
        return data
    value = data.get(section)
    return value if isinstance(value, dict) else {}
