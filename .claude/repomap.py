#!/usr/bin/env python3
"""
Repo-Map PageRank — Génère une carte compressée du projet par importance PageRank.
Usage : python3 .claude/repomap.py [--max-tokens N] [--json]
"""
import os, sys, json, sqlite3, time, hashlib, re, argparse
from pathlib import Path
from datetime import datetime

MAX_TOKENS_DEFAULT = 12000
CACHE_FILE = ".claude/.repomap_cache.sqlite"
EXCLUDED_DIRS = {
    ".git", ".claude", "node_modules", "__pycache__", ".venv", "venv",
    "dist", "build", ".next", "vendor", "coverage", ".pytest_cache",
    ".mypy_cache", ".ruff_cache", "target", ".cargo", ".gradle",
    "out", "bin", "obj", ".idea", ".vs", ".vscode"
}
EXCLUDED_EXTS = {
    ".lock", ".min.js", ".min.css", ".map", ".ico", ".png", ".jpg",
    ".jpeg", ".gif", ".svg", ".woff", ".woff2", ".ttf", ".eot",
    ".pdf", ".bin", ".exe", ".dll", ".so", ".dylib", ".pyc", ".pyo"
}
SUPPORTED_EXTS = {
    ".py", ".ts", ".tsx", ".js", ".jsx", ".go", ".rs",
    ".java", ".cpp", ".c", ".cs", ".rb", ".kt", ".swift",
    ".php", ".scala", ".hs", ".ex", ".exs"
}
EXT_LANG = {
    ".py": "python", ".ts": "typescript", ".tsx": "tsx",
    ".js": "javascript", ".jsx": "javascript", ".go": "go",
    ".rs": "rust", ".rb": "ruby", ".java": "java",
    ".cpp": "cpp", ".c": "c", ".cs": "c_sharp",
    ".kt": "kotlin", ".swift": "swift"
}

def init_cache(db_path):
    os.makedirs(os.path.dirname(db_path) if os.path.dirname(db_path) else ".", exist_ok=True)
    conn = sqlite3.connect(db_path, timeout=10, isolation_level=None)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS file_tags "
        "(path TEXT PRIMARY KEY, mtime REAL, sha TEXT, defs TEXT, refs TEXT)"
    )
    conn.execute("PRAGMA journal_mode=WAL")
    return conn

def extraire_tags_regex(contenu):
    patterns_def = [
        r"^(?:export\s+)?(?:async\s+)?(?:def|function\*?|func|fn|class|interface|type|struct|enum|trait|impl)\s+(\w+)",
        r"^(?:export\s+)?(?:abstract\s+)?class\s+(\w+)",
        r"^(?:public|private|protected|static|\s)+\w+\s+(\w+)\s*\(",
    ]
    patterns_ref = [r"\b([A-Z]\w{2,})\b", r"\b(\w+)\s*\("]
    defs, refs = set(), set()
    for ligne in contenu.splitlines():
        s = ligne.strip()
        for p in patterns_def:
            m = re.match(p, s)
            if m:
                defs.add(m.group(1))
        for p in patterns_ref:
            refs.update(re.findall(p, s))
    return list(defs), list(refs - defs)

def extraire_tags_ts(chemin, contenu, lang_key):
    try:
        import tree_sitter_languages
        from tree_sitter import Parser
        lang = tree_sitter_languages.get_language(lang_key)
        parser = Parser()
        parser.set_language(lang)
        arbre = parser.parse(bytes(contenu, "utf-8"))
        defs, refs = set(), set()
        def parcourir(noeud):
            t = noeud.type
            if t in ("function_declaration", "function_definition", "method_definition",
                     "method_declaration", "class_declaration", "class_definition",
                     "interface_declaration", "type_alias_declaration", "type_spec"):
                for enfant in noeud.children:
                    if enfant.type in ("identifier", "type_identifier", "field_identifier",
                                       "property_identifier"):
                        defs.add(contenu[enfant.start_byte:enfant.end_byte])
                        break
            elif t == "call_expression":
                premier = noeud.children[0] if noeud.children else None
                if premier:
                    val = contenu[premier.start_byte:premier.end_byte].split(".")[-1]
                    if val and not val[0].isupper():
                        refs.add(val)
            elif t in ("type_annotation", "type_identifier"):
                refs.add(contenu[noeud.start_byte:noeud.end_byte].strip(": \n"))
            for enfant in noeud.children:
                parcourir(enfant)
        parcourir(arbre.root_node)
        return list(defs), list(refs - defs)
    except Exception:
        return extraire_tags_regex(contenu)

def tags_pour_fichier(chemin, conn):
    try:
        stat = os.stat(chemin)
        mtime = stat.st_mtime
        row = conn.execute("SELECT mtime, defs, refs FROM file_tags WHERE path=?", (chemin,)).fetchone()
        if row and abs(row[0] - mtime) < 0.01:
            return json.loads(row[1]), json.loads(row[2])
        with open(chemin, "r", encoding="utf-8", errors="replace") as f:
            contenu = f.read()
        ext = Path(chemin).suffix.lower()
        lang_key = EXT_LANG.get(ext)
        if lang_key:
            defs, refs = extraire_tags_ts(chemin, contenu, lang_key)
        else:
            defs, refs = extraire_tags_regex(contenu)
        sha = hashlib.md5(contenu.encode()).hexdigest()[:8]
        conn.execute(
            "INSERT OR REPLACE INTO file_tags VALUES (?,?,?,?,?)",
            (chemin, mtime, sha, json.dumps(defs), json.dumps(refs))
        )
        return defs, refs
    except Exception:
        return [], []

