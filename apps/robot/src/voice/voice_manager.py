import asyncio
import logging
import json
import numpy as np
from typing import Protocol

logger = logging.getLogger(__name__)

SAMPLE_RATE = 16000
RECORD_SECONDS = 5
SILENCE_THRESHOLD = 0.01


class STTProtocol(Protocol):
    def transcribe(self, audio_data: np.ndarray, sample_rate: int = 16000) -> str: ...


class TTSProtocol(Protocol):
    def speak(self, text: str) -> None: ...
    def stop(self) -> None: ...


class VoiceManager:
    """
    Orchestrates the voice interaction loop:
    Listen (mic) -> STT -> JARVIS API -> TTS (speaker)
    """

    def __init__(
        self,
        stt: STTProtocol,
        tts: TTSProtocol,
        jarvis_url: str,
        jarvis_api_key: str,
        user_id: str,
        mock_audio: bool = False,
    ):
        self._stt = stt
        self._tts = tts
        self._jarvis_url = jarvis_url.rstrip('/')
        self._api_key = jarvis_api_key
        self._user_id = user_id
        self._mock_audio = mock_audio
        self._conversation_id: str | None = None
        self._running = False
        self._listening = False

    async def start(self) -> None:
        self._running = True
        logger.info("Voice manager started. Say something or press button.")

    async def stop(self) -> None:
        self._running = False
        self._tts.stop()
        logger.info("Voice manager stopped")

    async def process_voice_input(self) -> str | None:
        """Record audio, transcribe, send to JARVIS, speak response."""
        if not self._running:
            return None

        # 1. Record audio
        audio = self._record_audio()
        if audio is None:
            return None

        # 2. Speech-to-text
        text = self._stt.transcribe(audio, SAMPLE_RATE)
        if not text:
            logger.info("No speech detected")
            return None

        logger.info(f"Patient said: {text}")

        # 3. Send to JARVIS patient endpoint
        response = await self._send_to_jarvis(text)
        if not response:
            response = "Disculpa, no pude procesar tu pregunta. Intenta de nuevo."

        logger.info(f"JARVIS response: {response}")

        # 4. Text-to-speech
        self._tts.speak(response)

        return response

    def _record_audio(self) -> np.ndarray | None:
        """Record audio from microphone."""
        if self._mock_audio:
            # Return silence for mock mode - STT mock will return test text
            return np.zeros(SAMPLE_RATE * 2, dtype=np.float32)

        try:
            import sounddevice as sd
            logger.info("Listening...")
            self._listening = True
            audio = sd.rec(
                int(RECORD_SECONDS * SAMPLE_RATE),
                samplerate=SAMPLE_RATE,
                channels=1,
                dtype='float32'
            )
            sd.wait()
            self._listening = False

            # Check if there's actual audio (not just silence)
            if np.max(np.abs(audio)) < SILENCE_THRESHOLD:
                return None

            return audio.flatten()

        except Exception as e:
            logger.error(f"Audio recording error: {e}")
            self._listening = False
            return None

    async def _send_to_jarvis(self, message: str) -> str:
        """Send message to JARVIS patient endpoint and get response."""
        try:
            import aiohttp
            url = f"{self._jarvis_url}/api/chat/patient"
            headers = {
                'Content-Type': 'application/json',
                'Authorization': f'Bearer {self._api_key}'
            }
            payload = {
                'message': message,
                'conversationId': self._conversation_id,
                'source': 'robot',
                'userId': self._user_id,
                'context': {
                    'time': __import__('datetime').datetime.now().isoformat(),
                    'timezone': 'America/Mexico_City'
                }
            }

            async with aiohttp.ClientSession() as session:
                async with session.post(url, json=payload, headers=headers) as resp:
                    if resp.status == 200:
                        data = await resp.json()
                        self._conversation_id = data.get('conversationId')
                        return data.get('response', '')
                    else:
                        error = await resp.text()
                        logger.error(f"JARVIS API error ({resp.status}): {error}")
                        return ""

        except Exception as e:
            logger.error(f"JARVIS API call failed: {e}")
            return ""

    @property
    def is_listening(self) -> bool:
        return self._listening
