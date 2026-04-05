import io
import logging
import numpy as np
from openai import OpenAI

logger = logging.getLogger(__name__)


class WhisperSTT:
    """Speech-to-text using OpenAI Whisper API."""

    def __init__(self, api_key: str, language: str = "es"):
        self._client = OpenAI(api_key=api_key)
        self._language = language

    def transcribe(self, audio_data: np.ndarray, sample_rate: int = 16000) -> str:
        """Transcribe audio numpy array to text."""
        try:
            # Convert to WAV bytes
            import wave
            buf = io.BytesIO()
            with wave.open(buf, 'wb') as wf:
                wf.setnchannels(1)
                wf.setsampwidth(2)  # 16-bit
                wf.setframerate(sample_rate)
                wf.writeframes((audio_data * 32767).astype(np.int16).tobytes())

            buf.seek(0)
            buf.name = "audio.wav"

            result = self._client.audio.transcriptions.create(
                model="whisper-1",
                file=buf,
                language=self._language,
            )

            text = result.text.strip()
            logger.info(f"Transcribed: {text}")
            return text

        except Exception as e:
            logger.error(f"Whisper transcription error: {e}")
            return ""


class MockSTT:
    """Mock STT for testing without API calls."""

    def transcribe(self, audio_data: np.ndarray, sample_rate: int = 16000) -> str:
        logger.info("[MOCK] STT: returning test phrase")
        return "Que medicamentos tengo que tomar hoy"
