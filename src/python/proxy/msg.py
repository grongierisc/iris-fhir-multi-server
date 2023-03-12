from grongier.pex import Message
from dataclasses import dataclass

@dataclass
class FhirRequest(Message):
    rien:str = None