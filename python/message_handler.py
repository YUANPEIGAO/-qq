import asyncio
import logging
import re
import time

logger = logging.getLogger(__name__)

class MessageHandler:
    def __init__(self, rule_manager):
        self.rule_manager = rule_manager
        self.received_messages = 0
        self.replied_messages = 0
        self.start_time = 0
        self.last_message_time = {}
        self.global_reply_enabled = True
        self.private_enabled = True
        self.group_enabled = True
        self.whitelist = []
        self.blacklist = []
    
    async def handle_message(self, event):
        try:
            self.received_messages += 1
            message_type = event.get('message_type')
            user_id = event.get('user_id')
            group_id = event.get('group_id')
            raw_message = event.get('raw_message', '')
            
            if not self.global_reply_enabled:
                return
            
            if message_type == 'private' and not self.private_enabled:
                return
            
            if message_type == 'group' and not self.group_enabled:
                return
            
            if self.blacklist and user_id in self.blacklist:
                logger.info(f"User {user_id} is in blacklist, ignoring")
                return
            
            if self.whitelist and user_id not in self.whitelist:
                logger.info(f"User {user_id} is not in whitelist, ignoring")
                return
            
            reply = await self._match_rules(raw_message, event)
            
            if reply:
                target_type = 'private' if message_type == 'private' else 'group'
                target_id = user_id if message_type == 'private' else group_id
                
                if await self._check_rate_limit(target_id):
                    await self._send_reply(target_type, target_id, reply)
                    self.replied_messages += 1
                    
        except Exception as e:
            logger.error(f"Error handling message: {str(e)}")
    
    async def _match_rules(self, message, event):
        rules = self.rule_manager.get_enabled_rules()
        
        for rule in rules:
            keyword = rule.get('keyword', '')
            match_mode = rule.get('match_mode', 'exact')
            reply_content = rule.get('reply_content', '')
            trigger_scope = rule.get('trigger_scope', 'all')
            
            if not await self._check_scope(event, trigger_scope):
                continue
            
            if await self._match_keyword(message, keyword, match_mode):
                logger.info(f"Rule matched: {keyword}")
                return reply_content
        
        return None
    
    async def _match_keyword(self, message, keyword, match_mode):
        if match_mode == 'exact':
            return message.strip() == keyword
        elif match_mode == 'fuzzy':
            return keyword in message
        elif match_mode == 'regex':
            try:
                return bool(re.search(keyword, message))
            except re.error:
                logger.error(f"Invalid regex pattern: {keyword}")
                return False
        return False
    
    async def _check_scope(self, event, trigger_scope):
        message_type = event.get('message_type')
        group_id = event.get('group_id')
        user_id = event.get('user_id')
        
        if trigger_scope == 'all':
            return True
        elif trigger_scope == 'all_groups':
            return message_type == 'group'
        elif trigger_scope == 'all_private':
            return message_type == 'private'
        elif trigger_scope.startswith('group_'):
            return message_type == 'group' and group_id == int(trigger_scope.split('_')[1])
        elif trigger_scope.startswith('user_'):
            return message_type == 'private' and user_id == int(trigger_scope.split('_')[1])
        
        return True
    
    async def _check_rate_limit(self, target_id):
        now = time.time()
        last_time = self.last_message_time.get(target_id, 0)
        min_interval = 1
        
        if now - last_time >= min_interval:
            self.last_message_time[target_id] = now
            return True
        
        logger.info(f"Rate limit hit for {target_id}")
        return False
    
    async def _send_reply(self, target_type, target_id, reply):
        from main import client
        if client and client.is_connected:
            await client.send_message(target_type, target_id, reply)
    
    def get_stats(self):
        running_time = int(time.time() - self.start_time) if self.start_time > 0 else 0
        return {
            'received_messages': self.received_messages,
            'replied_messages': self.replied_messages,
            'running_time': running_time,
            'reconnect_count': 0
        }
    
    def start(self):
        self.start_time = time.time()
        self.received_messages = 0
        self.replied_messages = 0
    
    def stop(self):
        pass
    
    def set_global_reply(self, enabled):
        self.global_reply_enabled = enabled
    
    def set_private_enabled(self, enabled):
        self.private_enabled = enabled
    
    def set_group_enabled(self, enabled):
        self.group_enabled = enabled
    
    def set_whitelist(self, users):
        self.whitelist = users
    
    def set_blacklist(self, users):
        self.blacklist = users