// Author: Redcube
using System;
using System.IO;
using System.Linq;
using CUE4Parse.Encryption.Aes;
using CUE4Parse.FileProvider;
using CUE4Parse.UE4.Objects.Core.Misc;
using CUE4Parse.UE4.Versions;
using CUE4Parse.UE4.Assets.Objects.Properties;

if (args.Length == 0)
{
    Console.Error.WriteLine("usage: pfc <assetname>");
    return 1;
}

var paksPath = @"D:\SteamLibrary\steamapps\common\Sea of Thieves\Athena\Content\Paks";
var aesKey = "0x37A0BC3DC2E01D9EB4923CA266A5701F56A4802347F07927FC3FC25C93B31B50";
var name = Path.GetFileNameWithoutExtension(args[0]);
//var name = "wpn_blunderbuss_smp_01_a_di"; // test variable

try
{
#pragma warning disable CS0618
    var provider = new DefaultFileProvider(
        paksPath,
        SearchOption.TopDirectoryOnly,
        true,
        new VersionContainer(EGame.GAME_SeaOfThieves)
    );
#pragma warning restore CS0618

    provider.Initialize();
    provider.SubmitKey(new FGuid(), new FAesKey(aesKey));

    var hit = provider.Files.Keys.FirstOrDefault(k =>
        string.Equals(Path.GetFileNameWithoutExtension(k), name, StringComparison.OrdinalIgnoreCase) &&
        k.EndsWith(".uasset", StringComparison.OrdinalIgnoreCase));

    if (hit is null)
    {
        Console.Error.WriteLine($"not found: {name}");
        return 1;
    }

    // Parse the asset package using LoadPackageObject
    var packagePath = hit.Substring(0, hit.Length - 7); // Remove .uasset
    var obj = provider.LoadPackageObject(packagePath);

    if (obj != null)
    {
        // Try to get Format property (for textures)
        var formatProp = obj.GetType().GetProperty("Format");
        if (formatProp != null)
        {
            var value = formatProp.GetValue(obj)?.ToString();
            if (!string.IsNullOrEmpty(value))
            {
                Console.WriteLine(value);
                return 0;
            }
        }

        // Try PixelFormat as fallback
        var pixelFormatProp = obj.GetType().GetProperty("PixelFormat");
        if (pixelFormatProp != null)
        {
            var value = pixelFormatProp.GetValue(obj)?.ToString();
            if (!string.IsNullOrEmpty(value))
            {
                Console.WriteLine(value);
                return 0;
            }
        }
    }

    Console.Error.WriteLine("Format/PixelFormat not found");
    return 1;
}
catch (Exception ex)
{
    Console.Error.WriteLine($"error: {ex.Message}");
    return 1;
}