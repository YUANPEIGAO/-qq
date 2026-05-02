import json
import os
import logging

logger = logging.getLogger(__name__)

class RuleManager:
    def __init__(self):
        self.rules = []
        self.rule_id_counter = 1
        self.load_rules()
    
    def load_rules(self):
        try:
            from pathlib import Path
            rules_dir = Path(__file__).parent.parent / 'data'
            rules_dir.mkdir(exist_ok=True)
            rules_file = rules_dir / 'rules.json'
            
            if rules_file.exists():
                with open(rules_file, 'r', encoding='utf-8') as f:
                    self.rules = json.load(f)
                    if self.rules:
                        self.rule_id_counter = max(r['id'] for r in self.rules) + 1
                logger.info(f"Loaded {len(self.rules)} rules")
            else:
                self.rules = self._get_default_rules()
                self.save_rules()
        except Exception as e:
            logger.error(f"Error loading rules: {str(e)}")
            self.rules = self._get_default_rules()
    
    def save_rules(self):
        try:
            from pathlib import Path
            rules_dir = Path(__file__).parent.parent / 'data'
            rules_dir.mkdir(exist_ok=True)
            rules_file = rules_dir / 'rules.json'
            
            with open(rules_file, 'w', encoding='utf-8') as f:
                json.dump(self.rules, f, ensure_ascii=False, indent=2)
            logger.info(f"Saved {len(self.rules)} rules")
        except Exception as e:
            logger.error(f"Error saving rules: {str(e)}")
    
    def _get_default_rules(self):
        return [
            {
                'id': 1,
                'keyword': '你好',
                'match_mode': 'exact',
                'trigger_scope': 'all',
                'reply_content': '你好！我是QQ聊天机器人，很高兴为你服务！',
                'reply_type': 'text',
                'rate_limit': 1,
                'enabled': True
            },
            {
                'id': 2,
                'keyword': '帮助',
                'match_mode': 'fuzzy',
                'trigger_scope': 'all',
                'reply_content': '我可以自动回复消息。你可以在规则管理页面添加自定义回复规则。',
                'reply_type': 'text',
                'rate_limit': 1,
                'enabled': True
            }
        ]
    
    def add_rule(self, rule):
        new_rule = {
            'id': self.rule_id_counter,
            'keyword': rule.get('keyword', ''),
            'match_mode': rule.get('match_mode', 'exact'),
            'trigger_scope': rule.get('trigger_scope', 'all'),
            'reply_content': rule.get('reply_content', ''),
            'reply_type': rule.get('reply_type', 'text'),
            'rate_limit': rule.get('rate_limit', 1),
            'enabled': rule.get('enabled', True)
        }
        self.rules.append(new_rule)
        self.rule_id_counter += 1
        self.save_rules()
        return new_rule
    
    def remove_rule(self, rule_id):
        self.rules = [r for r in self.rules if r['id'] != rule_id]
        self.save_rules()
    
    def update_rule(self, rule_id, updated_rule):
        for i, rule in enumerate(self.rules):
            if rule['id'] == rule_id:
                self.rules[i].update(updated_rule)
                self.save_rules()
                return True
        return False
    
    def get_all_rules(self):
        return self.rules
    
    def get_enabled_rules(self):
        return [r for r in self.rules if r.get('enabled', True)]
    
    def toggle_rule(self, rule_id):
        for rule in self.rules:
            if rule['id'] == rule_id:
                rule['enabled'] = not rule['enabled']
                self.save_rules()
                return rule['enabled']
        return False
    
    def import_rules(self, rules):
        for rule in rules:
            if 'id' in rule:
                del rule['id']
            self.add_rule(rule)
    
    def export_rules(self):
        return self.rules
    
    def clear_rules(self):
        self.rules = []
        self.rule_id_counter = 1
        self.save_rules()
    
    def batch_toggle(self, rule_ids, enabled):
        for rule in self.rules:
            if rule['id'] in rule_ids:
                rule['enabled'] = enabled
        self.save_rules()
    
    def batch_delete(self, rule_ids):
        self.rules = [r for r in self.rules if r['id'] not in rule_ids]
        self.save_rules()