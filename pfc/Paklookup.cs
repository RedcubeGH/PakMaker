// author: Redcube
using CUE4Parse.Encryption.Aes;
using CUE4Parse.FileProvider;
using CUE4Parse.UE4.Assets.Exports.Texture;
using CUE4Parse.UE4.Objects.Core.Misc;
using CUE4Parse.UE4.Versions;

static class PakLookup
{
    const string ConfigFile = "net10.0/Path.cfg";
    const string AesKey = "0x37A0BC3DC2E01D9EB4923CA266A5701F56A4802347F07927FC3FC25C93B31B50";

    static string GetPaksPath()
    {
        if (!File.Exists(ConfigFile))
            throw new Exception("Path.cfg not found.");

        var path = File.ReadAllText(ConfigFile).Trim();

        if (!Directory.Exists(path))
            throw new Exception("The path in Path.cfg does not exist.");

        if (!string.Equals(Path.GetFileName(path), "Paks", StringComparison.OrdinalIgnoreCase))
            throw new Exception("The path in Path.cfg must end in a folder named 'Paks'.");

        return path;
    }

    [Obsolete]
    static DefaultFileProvider OpenProvider()
    {
        var provider = new DefaultFileProvider(
            GetPaksPath(),
            SearchOption.TopDirectoryOnly,
            true,
            new VersionContainer(EGame.GAME_SeaOfThieves)
        );

        provider.Initialize();
        provider.SubmitKey(new FGuid(), new FAesKey(AesKey));
        return provider;
    }

    static string FindUassetKey(DefaultFileProvider provider, string assetName)
    {
        var hit = provider.Files.Keys.FirstOrDefault(k =>
            string.Equals(Path.GetFileNameWithoutExtension(k), assetName, StringComparison.OrdinalIgnoreCase) &&
            k.EndsWith(".uasset", StringComparison.OrdinalIgnoreCase));

        if (hit is null)
            throw new Exception($"not found in paks: {assetName}");

        return hit;
    }

    [Obsolete]
    public static string GetPixelFormat(string assetName)
    {
        var provider = OpenProvider();
        var hit = FindUassetKey(provider, assetName);
        var packagePath = hit[..^7];
        var texture = provider.LoadPackageObject<UTexture2D>(packagePath);

        if (texture is null)
            throw new Exception("no Texture2D found in package");

        return texture.Format.ToString();
    }

    [Obsolete]
    public static string GetAssetPath(string assetName)
    {
        var provider = OpenProvider();
        return FindUassetKey(provider, assetName);
    }

    [Obsolete]
    public static long ExportRawAndGetOffset(string assetName, string outputUassetPath)
    {
        var provider = OpenProvider();
        var hit = FindUassetKey(provider, assetName);

        var saved = provider.SavePackage(hit);
        var rawBytes = saved.TryGetValue(hit, out var bytes) ? bytes : saved.Values.First();
        File.WriteAllBytes(outputUassetPath, rawBytes);

        var packagePath = hit[..^7];
        var texture = provider.LoadPackageObject<UTexture2D>(packagePath);

        if (texture is null)
            throw new Exception("no Texture2D found in package");

        var mip = texture.PlatformData.Mips.FirstOrDefault();
        if (mip?.BulkData is null)
            throw new Exception("no mip bulk data found");

        return mip.BulkData.Header.OffsetInFile;
    }
}