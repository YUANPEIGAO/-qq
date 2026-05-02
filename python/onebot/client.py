import asyncio
import json
import logging
import time
from websockets import connect, WebSocketClientProtocol, exceptions

logger = logging.getLogger(__name__)

class OneBotClient:
    def __init__(self, ws_url, access_token, message_handler):
        self.ws_url = ws_url
        self.access_token = access_token
        self.message_handler = message_handler
        self.websocket = None
        self.is_connected = False
        self.reconnect_count = 0
        self.max_reconnect_attempts = 10
        self.reconnect_interval = 5
        self.last_heartbeat = 0
        self.heartbeat_interval = 30
        self.qq_id = None
        
    async def connect(self):
        while self.reconnect_count < self.max_reconnect_attempts:
            try:
                logger.info(f"Connecting to {self.ws_url}...")
                self.websocket = await connect(self.ws_url)
                self.is_connected = True
                self.reconnect_count = 0
                logger.info("Connected successfully")
                
                await self._send_identify()
                
                await asyncio.gather(
                    self._receive_loop(),
                    self._heartbeat_loop()
                )
            except exceptions.ConnectionClosed:
                logger.warn("Connection closed, reconnecting...")
                self.is_connected = False
                self.reconnect_count += 1
                await asyncio.sleep(self.reconnect_interval)
            except Exception as e:
                logger.error(f"Connection error: {str(e)}")
                self.is_connected = False
                self.reconnect_count += 1
                await asyncio.sleep(self.reconnect_interval)
        
        logger.error(f"Max reconnect attempts ({self.max_reconnect_attempts}) exceeded")
    
    async def disconnect(self):
        self.is_connected = False
        if self.websocket:
            try:
                await self.websocket.close()
                logger.info("Disconnected")
            except Exception as e:
                logger.error(f"Error closing connection: {str(e)}")
    
    async def _send_identify(self):
        payload = {
            "op": 2,
            "d": {
                "token": self.access_token,
                "intents": 1 << 0 | 1 << 1 | 1 << 16,
                "shard": [0, 1]
            }
        }
        await self._send(payload)
    
    async def _heartbeat_loop(self):
        while self.is_connected:
            try:
                await asyncio.sleep(self.heartbeat_interval)
                if self.is_connected:
                    await self._send_heartbeat()
            except asyncio.CancelledError:
                break
            except Exception as e:
                logger.error(f"Heartbeat error: {str(e)}")
    
    async def _send_heartbeat(self):
        payload = {
            "op": 1,
            "d": int(time.time())
        }
        await self._send(payload)
        self.last_heartbeat = time.time()
    
    async def _receive_loop(self):
        while self.is_connected:
            try:
                message = await self.websocket.recv()
                await self._handle_message(message)
            except exceptions.ConnectionClosed:
                break
            except Exception as e:
                logger.error(f"Receive error: {str(e)}")
    
    async def _handle_message(self, message):
        try:
            data = json.loads(message)
            op = data.get('op', 0)
            
            if op == 0:
                await self._handle_event(data.get('d', {}))
            elif op == 11:
                logger.debug("Heartbeat ACK received")
            elif op == 10:
                self.heartbeat_interval = data.get('d', {}).get('heartbeat_interval', 30000) / 1000
                logger.debug(f"Heartbeat interval set to {self.heartbeat_interval}s")
        except json.JSONDecodeError:
            logger.error("Invalid JSON message")
        except Exception as e:
            logger.error(f"Error handling message: {str(e)}")
    
    async def _handle_event(self, event):
        try:
            event_type = event.get('post_type')
            
            if event_type == 'meta_event':
                await self._handle_meta_event(event)
            elif event_type == 'message':
                await self._handle_message_event(event)
        except Exception as e:
            logger.error(f"Error handling event: {str(e)}")
    
    async def _handle_meta_event(self, event):
        meta_type = event.get('meta_event_type')
        if meta_type == 'lifecycle':
            logger.info("Lifecycle event received")
        elif meta_type == 'heartbeat':
            pass
    
    async def _handle_message_event(self, event):
        message_type = event.get('message_type')
        user_id = event.get('user_id')
        group_id = event.get('group_id')
        message = event.get('message', '')
        raw_message = event.get('raw_message', '')
        
        logger.info(f"Received message: [{message_type}] {user_id}: {raw_message}")
        
        await self.message_handler.handle_message(event)
    
    async def _send(self, payload):
        if self.websocket and self.is_connected:
            try:
                await self.websocket.send(json.dumps(payload))
            except Exception as e:
                logger.error(f"Send error: {str(e)}")
    
    async def send_message(self, target_type, target_id, message):
        action = 'send_private_msg' if target_type == 'private' else 'send_group_msg'
        params = {
            'user_id' if target_type == 'private' else 'group_id': target_id,
            'message': message
        }
        
        payload = {
            'action': action,
            'params': params,
            'echo': int(time.time() * 1000)
        }
        
        await self._send(payload)
        logger.info(f"Sent {target_type} message to {target_id}: {message}")
    
    def get_status(self):
        return {
            'connected': self.is_connected,
            'qq_id': self.qq_id,
            'reconnect_count': self.reconnect_count,
            'last_heartbeat': self.last_heartbeat
        }