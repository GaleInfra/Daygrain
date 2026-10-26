"""Flutter 7.2.3 activity builder. Validates config and can shell out to Flutter 3.27.0."""
from __future__ import annotations

import argparse
import hashlib
import datetime
import json
import os
from pathlib import Path
import re
import shutil
import subprocess

SCHEMA = 'harness-activity.build.v1'
ROOT = Path(__file__).resolve().parent


def configuration(raw: dict) -> dict:
    if raw.get('schema_version') != SCHEMA:
        raise ValueError('activity_config_schema_invalid')
    for key in ('pkg', 'build_id', 'api_host'):
        if not isinstance(raw.get(key), str) or not raw[key].strip():
            raise ValueError(f'activity_missing:{key}')
    if not re.fullmatch(r'[A-Za-z0-9]+(?:[._-][A-Za-z0-9]+)*', raw['pkg']):
        raise ValueError('activity_pkg_invalid')
    env = raw.get('broadcaster_env', 'prod')
    if env not in ('prod', 'test'):
        raise ValueError('activity_broadcaster_env_invalid')
    pop = raw.get('pop_host_mode', 'pop')
    if pop not in ('pop', 'page'):
        raise ValueError('activity_pop_host_mode_invalid')
    allowlist = raw.get('product_allowlist', '')
    if allowlist and not re.fullmatch(r'\w+:\d+:\d+(?:\.\d+)?(?:,\w+:\d+:\d+(?:\.\d+)?)*', allowlist):
        raise ValueError('activity_product_allowlist_invalid')
    check_socket_url(raw['api_host'], raw.get('socket_url'))
    return raw


def _host(url: str) -> str:
    match = re.match(r'^(?:https|wss)://([^/:?#]+)', str(url or '').strip(), re.I)
    return match.group(1).lower() if match else ''


def check_socket_url(api_host: str, socket_url) -> None:
    """socket.io lives on the im domain. The api domain answers /socket.io/ with token errors."""
    if not isinstance(socket_url, str) or not _host(socket_url):
        raise ValueError('activity_socket_url_missing')
    if _host(socket_url) == _host(api_host):
        raise ValueError('activity_socket_url_is_api_host')


