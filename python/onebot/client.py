"""OneBot WebSocket 客户端"""

import asyncio
import json
import logging
import time
from typing import Any, Callable, Coroutine
from datetime import datetime

import websockets
from websockets.asyncio.client import ClientConnection

logger = logging.getLogger(__name__)


class OneBotClient:
    """OneBot v11 WebSocket 客户端"""

    def __init__(self, ws_url: str, token: str = ""):
        self.ws_url = ws_url
        self.token = token
        self.ws: ClientConnection | None = None
        self._message_id = 0
        self._pending_responses: dict[str, asyncio.Future[dict[str, Any]]] = {}
        self._message_handler: (
            Callable[[dict[str, Any]], Coroutine[Any, Any, None]] | None
        ) = None
        self._running = False
        self._should_stop = False
        self.reconnect_count = 0

    def set_message_handler(
        self, handler: Callable[[dict[str, Any]], Coroutine[Any, Any, None]]
    ) -> None:
        """设置消息处理器"""
        self._message_handler = handler

    def connection_status(self) -> dict[str, Any]:
        """返回连接状态快照。"""
        ws = self.ws
        ws_exists = ws is not None
        ws_closed = (ws.close_code is not None) if ws is not None else True
        connected = ws_exists and (not ws_closed) and self._running
        return {
            "connected": connected,
            "running": self._running,
            "ws_exists": ws_exists,
            "ws_closed": ws_closed,
            "ws_url": self.ws_url,
            "reconnect_count": self.reconnect_count,
        }

    async def connect(self) -> None:
        """连接到 OneBot WebSocket"""
        url = self.ws_url
        if self.token:
            separator = "&" if "?" in url else "?"
            url = f"{url}{separator}access_token={self.token}"

        logger.info(f"[WebSocket] 正在连接到 {url}...")

        extra_headers = {}
        if self.token:
            extra_headers["Authorization"] = f"Bearer {self.token}"

        try:
            self.ws = await websockets.connect(
                url,
                ping_interval=20,
                ping_timeout=480,
                max_size=100 * 1024 * 1024,
                additional_headers=extra_headers if extra_headers else None,
            )
            logger.info("[WebSocket] 连接成功")
        except Exception as e:
            logger.error(f"[WebSocket] 连接失败: {e}")
            raise

    async def disconnect(self) -> None:
        """断开连接"""
        self._running = False
        self._should_stop = True
        if self.ws:
            logger.info("[WebSocket] 正在主动断开连接...")
            await self.ws.close()
            self.ws = None
            logger.info("[WebSocket] 连接已断开")

    async def _call_api(
        self,
        action: str,
        params: dict[str, Any] | None = None,
        *,
        suppress_error_retcodes: set[int] | None = None,
    ) -> dict[str, Any]:
        """调用 OneBot API"""
        if not self.ws:
            raise RuntimeError("WebSocket 未连接")

        self._message_id += 1
        echo = str(self._message_id)

        request = {
            "action": action,
            "params": params or {},
            "echo": echo,
        }

        logger.debug(f"[API请求] {action} (ID={echo}) | 参数: {params}")

        future: asyncio.Future[dict[str, Any]] = asyncio.Future()
        self._pending_responses[echo] = future

        start_time = time.perf_counter()

        try:
            await self.ws.send(json.dumps(request))
            response = await asyncio.wait_for(future, timeout=480.0)
            duration = time.perf_counter() - start_time

            status = response.get("status")
            if status == "failed":
                retcode = response.get("retcode", -1)
                msg = response.get("message", "未知错误")
                if suppress_error_retcodes and retcode in suppress_error_retcodes:
                    logger.warning(f"[API预期失败] {action} (ID={echo}) | 耗时={duration:.2f}s | retcode={retcode} | message={msg}")
                else:
                    logger.error(f"[API失败] {action} (ID={echo}) | 耗时={duration:.2f}s | retcode={retcode} | message={msg}")
                raise RuntimeError(f"API 调用失败: {msg} (retcode={retcode})")

            logger.info(f"[API成功] {action} (ID={echo}) | 耗时={duration:.2f}s")
            return response
        except asyncio.TimeoutError:
            duration = time.perf_counter() - start_time
            logger.error(f"[API超时] {action} (ID={echo}) | 耗时={duration:.2f}s")
            raise
        finally:
            self._pending_responses.pop(echo, None)

    async def send_group_message(
        self,
        group_id: int,
        message: str | list[dict[str, Any]],
    ) -> dict[str, Any]:
        """发送群消息"""
        return await self._call_api(
            "send_group_msg",
            {"group_id": group_id, "message": message},
        )

    async def send_private_message(
        self,
        user_id: int,
        message: str | list[dict[str, Any]],
        *,
        group_id: int | None = None,
    ) -> dict[str, Any]:
        """发送私聊消息"""
        params: dict[str, Any] = {
            "user_id": user_id,
            "message": message,
        }
        if group_id is not None:
            params["group_id"] = group_id

        return await self._call_api("send_private_msg", params)

    async def send_message(self, target_type: str, target_id: int, message: str):
        """统一发送消息接口"""
        action = 'send_private_msg' if target_type == 'private' else 'send_group_msg'
        params = {
            'user_id' if target_type == 'private' else 'group_id': target_id,
            'message': message
        }
        return await self._call_api(action, params)

    async def run(self) -> None:
        """运行消息接收循环"""
        if not self.ws:
            raise RuntimeError("WebSocket 未连接")

        self._running = True
        self._tasks: set[asyncio.Task[None]] = set()
        logger.info("[WebSocket] 消息接收循环已启动")

        try:
            while self._running:
                raw_message = ""
                try:
                    message_data = await self.ws.recv()
                    raw_message = (
                        message_data.decode("utf-8")
                        if isinstance(message_data, bytes)
                        else message_data
                    )
                    data = json.loads(raw_message)
                    await self._dispatch_message(data)
                except json.JSONDecodeError as e:
                    logger.error(f"[WebSocket] 无法解析 JSON 消息: {raw_message!r}, 错误: {e}")
                except websockets.ConnectionClosed:
                    logger.warning("[WebSocket] 连接已关闭，接收循环结束")
                    break
                except Exception as e:
                    logger.exception(f"[WebSocket] 接收消息时发生异常: {e}")
        finally:
            self._running = False
            if self._tasks:
                await asyncio.gather(*self._tasks, return_exceptions=True)
            logger.info("[WebSocket] 接收循环已停止")

    async def _dispatch_message(self, data: dict[str, Any]) -> None:
        """分发消息"""
        echo = data.get("echo")
        if echo is not None:
            echo_str = str(echo)
            if echo_str in self._pending_responses:
                self._pending_responses[echo_str].set_result(data)
                return

        post_type = data.get("post_type")
        if post_type == "message":
            msg_type = data.get("message_type", "unknown")
            sender = data.get("sender", {}).get("user_id", "unknown")
            logger.info(f"[收到消息] type={msg_type}, sender={sender}")
            if self._message_handler:
                task = asyncio.create_task(self._safe_handle_message(data))
                self._tasks.add(task)
                task.add_done_callback(self._tasks.discard)
        elif post_type == "notice":
            notice_type = data.get("notice_type", "")
            sub_type = data.get("sub_type", "")
            if notice_type == "notify" and sub_type == "poke":
                target_id = data.get("target_id", 0)
                sender_id = data.get("user_id", 0)
                group_id = data.get("group_id", 0)
                logger.info(f"[收到拍一拍] sender={sender_id}, target={target_id}, group={group_id}")

    async def _safe_handle_message(self, data: dict[str, Any]) -> None:
        """安全地处理消息"""
        try:
            if self._message_handler:
                await self._message_handler(data)
        except Exception as e:
            logger.exception(f"处理消息时出错: {e}")

    async def run_with_reconnect(self, reconnect_interval: float = 5.0, max_reconnect_attempts: int = 10) -> None:
        """带自动重连的运行"""
        self._should_stop = False
        self.reconnect_count = 0

        while not self._should_stop:
            try:
                if self.reconnect_count > 0:
                    logger.info(f"[WebSocket] 正在尝试第 {self.reconnect_count} 次重连...")
                await self.connect()
                self.reconnect_count = 0
                await self.run()
            except websockets.ConnectionClosed as e:
                logger.warning(f"[WebSocket] 连接已断开: {e}")
            except Exception as e:
                logger.error(f"[WebSocket] 发生错误: {e}")

            if self._should_stop:
                break

            if max_reconnect_attempts > 0 and self.reconnect_count >= max_reconnect_attempts:
                logger.error(f"[WebSocket] 已达到最大重连次数 ({max_reconnect_attempts})")
                break

            self.reconnect_count += 1
            logger.info(f"{reconnect_interval} 秒后尝试重连...")
            await asyncio.sleep(reconnect_interval)

    def stop(self) -> None:
        """停止运行"""
        self._should_stop = True
        self._running = False


def parse_message_time(message: dict[str, Any]) -> datetime:
    """解析消息时间"""
    raw_timestamp = message.get("time")

    if raw_timestamp is None:
        return datetime.now()

    try:
        timestamp = float(raw_timestamp)
    except (TypeError, ValueError):
        return datetime.now()

    if timestamp > 1_000_000_000_000:
        timestamp /= 1000.0

    if timestamp <= 0:
        return datetime.now()

    try:
        return datetime.fromtimestamp(timestamp)
    except (OSError, OverflowError, ValueError):
        return datetime.now()


def get_message_sender_id(message: dict[str, Any]) -> int:
    """获取消息发送者 QQ 号"""
    sender: dict[str, Any] = message.get("sender", {})
    user_id: int = sender.get("user_id", 0)
    return user_id


def get_message_content(message: dict[str, Any]) -> list[dict[str, Any]]:
    """获取消息内容（CQ 码数组格式）"""
    msg = message.get("message", [])
    if isinstance(msg, str):
        return [{"type": "text", "data": {"text": msg}}]
    content: list[dict[str, Any]] = msg
    return content