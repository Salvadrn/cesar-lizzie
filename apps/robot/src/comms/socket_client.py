import asyncio
import logging
import socketio

logger = logging.getLogger(__name__)


class RobotSocketClient:
    """Async Socket.IO client for communicating with the backend."""

    def __init__(self, server_url: str, robot_id: str, api_key: str, namespace: str = "/robot"):
        self._url = server_url
        self._robot_id = robot_id
        self._api_key = api_key
        self._namespace = namespace
        self._sio = socketio.AsyncClient(reconnection=True, reconnection_delay=2)
        self._connected = False
        self._command_handler: callable | None = None

        self._sio.on("connect", self._on_connect, namespace=namespace)
        self._sio.on("disconnect", self._on_disconnect, namespace=namespace)
        self._sio.on("robot:command", self._on_command, namespace=namespace)

    async def connect(self) -> None:
        try:
            await self._sio.connect(
                self._url,
                namespaces=[self._namespace],
                auth={"robotId": self._robot_id, "apiKey": self._api_key},
            )
        except Exception as e:
            logger.error(f"Connection failed: {e}")
            self._connected = False

    async def disconnect(self) -> None:
        if self._connected:
            await self._sio.disconnect()

    async def emit_telemetry(self, data: dict) -> None:
        if self._connected:
            await self._sio.emit("robot:telemetry", data, namespace=self._namespace)

    async def emit_status_change(self, state: str) -> None:
        if self._connected:
            await self._sio.emit("robot:status_change", {"state": state}, namespace=self._namespace)

    async def emit_emergency(self, reason: str) -> None:
        if self._connected:
            await self._sio.emit("robot:emergency", {"reason": reason}, namespace=self._namespace)

    def on_command(self, handler: callable) -> None:
        self._command_handler = handler

    @property
    def connected(self) -> bool:
        return self._connected

    async def _on_connect(self) -> None:
        self._connected = True
        logger.info("Connected to backend")

    async def _on_disconnect(self) -> None:
        self._connected = False
        logger.warning("Disconnected from backend")

    async def _on_command(self, data: dict) -> None:
        logger.info(f"Command received: {data}")
        if self._command_handler:
            await self._command_handler(data)