def scanner_projet(racine, conn):
    fichiers = {}
    for dirpath, dirnames, filenames in os.walk(racine):
        dirnames[:] = [d for d in dirnames if d not in EXCLUDED_DIRS and not d.startswith(".")]
        for fname in filenames:
            ext = Path(fname).suffix.lower()
            if ext not in SUPPORTED_EXTS or ext in EXCLUDED_EXTS:
                continue
            chemin = os.path.relpath(os.path.join(dirpath, fname), racine)
            defs, refs = tags_pour_fichier(os.path.join(racine, chemin), conn)
            fichiers[chemin] = {"defs": set(defs), "refs": set(refs),
                                "mtime": os.path.getmtime(os.path.join(racine, chemin))}
    return fichiers

def construire_graphe(fichiers):
    try:
        import networkx as nx
    except ImportError:
        return None, {}
    G = nx.DiGraph()
    for f in fichiers:
        G.add_node(f)
    defs_index = {}
    for chemin, data in fichiers.items():
        for sym in data["defs"]:
            if sym not in defs_index:
                defs_index[sym] = chemin
    for chemin, data in fichiers.items():
        for ref in data["refs"]:
            cible = defs_index.get(ref)
            if cible and cible != chemin:
                G.add_edge(chemin, cible)
    return G, defs_index

def calculer_pagerank(G, fichiers):
    try:
        import networkx as nx
        now = time.time()
        perso = {}
        for f in fichiers:
            age = now - fichiers[f]["mtime"]
            perso[f] = 3.0 if age < 86400 else 1.0
        total = sum(perso.values())
        perso = {k: v / total for k, v in perso.items()}
        scores = nx.pagerank(G, alpha=0.85, personalization=perso, max_iter=200)
        return scores
    except Exception:
        return {f: 1.0 / len(fichiers) for f in fichiers} if fichiers else {}

def compter_tokens(texte):
    try:
        import tiktoken
        enc = tiktoken.get_encoding("cl100k_base")
        return len(enc.encode(texte))
    except Exception:
        return len(texte) // 4

def generer_repomap(racine, max_tokens, conn):
    fichiers = scanner_projet(racine, conn)
    if not fichiers:
        return "# Repo-Map\n> Aucun fichier source trouvé.\n", 0, 0
    G, defs_index = construire_graphe(fichiers)
    if G is not None:
        scores = calculer_pagerank(G, fichiers)
    else:
        scores = {f: 1.0 for f in fichiers}
    tries = sorted(scores.items(), key=lambda x: x[1], reverse=True)
    now = time.time()
    nom_projet = os.path.basename(racine) or "projet"
    lignes = [
        f"# Repo-Map — {nom_projet}",
        f"> {len(fichiers)} fichiers analysés · Générée {datetime.now().strftime('%Y-%m-%d %H:%M')}",
        f"> Classement PageRank · Budget : {max_tokens} tokens max\n",
        "---\n"
    ]
    tokens_utilises = compter_tokens("\n".join(lignes))
    fichiers_inclus = 0
    for chemin, score in tries:
        age = now - fichiers[chemin]["mtime"]
        etoile = "* " if age < 86400 else ""
        defs = sorted(fichiers[chemin]["defs"])[:15]
        bloc = [f"## {etoile}`{chemin}`"]
        if defs:
            bloc.append("  Definit : " + " | ".join(defs[:12]))
        bloc.append("")
        texte_bloc = "\n".join(bloc)
        tokens_bloc = compter_tokens(texte_bloc)
        if tokens_utilises + tokens_bloc > max_tokens:
            lignes.append(f"\n> Budget atteint — {len(tries) - fichiers_inclus} fichiers omis.")
            break
        lignes.extend(bloc)
        tokens_utilises += tokens_bloc
        fichiers_inclus += 1
    return "\n".join(lignes), tokens_utilises, fichiers_inclus

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--max-tokens", type=int, default=MAX_TOKENS_DEFAULT)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()
    racine = os.getcwd()
    conn = init_cache(CACHE_FILE)
    try:
        carte, tokens, n_fichiers = generer_repomap(racine, args.max_tokens, conn)
        cache_md = os.path.join(".claude", ".repomap_cache.md")
        os.makedirs(".claude", exist_ok=True)
        with open(cache_md, "w", encoding="utf-8") as f:
            f.write(carte)
        if args.json:
            print(json.dumps({"repomap": carte, "tokens": tokens, "files": n_fichiers}))
        else:
            print(carte)
            sys.stderr.write(f"[repomap] {n_fichiers} fichiers · {tokens} tokens\n")
    finally:
        conn.close()

if __name__ == "__main__":
    main()
