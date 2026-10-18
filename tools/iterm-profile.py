#!/usr/bin/env python3
"""List or add claude-auto profiles in iTerm2's dynamic profiles file.

  iterm-profile.py list
  iterm-profile.py add "<Profile Name>" <claude-auto project> [--dir <start folder>] [--template "<Name>"]

add clones an existing claude-auto profile (same colours, fonts, keys), gives it a
new Name and Guid, and sets Initial Text to "claude-auto <project>\\n" (the trailing
newline makes the tab run it on open, Pitfall 670). If a profile with that Name
already exists, only its Initial Text is repointed. The old file is backed up to
~/.claude-auto/backups/ first, never into the
DynamicProfiles folder (iTerm2 would load the backup as profiles).
"""
import copy, datetime, json, os, pathlib, sys, tempfile, uuid

PROFILES = pathlib.Path.home() / "Library/Application Support/iTerm2/DynamicProfiles/claude-auto-profiles.json"
BACKUPS = pathlib.Path.home() / ".claude-auto/backups"


def load():
    return json.loads(PROFILES.read_text())


def backup():
    BACKUPS.mkdir(parents=True, exist_ok=True)
    stamp = datetime.datetime.now().strftime("%Y%m%d-%H%M%S-%f")
    (BACKUPS / f"claude-auto-profiles.{stamp}.json").write_text(PROFILES.read_text())


def save(data):
    fd, tmp = tempfile.mkstemp(dir=str(PROFILES.parent.parent))
    with os.fdopen(fd, "w") as f:
        json.dump(data, f, indent=2)
    os.replace(tmp, PROFILES)


def set_dir(profile, directory):
    if directory:
        profile["Custom Directory"] = "Yes"
        profile["Working Directory"] = os.path.expanduser(directory)


def cmd_list(data):
    for p in data.get("Profiles", []):
        print(f"{p.get('Name')!r:32} initial={p.get('Initial Text')!r:40} dir={p.get('Working Directory', '')!r}")


def cmd_add(data, name, project, template=None, directory=None):
    profiles = data.get("Profiles", [])
    existing = next((p for p in profiles if p.get("Name") == name), None)
    if existing is not None:
        want = f"claude-auto {project}\n"
        if existing.get("Initial Text") == want:
            print(f"{name!r} already runs claude-auto {project}; nothing changed.")
            return
        backup()
        print(f"Repointed {name!r}: {existing.get('Initial Text')!r} -> {want!r}")
        existing["Initial Text"] = want
        set_dir(existing, directory)
        save(data)
        return
    if template:
        src = next((p for p in profiles if p.get("Name") == template), None)
    else:
        src = next((p for p in profiles
                    if str(p.get("Initial Text", "")).startswith("claude-auto ")
                    and "launch" not in str(p.get("Initial Text", ""))), None)
    if src is None:
        sys.exit("No template profile found; pass --template with an exact Name from 'list'.")
    new = copy.deepcopy(src)
    new["Name"] = name
    new["Guid"] = str(uuid.uuid4()).upper()
    new["Initial Text"] = f"claude-auto {project}\n"
    set_dir(new, directory)
    if "Badge Text" in new:
        new["Badge Text"] = name
    profiles.append(new)
    backup()
    save(data)
    print(f"Added {name!r} (from {src.get('Name')!r}) -> claude-auto {project}")


if __name__ == "__main__":
    a = sys.argv[1:]
    if not a or a[0] not in ("list", "add"):
        sys.exit(__doc__)
    d = load()
    if a[0] == "list":
        cmd_list(d)
    else:
        opts = {}
        for flag in ("--template", "--dir"):
            if flag in a:
                i = a.index(flag); opts[flag] = a[i + 1]; a = a[:i] + a[i + 2:]
        if len(a) != 3:
            sys.exit(__doc__)
        cmd_add(d, a[1], a[2], opts.get("--template"), opts.get("--dir"))
