# kimodo.cpp-windows — AI Text-to-Motion Animation on Windows

Generate 3D character animation from plain English. Type *"a person waving"*,
get an animated skeleton you can drop into Blender or Unreal Engine 5.
This is the Windows-ready port of NVIDIA's **Kimodo** text-to-motion model,
running locally on CPU or Vulkan (no cloud, no subscription).

Keywords: AI animation generator, text to motion, text-to-animation,
AI motion capture, 3D animation from text, open source animation tool.

## Quick start (Windows 11)

You need: Visual Studio (C++ workload), CMake, Python 3.10+
(`pip install huggingface_hub`), Git — plus ~17 GB free for models.
Vulkan SDK and Go are optional (GPU speed-up and web UI).

```powershell
git clone https://github.com/TheLocalLab/kimodo.cpp-windows.git
cd kimodo.cpp-windows
git submodule update --init --recursive
python scripts/download_gguf_weights.py --model soma-rp-v1.1
cmake -B build -G "Visual Studio 18 2026" -A x64
cmake --build build --config Release
```

Then double-click **`Launch-Kimodo.bat`** to generate, or
**`Launch-Kimodo-UI.bat`** for the browser studio at
`http://127.0.0.1:8094`. No terminal needed after building.

Prefer to skip the build? There is a
[one-click supporter installer](https://www.patreon.com/TheLocalLab/posts/kimodo-cpp-one-169875852)
that sets everything up for you.

## Models and disk space

| Model | Skeleton | Size |
|---|---|---|
| SOMA RP / SEED v1.1 | 30-joint control rig | ~1.13 GB each |
| G1 RP / SEED v1 | 34 Unitree G1 joints | ~1.13 GB each |
| Llama-3 text encoder bundle (35 files) | — | ~15.2 GB |

Minimal setup (one motion model + text bundle): **~16.3 GB**.
SMPL-X is excluded: its licence forbids redistribution.

## Demo, export, Unreal

- `go run ./demo` — generate in the browser, download `animation.glb`.
- `scripts/export_glb.py` — raw motion to GLB for Blender.
- `docs/how_to_setup_with_unreal_in_windows.md` — retarget to the UE5
  Mannequin step by step.

## Licence

Code: Apache-2.0 (see [LICENSE](LICENSE)). SOMA/G1 checkpoints: NVIDIA
Open Model License (commercial use permitted). SMPL-X: internal R&D only.
The text bundle carries Meta Llama 3 terms — review each model card
([LocalAI-io on Hugging Face](https://huggingface.co/LocalAI-io))
before redistributing.

Upstream project: [localai-org/kimodo.cpp](https://github.com/localai-org/kimodo.cpp).
