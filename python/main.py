import sys
import os
import asyncio
import json
import logging
from pathlib import Path

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from onebot.client import OneBotClient
from message_handler import MessageHandler
from rule_manager import RuleManager

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[logging.StreamHandler()]
)

logger = logging.getLogger(__name__)

client = None
handler = None
rule_manager = None
is_running = False

def init_bot(config):
    global client, handler, rule_manager
    ws_url = config.get('ws_url', 'ws://localhost:8080')
    access_token = config.get('access_token', '')
    
    rule_manager = RuleManager()
    handler = MessageHandler(rule_manager)
    client = OneBotClient(ws_url, access_token, handler)
    
    logger.info(f"Bot initialized with WS URL: {ws_url}")

async def start_bot():
    global is_running
    if is_running:
        logger.warn("Bot is already running")
        return
    
    is_running = True
    logger.info("Starting bot...")
    
    try:
        await client.connect()
    except Exception as e:
        logger.error(f"Failed to start bot: {str(e)}")
        is_running = False
        raise

async def stop_bot():
    global is_running
    if not is_running:
        logger.warn("Bot is not running")
        return
    
    is_running = False
    logger.info("Stopping bot...")
    
    try:
        await client.disconnect()
    except Exception as e:
        logger.error(f"Error stopping bot: {str(e)}")

def add_rule(rule):
    if rule_manager:
        rule_manager.add_rule(rule)
        logger.info(f"Rule added: {rule.get('keyword', 'unknown')}")

def remove_rule(rule_id):
    if rule_manager:
        rule_manager.remove_rule(rule_id)
        logger.info(f"Rule removed: {rule_id}")

def update_rule(rule_id, updated_rule):
    if rule_manager:
        rule_manager.update_rule(rule_id, updated_rule)
        logger.info(f"Rule updated: {rule_id}")

def get_rules():
    if rule_manager:
        return rule_manager.get_all_rules()
    return []

def import_rules(rules):
    if rule_manager:
        rule_manager.import_rules(rules)
        logger.info(f"Imported {len(rules)} rules")

def export_rules():
    if rule_manager:
        return rule_manager.export_rules()
    return []

def set_log_level(level):
    levels = {
        'debug': logging.DEBUG,
        'info': logging.INFO,
        'warn': logging.WARNING,
        'error': logging.ERROR
    }
    logger.setLevel(levels.get(level, logging.INFO))
    logger.info(f"Log level set to: {level}")

def get_stats():
    if handler:
        return handler.get_stats()
    return {
        'received_messages': 0,
        'replied_messages': 0,
        'running_time': 0,
        'reconnect_count': 0
    }

if __name__ == '__main__':
    pass