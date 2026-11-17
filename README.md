# Genome of the Twin Kings

Playable Godot 4 Web prototype (prologue + five chapters). Full docs: [`twin-kings/README.md`](twin-kings/README.md).

## Play in the browser (GitHub Pages)

**[Open the game](https://swatipriyadarshini9.github.io/Genome-Of-The-Twin-King/twin-kings-preview/)**
**Or**
**https://swatipriyadarshini9.itch.io/genome-of-the-twin-kings**

## Local play

```powershell
python twin-kings-preview/serve.py
# http://127.0.0.1:8000/
```

## Repository layout

| Path | Contents |
|------|-----------|
| `twin-kings/` | Godot 4.4.1 source project |
| `twin-kings-preview/` | Web export (WASM) for itch.io / Pages |
| `docs/github-pages-workflow.yml` | Optional Actions deploy (needs `gh auth refresh -s workflow`) |
