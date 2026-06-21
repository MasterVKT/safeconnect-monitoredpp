#!/usr/bin/env python3
"""
AST Elision Hook — PreToolUse
Intercepte Read/View sur fichiers >100 lignes, retourne résumé AST.
Exit 0 = laisser passer. JSON deny = injecter résumé à la place.
"""
import sys, json, os, traceback

SEUIL_LIGNES = 100
EXTENSIONS = {
    ".py": "python", ".ts": "typescript", ".tsx": "tsx",
    ".js": "javascript", ".jsx": "javascript", ".go": "go",
    ".rs": "rust", ".rb": "ruby", ".java": "java",
    ".cpp": "cpp", ".c": "c", ".cs": "c_sharp",
    ".kt": "kotlin", ".swift": "swift", ".php": "php"
}
REQUETES_SCM = {
    "python": """
      [(function_definition name: (identifier) @name
          parameters: (parameters) @params
          return_type: (_)? @ret) @fn
       (class_definition name: (identifier) @name) @cls
       (import_statement) @imp
       (import_from_statement) @imp]
    """,
    "typescript": """
      [(function_declaration name: (identifier) @name
          parameters: (formal_parameters) @params
          return_type: (_)? @ret) @fn
       (method_definition name: (property_identifier) @name
          parameters: (formal_parameters) @params) @fn
       (arrow_function) @fn
       (class_declaration name: (type_identifier) @name) @cls
       (interface_declaration name: (type_identifier) @name) @iface
       (type_alias_declaration name: (type_identifier) @name) @type
       (import_statement) @imp]
    """,
    "tsx": """
      [(function_declaration name: (identifier) @name
          parameters: (formal_parameters) @params) @fn
       (class_declaration name: (type_identifier) @name) @cls
       (interface_declaration name: (type_identifier) @name) @iface
       (import_statement) @imp]
    """,
    "javascript": """
      [(function_declaration name: (identifier) @name
          parameters: (formal_parameters) @params) @fn
       (method_definition name: (property_identifier) @name
          parameters: (formal_parameters) @params) @fn
       (class_declaration name: (identifier) @name) @cls
       (import_statement) @imp]
    """,
    "go": """
      [(function_declaration name: (identifier) @name
          parameters: (parameter_list) @params
          result: (_)? @ret) @fn
       (method_declaration name: (field_identifier) @name
          parameters: (parameter_list) @params) @fn
       (type_declaration (type_spec name: (type_identifier) @name
          type: (_) @kind)) @type
       (import_declaration) @imp]
    """,
    "kotlin": """
      [(function_declaration (simple_identifier) @name) @fn
       (class_declaration (type_identifier) @name) @cls
       (object_declaration (type_identifier) @name) @cls
       (import_header) @imp]
    """,
    "swift": """
      [(function_declaration name: (simple_identifier) @name) @fn
       (class_declaration name: (type_identifier) @name) @cls
       (protocol_declaration name: (type_identifier) @name) @iface
       (import_declaration) @imp]
    """,
    "java": """
      [(method_declaration name: (identifier) @name) @fn
       (class_declaration name: (identifier) @name) @cls
       (interface_declaration name: (identifier) @name) @iface
       (import_declaration) @imp]
    """,
}
REQUETES_SCM["jsx"] = REQUETES_SCM["javascript"]


def extraire_signatures_ast(chemin, contenu, langage_cle):
    try:
        try:
            from tree_sitter_language_pack import get_language, get_parser
            parser = get_parser(langage_cle)
            lang = get_language(langage_cle)
        except Exception:
            try:
                import tree_sitter_languages
                from tree_sitter import Parser
                lang = tree_sitter_languages.get_language(langage_cle)
                parser = Parser()
                parser.set_language(lang)
            except Exception:
                return extraire_signatures_regex(contenu)

        arbre = parser.parse(bytes(contenu, "utf-8"))
        scm = REQUETES_SCM.get(langage_cle)
        if not scm:
            return extraire_signatures_regex(contenu)

        try:
            requete = lang.query(scm)
        except Exception:
            return extraire_signatures_regex(contenu)

        captures = requete.captures(arbre.root_node)
        lignes_source = contenu.splitlines()
        vus = set()
        resultats = []

        # captures peut être dict ou liste selon version tree-sitter
        if isinstance(captures, dict):
            items = []
            for tag, noeuds in captures.items():
                for noeud in noeuds:
                    items.append((noeud, tag))
            items.sort(key=lambda x: x[0].start_byte)
        else:
            items = captures

        for noeud, tag in items:
            if tag == "imp":
                texte = contenu[noeud.start_byte:noeud.end_byte].strip()
                if texte not in vus:
                    vus.add(texte)
                    resultats.append(f"  {texte}")
            elif tag in ("fn", "cls", "iface", "type"):
                num_ligne = noeud.start_point[0]
                texte_ligne = (
                    lignes_source[num_ligne].strip()
                    if num_ligne < len(lignes_source) else ""
                )
                cle = f"{tag}:{num_ligne}"
                if cle not in vus and texte_ligne:
                    vus.add(cle)
                    suffixe = " {…}" if tag in ("fn", "cls", "iface") else ""
                    resultats.append(f"  {texte_ligne}{suffixe}")

        return resultats
    except Exception:
        return extraire_signatures_regex(contenu)


def extraire_signatures_regex(contenu):
    import re
    patterns = [
        r"^(def |class |async def |func |function |interface |type |pub fn |fn )",
        r"^(export (default |async |function|class|interface|type))",
        r"^(import |from .+ import)",
    ]
    resultats = []
    for ligne in contenu.splitlines():
        stripped = ligne.strip()
        if any(re.match(p, stripped) for p in patterns):
            resultats.append(f"  {stripped[:120]}")
    return resultats[:80]


def main():
    try:
        data = json.loads(sys.stdin.read())
        file_path = (
            data.get("tool_input", {}).get("file_path") or
            data.get("tool_input", {}).get("path") or
            data.get("tool_input", {}).get("relative_path") or ""
        )
        if not file_path or not os.path.isfile(file_path):
            sys.exit(0)
        ext = os.path.splitext(file_path)[1].lower()
        if ext not in EXTENSIONS:
            sys.exit(0)
        try:
            with open(file_path, "r", encoding="utf-8", errors="replace") as f:
                contenu = f.read()
        except Exception:
            sys.exit(0)
        lignes = contenu.splitlines()
        if len(lignes) < SEUIL_LIGNES:
            sys.exit(0)
        langage_cle = EXTENSIONS[ext]
        signatures = extraire_signatures_ast(file_path, contenu, langage_cle)
        if len(signatures) < 3:
            sys.exit(0)
        basename = os.path.basename(file_path)
        resume = (
            f"# AST Summary : `{basename}` ({len(lignes)} lignes -> "
            f"{len(signatures)} signatures)\n"
            f"> Corps elisés. Demander `read_full:{file_path}` pour code complet.\n\n"
            + "\n".join(signatures[:100])
        )
        sortie = {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny",
                "permissionDecisionReason": resume
            }
        }
        print(json.dumps(sortie))
        sys.exit(0)
    except Exception:
        sys.exit(0)


if __name__ == "__main__":
    main()
