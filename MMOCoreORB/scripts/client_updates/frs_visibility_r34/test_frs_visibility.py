"""Exercise the real builder visibility block against the stock Pre-CU table."""
import ast
import copy
import importlib.util
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parent
spec = importlib.util.spec_from_file_location('swgtool', Path.home() / '.claude/skills/swgemu-developer/scripts/swgtool.py')
swg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(swg)


class FrsVisibilityTests(unittest.TestCase):
    def setUp(self):
        self.stock = swg.dt_read((ROOT / 'stock_skills.iff').read_bytes())
        self.col = {name: i for i, name in enumerate(self.stock['columns'])}
        tree = ast.parse((ROOT / 'build_tre.py').read_text())
        blocks = [node for node in tree.body if isinstance(node, ast.If)
                  and isinstance(node.test, ast.Name) and node.test.id == 'HIDE_RETIRED']
        self.assertEqual(len(blocks), 1)
        self.result = copy.deepcopy(self.stock)
        namespace = dict(skills=self.result, HIDE_RETIRED=True, re=re, report=[],
                         NAME=self.col['NAME'], GOD=self.col['GOD_ONLY'], HID=self.col['IS_HIDDEN'])
        exec(compile(ast.Module(body=blocks, type_ignores=[]), 'builder-visibility', 'exec'), namespace)

    def test_frs_retains_exact_stock_visibility_and_gameplay(self):
        name = self.col['NAME']
        pairs = [(old, new) for old, new in zip(self.stock['rows'], self.result['rows'])
                 if old[name] == 'force_rank' or old[name].startswith('force_rank_')]
        self.assertEqual(len(pairs), 27)
        for old, new in pairs:
            self.assertEqual(new, old, old[name])
            self.assertEqual(new[self.col['IS_HIDDEN']], 0)
            self.assertEqual(new[self.col['GOD_ONLY']], int(old[name] == 'force_rank'))

    def test_only_retired_sensitive_discipline_title_visibility_changes(self):
        count = 0
        for old, new in zip(self.stock['rows'], self.result['rows']):
            expected = list(old)
            if re.match(r'force_(sensitive|discipline|title)', old[self.col['NAME']]):
                expected[self.col['GOD_ONLY']] = expected[self.col['IS_HIDDEN']] = 1
                count += 1
            self.assertEqual(new, expected, old[self.col['NAME']])
        self.assertGreater(count, 100)


if __name__ == '__main__':
    unittest.main(verbosity=2)
