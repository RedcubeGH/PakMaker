// author: Redcube

using CUE4Parse.FileProvider;
using CUE4Parse.UE4.Assets.Exports.Texture;
using CUE4Parse.UE4.Objects.Core.Misc;
using CUE4Parse.UE4.Versions;
//using System;
//using System.IO;
//using System.Xml.Linq;

if (args.Length == 0)
{
    Console.Error.WriteLine("usage: pfc <assetname>");
    return 1;
}

var paksPath = @"D:\SteamLibrary\steamapps\common\Sea of Thieves\Athena\Content\Paks";
var aesKey = "0x37A0BC3DC2E01D9EB4923CA266A5701F56A4802347F07927FC3FC25C93B31B50";
var name = Path.GetFileNameWithoutExtension(args[0]);

try
{
    var provider = new DefaultFileProvider(
        paksPath,
        SearchOption.TopDirectoryOnly,
        isCaseInsensitive: true,
        new VersionContainer(EGame.GAME_SeaOfThieves)
    );

    provider.Initialize();
    await provider.SubmitKeyAsync(new FAesKey(aesKey));

    var hit = provider.Files.Keys.FirstOrDefault(k =>
        string.Equals(Path.GetFileNameWithoutExtension(k), name, StringComparison.OrdinalIgnoreCase) &&
        k.EndsWith(".uasset", StringComparison.OrdinalIgnoreCase));

    if (hit is null)
    {
        Console.Error.WriteLine($"not found: {name}");
        return 1;
    }

    var packagePath = hit[..^7]; // strip .uasset
    var exports = await provider.LoadObjectExportsAsync(packagePath);

    foreach (var export in exports)
    {
        if (export is UTexture2D tex)
        {
            Console.WriteLine(tex.PixelFormat);
            return 0;
        }
    }

    Console.Error.WriteLine("no Texture2D export found");
    return 1;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"error: {ex.Message}");
    return 1;
}
    