def source_gate_problems(root: Path = ROOT) -> list[str]:
    """Dart defects that shipped once: in-call chat never connects, recharge card stays in app."""
    problems: list[str] = []
    main = (root / 'lib/main.dart').read_text(encoding='utf-8')
    if 'socketUrl: (socketUrl ?? BakedConfig.socketUrl).replaceAll("wss://", "https://")' not in main:
        problems.append('baked socketUrl keeps wss:// (Uri.parse port 0)')
    card = (root / 'lib/pages/message/message_chat/widget/chat_bubble_widget.dart').read_text(encoding='utf-8')
    if 'myBrowser(url, 0, 1)' in card:
        problems.append('recharge card ignores tpp_open_type')
    vip = root / 'lib/widget/vip/vip_privileges_sheet.dart'
    if vip.is_file():
        vip_src = vip.read_text(encoding='utf-8')
        if 'kIsWeb' not in vip_src or 'networkUrl' not in vip_src:
            problems.append('vip sheet missing web-safe networkUrl background video')
        if 'assetsPrefix' not in vip_src:
            problems.append('vip sheet missing assetsPrefix for web video url')
        if 'setVolume(1)' not in vip_src or 'setVolume(0)' not in vip_src:
            problems.append('vip sheet missing audible autoplay with muted fallback')
        if '_unmuteWebBackground' not in vip_src or 'onPointerDown' not in vip_src:
            problems.append('vip sheet missing unmute on first interaction')
        if '_enableBgVideo = !kIsWeb' in vip_src:
            problems.append('vip sheet still disables background video on web')
        if 'shouldGateNonVip' not in vip_src:
            problems.append('vip sheet missing shouldGateNonVip')
        if 'shouldShowVipEntry' not in vip_src:
            problems.append('vip sheet missing shouldShowVipEntry')
        if 'resolveVipPurchase' not in vip_src:
            problems.append('vip sheet purchase ignores exchangeDays term')
    page = root / 'lib/pages/vip/vip_privileges_page.dart'
    if page.is_file() and 'resolveVipPurchase' not in page.read_text(encoding='utf-8'):
        problems.append('vip page purchase ignores exchangeDays term')
    model = root / 'lib/model/mine/coin_goods_model.dart'
    logic = root / 'lib/common_logic/coin_goods_logic.dart'
    if model.is_file() and logic.is_file():
        model_src = model.read_text(encoding='utf-8')
        logic_src = logic.read_text(encoding='utf-8')
        if (
            'bool get isVipTerm' not in model_src
            or "json['exchangeDays']" not in model_src
            or "json['validDays']" not in model_src
            or 'if (validity != null) return true;' not in model_src
            or 'if (validDays != null && validDays! > 0) return true;' not in model_src
            or 'if (exchangeDays != null && exchangeDays! > 0) return true;' not in model_src
        ):
            problems.append('vip term missing exchangeDays/validDays membership')
        if 'item.isVipTerm' not in logic_src or 'resolveVipPurchase' not in logic_src:
            problems.append('vip list ignores isVipTerm')
    mine = root / 'lib/pages/mine/view.dart'
    if mine.is_file():
        mine_src = mine.read_text(encoding='utf-8')
        if 'shouldShowVipEntry' not in mine_src:
            problems.append('mine page missing VIP entry visibility gate')
    match = root / 'lib/pages/flash_chat/view.dart'
    if match.is_file():
        match_src = match.read_text(encoding='utf-8')
        if 'shouldShowVipEntry' not in match_src:
            problems.append('flash chat missing VIP entry visibility gate')
    index = root / 'web/index.html'
    if index.is_file():
        index_src = index.read_text(encoding='utf-8')
        if "messageHandlers.event.postMessage({kind: 'settings'})" not in index_src:
            problems.append('settings jump missing event kind settings')
        if 'function my_log_setting(' in index_src:
            problems.append('my_log_setting declaration overrides native wrapper')
        if 'window.my_log_setting = function' not in index_src:
            problems.append('my_log_setting is not assigned over a native wrapper')
        if 'window.__fuseLifecycleEmit = emitLifecycle' not in index_src:
            problems.append('lifecycle bridge missing visibilitychange -> onLifecycleState')
        if "window.addEventListener('pagehide', function () { emitLifecycle('paused'); })" not in index_src:
            problems.append('lifecycle bridge missing pagehide -> paused')
    my_app = root / 'lib/my_app.dart'
    if my_app.is_file():
        my_app_src = my_app.read_text(encoding='utf-8')
        if '_onAppPausedNow();' not in my_app_src or 'throttleUtil.cancel("app_lifecycle_state_change")' not in my_app_src:
            problems.append('my_app paused report still waits for throttle')
        if 'BHPlatform.isWeb && state == myAppLifecycleState' not in my_app_src:
            problems.append('my_app missing web lifecycle dedupe')
    return problems


def _defines(raw: dict) -> list[str]:
    keys = raw.get('keys') if isinstance(raw.get('keys'), list) and len(raw.get('keys')) == 4 else ['', '', '', '']
    mapping = {
        'PACKAGE_NAME': raw.get('package_name') or raw['pkg'],
        'BASE_URL': raw['api_host'],
        'LOG_URL': raw.get('log_url') or raw['api_host'],
        'SOCKET_URL': re.sub(r'^wss://', 'https://', str(raw.get('socket_url') or raw['api_host']).strip()),
        'PRIVACY_POLICY': raw.get('privacy_url', ''),
        'TERMS_CONDITIONS': raw.get('terms_url', ''),
        'IOS_APP_ID': raw.get('ios_app_id', ''),
        'APP_VERSION': raw.get('app_version', ''),
        'BROADCASTER_ENV': raw.get('broadcaster_env', 'prod'),
        'LOCAL_SCHEME': raw.get('local_scheme', ''),
        'POP_HOST_MODE': raw.get('pop_host_mode', 'pop'),
        'ACTIVITY_DEVICE_PARAMETER': raw.get('device_parameter', 'device-id'),
        'COMMERCE_MODE': raw.get('commerce_mode', ''),
        'PRODUCT_ALLOWLIST': raw.get('product_allowlist', ''),
        'KEY1': keys[0],
        'KEY2': keys[1],
        'KEY3': keys[2],
        'KEY4': keys[3],
    }
    mapping.update(_prelogin_defines(raw))
    return [f'--dart-define={key}={value}' for key, value in mapping.items() if value]


def _prelogin_spec(raw: dict):
    keys = raw.get('keys')
    pkg = raw.get('pkg')
    build_id = raw.get('build_id')
    if not isinstance(keys, list) or len(keys) != 4 or not pkg or not build_id:
        return None
    import sys
    factory_root = ROOT.parents[1]
    if str(factory_root) not in sys.path:
        sys.path.insert(0, str(factory_root))
    from factory.prelogin_schema import derive_prelogin_spec
    return derive_prelogin_spec(str(pkg), str(build_id), [str(item) for item in keys])


