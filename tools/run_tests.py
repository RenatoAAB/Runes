"""Run Godot regression suites in an isolated copy (stdlib only)."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
import time

SUITES = {
    "ui": "tests/test_rune_interactions.gd",
    "slot_presentation": "tests/test_slot_modifier_presentation.gd",
    "highlights": "tests/test_highlight_rules.gd",
    "conditions": "tools/test_gameplay_conditions.gd",
    "victory": "tools/test_run_victory.gd",
}
EXCLUDED = {".git", ".godot", "godot_mcp", "__pycache__"}


def runtime_files(source):
    for name in ("project.godot", "icon.svg", "default_bus_layout.tres"):
        yield source / name
    for name in ("scripts", "scenes", "resources", "sprites", "text", "addons", "tests"):
        for folder, dirs, files in os.walk(source / name):
            dirs[:] = sorted(d for d in dirs if d not in EXCLUDED)
            for filename in sorted(files):
                yield Path(folder) / filename
    for rel in SUITES.values():
        if rel.startswith("tools/"):
            yield source / rel


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def execute(command, directory, label, timeout, env):
    out, err = directory / (label + '.stdout.log'), directory / (label + '.stderr.log')
    started = time.monotonic()
    with out.open('w', encoding='utf-8') as stdout, err.open('w', encoding='utf-8') as stderr:
        try:
            code = subprocess.run(command, stdout=stdout, stderr=stderr, timeout=timeout,
                                  env=env, creationflags=getattr(subprocess, 'CREATE_NO_WINDOW', 0)).returncode
        except subprocess.TimeoutExpired:
            code = -1
    text = out.read_text(encoding='utf-8') + err.read_text(encoding='utf-8')
    errors = bool(re.search(r'SCRIPT ERROR|Parse Error|^ERROR:', text, re.M))
    # Existing suites report this marker; a quit(0) alone is not proof of completion.
    matches = re.findall(r'(\d+) checks, (\d+) failures', text)
    return {'returncode': code, 'script_errors': errors, 'timeout': code == -1,
            'duration_seconds': round(time.monotonic()-started, 2),
            'checks': int(matches[-1][0]) if matches else None,
            'failures': int(matches[-1][1]) if matches else None,
            'stdout': str(out), 'stderr': str(err)}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--godot', default=os.environ.get('GODOT_BIN') or shutil.which('godot') or shutil.which('godot4'))
    parser.add_argument('--suite', action='append', choices=SUITES)
    parser.add_argument('--output', type=Path)
    parser.add_argument('--timeout', type=int, default=120)
    parser.add_argument('--render', action='store_true', help='Render UI suite and save screenshots (requires a display)')
    args = parser.parse_args()
    if not args.godot:
        parser.error('Pass --godot PATH or set GODOT_BIN.')
    source = Path(__file__).resolve().parent.parent
    output = (args.output or Path(tempfile.mkdtemp(prefix='runes-tests-'))).resolve()
    if output == source or source in output.parents or output in source.parents:
        parser.error('--output must be outside the game checkout')
    if output.exists() and any(output.iterdir()):
        parser.error('--output must be empty; previous evidence is preserved')
    output.mkdir(parents=True, exist_ok=True)
    project = output / 'project'
    before = {}
    for path in runtime_files(source):
        if path.is_symlink():
            raise ValueError('Runtime symlinks are unsupported: ' + str(path))
        rel = path.relative_to(source)
        before[rel.as_posix()] = digest(path)
        dest = project / rel
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(path, dest)
    config_path = project / 'project.godot'
    config = config_path.read_text(encoding='utf-8-sig')
    config = re.sub(r'(?m)^(config/name|config/use_custom_user_dir|config/custom_user_dir_name)=.*\n?', '', config)
    config = config.replace('[application]', '[application]\nconfig/name="Runes Tests"\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="runes-victory-tests"')
    config = re.sub(r'(?m)^MCP[^\n]*\n', '', config)
    config = re.sub(r'(?ms)(\[editor_plugins\]\s*)enabled=[^\n]*', r'\1enabled=PackedStringArray()', config)
    config = re.sub(r'(?m)^window/size/mode=.*', 'window/size/mode=0', config)
    config_path.write_text(config, encoding='utf-8')
    (project/'telemetry.cfg').write_text('[telemetry]\nenabled=false\n', encoding='utf-8')

    def environment(label):
        env = os.environ.copy()
        profile = output / 'profiles' / label
        env.update(APPDATA=str(profile), LOCALAPPDATA=str(profile),
                   XDG_DATA_HOME=str(profile), XDG_CONFIG_HOME=str(profile))
        return env

    report = {'source': str(source), 'source_hashes': before, 'suites': {}, 'passed': False}
    imported = execute([args.godot, '--headless', '--path', str(project), '--editor', '--import'],
                       output, 'import', args.timeout, environment('import'))
    report['import'] = imported
    if imported['returncode'] == 0 and not imported['script_errors']:
        for name in args.suite or SUITES:
            command = [args.godot, '--path', str(project), '--script', 'res://' + SUITES[name]]
            if args.render and name in ('ui', 'slot_presentation'):
                command += ['--rendering-method', 'gl_compatibility', '--resolution', '640x360', '--position', '-2000,-2000', '--', '--capture']
            else:
                command.insert(1, '--headless')
            result = execute(command, output, name, args.timeout, environment(name))
            result['passed'] = result['returncode'] == 0 and not result['script_errors'] and result['checks'] is not None and result['failures'] == 0
            report['suites'][name] = result
            print(f"{name}: {'PASS' if result['passed'] else 'FAIL'} ({result['checks']} checks)", flush=True)
    report['source_unchanged'] = all(digest(source/rel) == sha for rel, sha in before.items())
    report['passed'] = bool(report['suites']) and all(x['passed'] for x in report['suites'].values()) and report['source_unchanged']
    (output/'results.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print(output/'results.json')
    return 0 if report['passed'] else 1


if __name__ == '__main__':
    raise SystemExit(main())
