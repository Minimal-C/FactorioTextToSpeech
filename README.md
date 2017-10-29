# Factorio Text To Speech

# Features

The text to speech mod converts input text to a blueprint which uses custom speaker sounds to synthesize speech.

- Recognizes 134,000 words
- Can synthesize custom words by phonemes should the dictionary not recognize it
- Two voices:
    * Male voice
    * HL1 VOX (Half Life 1 facility computer voice)

# Examples

## Speech synthesis
- (Old but relevant-pre v0.1.0): https://www.youtube.com/watch?v=6RPOTj4Ysrg
- (Old but relevant-pre v0.1.0): https://www.youtube.com/watch?v=Y875JPsUVJg

# How to use
1. Input text
2. With an empty blueprint on your cursor, click on the blueprint icon
3. Place blueprint
4. Activate the constant combinator (red box)

# How to synthesize custom words (Excluding HL1 VOX)
You can create a custom word by writing a sequence of phonemes (39 phonemes defined by CMU Pronouncing Dictionary) each separated by a whitespace and encapsulated with square brackets, e.g. "[F AE K T AO R IY OW] is pretty neat" would pronounce the sentence: "Factorio is pretty neat".

The 39 phonemes supported are: AA, AE, AH, AO, AW, AY, B, CH, D, DH, EH, ER, EY, F, G, HH, IH, IY, JH, K, L, M, N, NG, OW, OY, P, R, S, SH, T, TH, UH, UW, V, W, Y, Z, ZH

# Known Bugs

* When using the HL1 VOX voice, the programmable speaker may display a sound name that is different from the one being played, this is a visual bug and likely due to the number of sounds for that voice.