def _prelogin_defines(raw: dict) -> dict:
    spec = _prelogin_spec(raw)
    if not spec:
        return {}
    slots = spec['slots']
    return {
        'PRELOGIN_WINDOW_SLOT': spec['window_slot'],
        'PRELOGIN_SLOT_DEVICE_ID': slots['device_id'],
        'PRELOGIN_SLOT_TOKEN': slots['token'],
        'PRELOGIN_SLOT_FIRST_REG': slots['first_reg'],
        'PRELOGIN_SLOT_USER': slots['user'],
        'PRELOGIN_SLOT_CONFIG': slots['config'],
        'PRELOGIN_SLOT_STRATEGY': slots['strategy'],
        'PRELOGIN_SLOT_ISSUED_AT': slots['issued_at'],
    }


def _prelogin_script(raw: dict) -> str:
    spec = _prelogin_spec(raw)
    pkg = str(raw.get('pkg') or '').replace('\\', '').replace("'", '')
    if not spec or not pkg:
        return ''
    name = spec['cookie_name']
    slot = spec['window_slot']
    key_hex = spec['seal_key_hex']
    return (
        "<script>(function(){"
        f"var n='{name}',slot='{slot}',pkg='{pkg}',keyHex='{key_hex}';"
        "function take(name){var all=document.cookie?document.cookie.split(';'):[];"
        "for(var i=0;i<all.length;i++){var p=all[i].trim();if(p.indexOf(name+'=')===0)return p.slice(name.length+1);}return '';}"
        "function burn(name){var path=location.pathname.replace(/index\\.html$/,'');"
        "if(path.slice(-1)!=='/')path+='/';"
        "var sec=location.protocol==='https:'?'; Secure':'';"
        "document.cookie=name+'=; Max-Age=0; Path='+path+'; SameSite=Strict'+sec;}"
        "var blob=take(n);for(var i=1;i<8;i++){var c=take(n+'_'+i);if(!c)break;blob+=c;}"
        "burn(n);for(var j=1;j<8;j++)burn(n+'_'+j);"
        "function b64(s){s=s.replace(/-/g,'+').replace(/_/g,'/');while(s.length%4)s+='=';"
        "var bin=atob(s),out=new Uint8Array(bin.length);for(var k=0;k<bin.length;k++)out[k]=bin.charCodeAt(k);return out;}"
        "function hex(s){var out=new Uint8Array(s.length/2);for(var i=0;i<out.length;i++)out[i]=parseInt(s.substr(i*2,2),16);return out;}"
        "window[slot]=blob?crypto.subtle.importKey('raw',hex(keyHex),{name:'AES-GCM'},false,['decrypt']).then(function(key){"
        "var parts=blob.split('.');"
        "return crypto.subtle.decrypt({name:'AES-GCM',iv:b64(parts[0]),additionalData:new TextEncoder().encode(pkg)},key,b64(parts[1]));"
        "}).then(function(buf){var ds=new DecompressionStream('deflate-raw');"
        "return new Response(new Blob([buf]).stream().pipeThrough(ds)).text();"
        "}).catch(function(){return null;}):Promise.resolve(null);"
        "})();</script>"
    )


def stamp_host(html: str, raw: dict) -> str:
    scheme = str(raw.get('local_scheme') or '').replace("'", '')
    primary = scheme[:-6] if scheme.endswith('-local') else scheme
    pop = 'page' if raw.get('pop_host_mode') == 'page' else 'pop'
    marker = '<head>'
    script = (
        "<head>\n<script>"
        f"window.__FUSE_LOCAL_SCHEME__='{scheme}';"
        f"window.__FUSE_PRIMARY_SCHEME__='{primary}';"
        f"window.__FUSE_POP_HOST_MODE__='{pop}';"
        "</script>"
        f"{_prelogin_script(raw)}"
    )
    if marker not in html:
        raise ValueError('activity_index_head_missing')
    return html.replace(marker, script, 1)


