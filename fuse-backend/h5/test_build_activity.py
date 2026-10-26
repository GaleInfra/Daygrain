import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parent


def _load():
    spec = importlib.util.spec_from_file_location('build_activity', ROOT / 'build_activity.py')
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


class BuildActivityTests(unittest.TestCase):
    def test_configuration_validates_fields(self):
        module = _load()
        valid = {
            'schema_version': module.SCHEMA,
            'pkg': 'at.timavo.selfseal',
            'build_id': 'dev',
            'api_host': 'https://app.latergate.org',
            'socket_url': 'wss://im.latergate.org',
            'broadcaster_env': 'prod',
            'pop_host_mode': 'pop',
        }
        self.assertEqual(module.configuration(valid)['pkg'], 'at.timavo.selfseal')
        with self.assertRaises(ValueError):
            module.configuration({**valid, 'broadcaster_env': 'staging'})

    def test_socket_url_must_be_im_domain(self):
        module = _load()
        base = {
            'schema_version': module.SCHEMA,
            'pkg': 'at.timavo.selfseal',
            'build_id': 'live',
            'api_host': 'https://qura.accesstrace.org',
        }
        with self.assertRaisesRegex(ValueError, 'activity_socket_url_missing'):
            module.configuration(base)
        with self.assertRaisesRegex(ValueError, 'activity_socket_url_is_api_host'):
            module.configuration({**base, 'socket_url': 'https://qura.accesstrace.org'})
        defines = module._defines({**base, 'socket_url': 'wss://yepa.accesstrace.org'})
        self.assertIn('--dart-define=SOCKET_URL=https://yepa.accesstrace.org', defines)

    def test_source_gate_blocks_shipped_chat_and_recharge_defects(self):
        module = _load()
        self.assertEqual(module.source_gate_problems(), [])
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            card = root / 'lib/pages/message/message_chat/widget/chat_bubble_widget.dart'
            card.parent.mkdir(parents=True)
            card.write_text('await JSRongCloudManager.myBrowser(url, 0, 1);', encoding='utf-8')
            (root / 'lib/main.dart').write_text('socketUrl: socketUrl ?? BakedConfig.socketUrl,', encoding='utf-8')
            problems = module.source_gate_problems(root)
        self.assertEqual(len(problems), 2)

    def test_source_gate_requires_lifecycle_bridge(self):
        module = _load()
        self.assertEqual(module.source_gate_problems(), [])
        index = (ROOT / 'web/index.html').read_text(encoding='utf-8')
        self.assertIn("document.visibilityState === 'hidden' ? 'paused' : 'resumed'", index)
        self.assertIn('state === lastLifecycle', index)
        self.assertIn("window.__fusePayResume('')", index)
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / 'web').mkdir()
            (root / 'web/index.html').write_text('<script></script>', encoding='utf-8')
            card = root / 'lib/pages/message/message_chat/widget/chat_bubble_widget.dart'
            card.parent.mkdir(parents=True)
            card.write_text('await JSRongCloudManager.myBrowser(url, 0, 1);', encoding='utf-8')
            (root / 'lib/main.dart').write_text('socketUrl: socketUrl ?? BakedConfig.socketUrl,', encoding='utf-8')
            (root / 'lib/my_app.dart').write_text('throttleUtil.throttle(() async {});', encoding='utf-8')
            problems = module.source_gate_problems(root)
        for problem in (
            'lifecycle bridge missing visibilitychange -> onLifecycleState',
            'lifecycle bridge missing pagehide -> paused',
            'my_app paused report still waits for throttle',
            'my_app missing web lifecycle dedupe',
        ):
            self.assertIn(problem, problems)

    def test_stamp_host_injects_scheme_and_pop_mode(self):
        module = _load()
        stamped = module.stamp_host('<head><title>App</title></head>', {
            'local_scheme': 'timavo-local',
            'pop_host_mode': 'page',
        })
        self.assertIn("window.__FUSE_LOCAL_SCHEME__='timavo-local'", stamped)
        self.assertIn("window.__FUSE_PRIMARY_SCHEME__='timavo'", stamped)
        self.assertIn("window.__FUSE_POP_HOST_MODE__='page'", stamped)
        self.assertNotIn('Max-Age=0', stamped)

    def test_product_allowlist_is_validated_and_defined(self):
        module = _load()
        valid = {
            'schema_version': module.SCHEMA,
            'pkg': 'xycoins.2027.test',
            'build_id': 'sbx2',
            'api_host': 'https://test-app.dirth.quest',
            'socket_url': 'https://test-im.dirth.quest',
            'product_allowlist': '666666001:500:1.99',
        }
        module.configuration(valid)
        self.assertIn('--dart-define=PRODUCT_ALLOWLIST=666666001:500:1.99', module._defines(valid))
        self.assertFalse(any('PRODUCT_ALLOWLIST' in item for item in module._defines({**valid, 'product_allowlist': ''})))
        with self.assertRaises(ValueError):
            module.configuration({**valid, 'product_allowlist': '666666001:$1.99'})

    def test_splitbite_defines_separate_pkg_and_burn_cookie(self):
        module = _load()
        raw = {
            'schema_version': module.SCHEMA,
            'pkg': 'by.splitbite.woodcut',
            'package_name': 'com.splitbite.woodcut',
            'build_id': 'v1_0_2',
            'api_host': 'https://app.splitbitegate.org/api/mill',
            'log_url': 'https://app.splitbitegate.org/api/mill-log',
            'socket_url': 'wss://deride.netbranch.org',
            'privacy_url': 'splitbite-local://legal/privacy',
            'terms_url': 'splitbite-local://legal/terms',
            'local_scheme': 'splitbite-local',
            'pop_host_mode': 'page',
            'keys': ['jaunting', 'overhauled', 'auburn', 'atropos'],
        }
        module.configuration(raw)
        defines = module._defines(raw)
        self.assertIn('--dart-define=PACKAGE_NAME=com.splitbite.woodcut', defines)
        self.assertIn('--dart-define=BASE_URL=https://app.splitbitegate.org/api/mill', defines)
        self.assertIn('--dart-define=PRIVACY_POLICY=splitbite-local://legal/privacy', defines)
        self.assertTrue(any(item.startswith('--dart-define=PRELOGIN_WINDOW_SLOT=__') for item in defines))
        stamped = module.stamp_host('<head><title>App</title></head>', raw)
        self.assertIn('Max-Age=0', stamped)
        self.assertIn("DecompressionStream('deflate-raw')", stamped)
        self.assertIn('crypto.subtle.decrypt', stamped)
        self.assertIn('by.splitbite.woodcut', stamped)

    def test_prepare_copies_source_tree(self):
        module = _load()
        with tempfile.TemporaryDirectory() as tmp:
            out = Path(tmp) / 'snap'
            rc = module.main(['--prepare', '--out', str(out)])
            self.assertEqual(rc, 0)
            self.assertTrue((out / 'source/pubspec.yaml').is_file())
            lock = json.loads((out / 'source/h5_source_lock.json').read_text(encoding='utf-8'))
            self.assertEqual(lock['flutter_version'], '3.27.0')
            self.assertTrue(lock['auto_login'])
            self.assertFalse(lock['h5_auto_retry'])

    def test_vip_sheet_web_safe_gate(self):
        module = _load()
        self.assertEqual(module.source_gate_problems(), [])
        vip = (ROOT / 'lib/widget/vip/vip_privileges_sheet.dart').read_text(encoding='utf-8')
        self.assertIn('kIsWeb', vip)
        self.assertIn('networkUrl', vip)
        self.assertIn('assetsPrefix', vip)
        self.assertIn('setVolume(1)', vip)
        self.assertIn('setVolume(0)', vip)
        self.assertIn('_unmuteWebBackground', vip)
        self.assertIn('onPointerDown', vip)
        self.assertNotIn('_enableBgVideo = !kIsWeb', vip)
        self.assertIn('VideoPlayer(active)', vip)
        self.assertIn('shouldGateNonVip', vip)
        self.assertIn('shouldShowVipEntry', vip)
        handler = (ROOT / 'lib/common_logic/video_call_handler.dart').read_text(encoding='utf-8')
        self.assertIn('VipPrivilegesSheet.shouldGateNonVip()', handler)
        match_logic = (ROOT / 'lib/pages/flash_chat/logic.dart').read_text(encoding='utf-8')
        self.assertIn('VipPrivilegesSheet.shouldGateNonVip()', match_logic)
        self.assertIn('.timeout(const Duration(seconds: 3)', match_logic)
        mine = (ROOT / 'lib/pages/mine/view.dart').read_text(encoding='utf-8')
        self.assertIn('VipPrivilegesSheet.shouldShowVipEntry()', mine)
        match_view = (ROOT / 'lib/pages/flash_chat/view.dart').read_text(encoding='utf-8')
        self.assertIn('VipPrivilegesSheet.shouldShowVipEntry()', match_view)
        perm = (ROOT / 'lib/utils/permission_util.dart').read_text(encoding='utf-8')
        self.assertIn('.timeout(', perm)
        self.assertNotIn("facingMode': 'environment'", perm)

    def test_exchange_days_counts_as_vip_term(self):
        module = _load()
        self.assertEqual(module.source_gate_problems(), [])
        model = (ROOT / 'lib/model/mine/coin_goods_model.dart').read_text(encoding='utf-8')
        logic = (ROOT / 'lib/common_logic/coin_goods_logic.dart').read_text(encoding='utf-8')
        page = (ROOT / 'lib/pages/vip/vip_privileges_page.dart').read_text(encoding='utf-8')
        sheet = (ROOT / 'lib/widget/vip/vip_privileges_sheet.dart').read_text(encoding='utf-8')
        self.assertIn("json['exchangeDays']", model)
        self.assertIn("json['validDays']", model)
        self.assertIn('if (validity != null) return true;', model)
        self.assertIn('if (validDays != null && validDays! > 0) return true;', model)
        self.assertIn('if (exchangeDays != null && exchangeDays! > 0) return true;', model)
        self.assertIn('if (item.isVipTerm)', logic)
        self.assertIn('resolveVipPurchase', logic)
        self.assertIn('resolveVipPurchase(_selectedProduct)', page)
        self.assertIn('resolveVipPurchase(_selectedProduct)', sheet)


if __name__ == '__main__':
    unittest.main()
