"""Remplace le numéro de build (partie après `+`) de la ligne `version:` du pubspec.

Le fichier est lu et réécrit tel quel (fins de ligne conservées, fichier
entièrement réécrit) : l'ancienne version réécrivait par-dessus sans tronquer,
ce qui laissait des restes en fin de fichier sous Linux (pubspec en CRLF).
"""
import os
import re
import sys

PUBSPEC = "./pubspec.yaml"


def main() -> None:
    build_num = os.environ.get("BUILD_NUM", "").strip()
    if not build_num.isdigit():
        sys.exit(f"BUILD_NUM invalide : {build_num!r}")

    with open(PUBSPEC, encoding="utf-8", newline="") as file:
        content = file.read()

    new_content, count = re.subn(
        r"(?m)^(version:[ \t]*[^\s+]+)(?:\+[^\s]*)?",
        rf"\g<1>+{build_num}",
        content,
    )
    if count != 1:
        sys.exit(f"Ligne 'version:' introuvable ou multiple dans {PUBSPEC} ({count})")

    with open(PUBSPEC, "w", encoding="utf-8", newline="") as file:
        file.write(new_content)

    print(re.search(r"(?m)^version:.*$", new_content).group(0).strip())


if __name__ == "__main__":
    main()