def _run_surface_gates(app: Path) -> None:
    import sys
    factory_root = ROOT.parents[1]
    if str(factory_root) not in sys.path:
        sys.path.insert(0, str(factory_root))
    from factory.h5_webview_surface import check_broadcaster_ids, check_h5_external_links, check_open_native_browser
    index = (app / 'index.html').read_text(encoding='utf-8')
    problems = check_h5_external_links('index.html', index) + check_open_native_browser(index)
    dart = ROOT / 'lib/business/say_hi/robot_chat_manager.dart'
    if dart.is_file():
        problems.extend(check_broadcaster_ids(dart.read_text(encoding='utf-8'), require_official=True))
    if problems:
        raise ValueError('activity_surface_gate:' + ';'.join(problems[:8]))


def build(raw: dict, out: Path, *, flutter: str) -> dict:
    configuration(raw)
    problems = source_gate_problems()
    if problems:
        raise ValueError('activity_source_gate:' + ';'.join(problems))
    out.mkdir(parents=True, exist_ok=True)
    base = f"/activity/{raw['pkg']}/{raw['build_id']}/"
    if not (ROOT / '.dart_tool/package_config.json').is_file():
        subprocess.run([flutter, 'pub', 'get', '--offline'], cwd=ROOT, check=False)
    command = [
        flutter, 'build', 'web', '--no-pub', '--web-renderer=html',
        '--release', '--tree-shake-icons', f'--base-href={base}',
        f'--output={out / "app"}', *_defines(raw),
    ]
    version = subprocess.run([flutter, '--version', '--machine'], capture_output=True, text=True, check=False)
    try:
        version_ok = json.loads(version.stdout).get('flutterVersion') == '3.27.0'
    except Exception:
        version_ok = 'Flutter 3.27.0' in version.stdout
    if not version_ok:
        raise ValueError('flutter_version_mismatch:expected_3.27.0')
    result = subprocess.run(command, cwd=ROOT, check=False)
    if result.returncode:
        raise ValueError('activity_build_failed')
    app = out / 'app'
    for name in ('NOTICES', '.last_build_id'):
        path = app / name
        if path.is_file():
            path.unlink()
    canvaskit = app / 'canvaskit'
    if canvaskit.is_dir():
        shutil.rmtree(canvaskit)
    for path in app.rglob('*.map'):
        path.unlink()
    for path in app.rglob('*.symbols'):
        path.unlink()
    index = app / 'index.html'
    main_js = app / 'main.dart.js'
    if index.is_file():
        stamp = hashlib.sha256(main_js.read_bytes()).hexdigest()[:12] if main_js.is_file() else str(raw.get('build_id') or 'live')
        html = index.read_text(encoding='utf-8').replace('ttVersion123456', stamp)
        html = html.replace('href="main.dart.js"', f'href="main.dart.js?_v={stamp}"')
        html = html.replace('src="main.dart.js"', f'src="main.dart.js?_v={stamp}"')
        index.write_text(stamp_host(html, raw), encoding='utf-8')
    _run_surface_gates(app)
    resources = []
    for path in sorted(p for p in app.rglob('*') if p.is_file()):
        body = path.read_bytes()
        resources.append({'path': path.relative_to(app).as_posix(), 'sha256': hashlib.sha256(body).hexdigest(), 'size': len(body)})
    resources_sha256 = hashlib.sha256(json.dumps(resources, sort_keys=True, separators=(',', ':'), ensure_ascii=False).encode('utf-8')).hexdigest()
    manifest = {
        'schema_version': SCHEMA,
        'product_pkg': raw['pkg'],
        'build_id': raw['build_id'],
        'base': base,
        'entry': 'app/index.html',
        'build': 'pass',
        'typecheck': 'pass',
        'deployment_target': 'cloudflare_worker',
        'resources_sha256': resources_sha256,
        'resources': resources,
    }
    (out / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
    return manifest


def main(argv=None) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path)
    parser.add_argument('--out', type=Path)
    parser.add_argument('--prepare', action='store_true')
    parser.add_argument('--flutter', default=os.environ.get('FLUTTER_BIN', 'flutter'))
    args = parser.parse_args(argv)
    if args.prepare:
        snap = Path(args.out or 'out')
        if snap.exists():
            raise SystemExit('activity_output_exists')
        shutil.copytree(
            ROOT, snap / 'source',
            ignore=shutil.ignore_patterns('.dart_tool', 'build', '.git', 'ephemeral'),
            ignore_dangling_symlinks=True,
        )
        return 0
    if not args.config or not args.out:
        raise SystemExit('activity_config_and_out_required')
    raw = json.loads(args.config.read_text(encoding='utf-8'))
    build(raw, args.out, flutter=args.flutter)
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
