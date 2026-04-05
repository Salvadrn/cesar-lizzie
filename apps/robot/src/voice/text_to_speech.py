import logging

logger = logging.getLogger(__name__)


class PyttsxTTS:
    """Text-to-speech using pyttsx3 (offline, runs on RPi)."""

    def __init__(self, rate: int = 150, voice_lang: str = "es"):
        import pyttsx3
        self._engine = pyttsx3.init()
        self._engine.setProperty('rate', rate)

        # Try to find a Spanish voice
        for voice in self._engine.getProperty('voices'):
            if voice_lang in (voice.id or '').lower() or voice_lang in (voice.name or '').lower():
                self._engine.setProperty('voice', voice.id)
                logger.info(f"TTS voice: {voice.name}")
                break

    def speak(self, text: str) -> None:
        """Speak text aloud through the system speaker."""
        logger.info(f"Speaking: {text[:60]}...")
        self._engine.say(text)
        self._engine.runAndWait()

    def stop(self) -> None:
        self._engine.stop()


class MockTTS:
    """Mock TTS for testing without audio output."""

    def speak(self, text: str) -> None:
        logger.info(f"[MOCK] TTS would say: {text}")

    def stop(self) -> None:
        pass
