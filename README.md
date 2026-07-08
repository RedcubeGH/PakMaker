# PakMaker

A texture-replacement modding tool for Sea of Thieves. Drop an image onto it and it will:

- look up the pixel format the existing in-game texture uses
- convert your image to matching DDS compression with Compressonator CLI
- hex-inject the DDS data into the original `.uasset`
- stage everything and build a `.pak` with u4pak, ready to drop into the game

It also comes with an unpack tool (`Ω_UNPACK.bat`) for pulling files back out of a `.pak`.

## Getting started

### Option 1: Download the latest release (recommended)

Grab the newest zip from the [Releases](https://github.com/RedcubeGH/PakMaker/releases) page. It ships with everything already included — `u4pak.exe`, `oo2core_9_win64.dll`, and Compressonator CLI — so there's nothing extra to install.

1. Extract the zip anywhere
2. Drag your image file(s) onto `Ω_DRAG_HERE_TO_MAKE_PAK.bat`
3. On first run it'll ask for your Sea of Thieves `Paks` folder (e.g. `...\Steam\steamapps\common\Sea of Thieves\Athena\Content\Paks`) — it saves this to `Path.cfg` so you won't be asked again

That's it.

### Option 2: Build from source

**Requirements**
- [.NET 10 SDK](https://dotnet.microsoft.com/download)
- Git

**1. Clone and build**

```
git clone https://github.com/RedcubeGH/PakMaker.git
cd PakMaker
build.bat
```

This runs `dotnet build -c Release`, producing `pfc.exe` in `pfc\bin\Release\net10.0\`.

**2. Get the runtime dependencies**

PakMaker shells out to a couple of external tools that aren't part of the C# build. Check `pfc\bin\Release\net10.0\` and make sure these are present:

| File | Where to get it |
|---|---|
| `u4pak.exe` | [FranklyGD/Spyro-Reignited-Trilogy-Asset-Replacement releases](https://github.com/FranklyGD/Spyro-Reignited-Trilogy-Asset-Replacement/releases/tag/fp1.0) — a standalone Windows build of panzi's `u4pak.py`, handles the actual `pack`/`list`/`info` work |
| `oo2core_9_win64.dll` | Copy this from your own Sea of Thieves install: `Sea of Thieves\Athena\Binaries\Win64\oo2core_9_win64.dll`. It's RAD Game Tools' proprietary Oodle codec, so it can't be redistributed on its own — pull it from a copy of the game you own |
| Compressonator CLI | Download from [gpuopen.com/compressonator](https://gpuopen.com/compressonator/) (or grab `CompressonatorCLI_x64_4.5.52.exe` directly from the [V4.5.52 release](https://github.com/GPUOpen-Tools/compressonator/releases/tag/V4.5.52)), install it, then copy `compressonatorcli.exe` and its accompanying DLLs into a `compressonatorcli\` subfolder next to `pfc.exe` |

**3. Run it**

Drag your image file(s) onto `Ω_DRAG_HERE_TO_MAKE_PAK.bat` (in `pfc\bin\Release\`) the same way as in Option 1.

## Unpacking

To pull files back out of a `.pak` (e.g. to inspect the original folder structure), drag the `.pak` onto `Ω_UNPACK.bat`. It extracts into `unpak\<pakname>\`.

## Folder layout

Whichever path you took, you should end up with something like:

```
PakMaker/
├─ net10.0/
│  ├─ pfc.exe
│  ├─ u4pak.exe
│  ├─ oo2core_9_win64.dll
│  ├─ Path.cfg
│  └─ compressonatorcli/
│     └─ compressonatorcli.exe (+ its DLLs)
├─ pak/          <- built .pak files land here
├─ unpak/        <- unpacked .pak contents land here
├─ Ω_DRAG_HERE_TO_MAKE_PAK.bat
└─ Ω_UNPACK.bat
```

## License

[AGPL-3.0](LICENSE.txt)
