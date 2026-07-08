// author: Redcube

internal class Program
{
    [Obsolete]
    private static int Main(string[] args)
    {
        if (args.Length == 0)
        {
            Console.Error.WriteLine("usage: pfc <assetname>");
            Console.Error.WriteLine("       pfc inject <assetname> <ddspath> <outuasset>");
            Console.Error.WriteLine("       pfc path <assetname>");
            Console.Error.WriteLine("       pfc info <assetname>");
            return 1;
        }

        if (string.Equals(args[0], "path", StringComparison.OrdinalIgnoreCase))
        {
            if (args.Length < 2)
            {
                Console.Error.WriteLine("usage: pfc path <assetname>");
                return 1;
            }

            try
            {
                Console.WriteLine(value: PakLookup.GetAssetPath(args[1]));
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"error: {ex.Message}");
                return 1;
            }
        }

        if (string.Equals(args[0], "info", StringComparison.OrdinalIgnoreCase))
        {
            if (args.Length < 2)
            {
                Console.Error.WriteLine("usage: pfc info <assetname>");
                return 1;
            }

            try
            {
                var (format, sizeX, _) = PakLookup.GetTextureInfo(args[1]);
                var tcFormat = TexconvFormatMap.Resolve(format, out var reason);

                if (tcFormat is null)
                {
                    Console.WriteLine($"{format}|{sizeX}|");
                    Console.Error.WriteLine($"error: {reason}");
                    return 1;
                }

                Console.WriteLine($"{format}|{sizeX}|{tcFormat}");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"error: {ex.Message}");
                return 1;
            }
        }

        if (string.Equals(args[0], "inject", StringComparison.OrdinalIgnoreCase))
        {
            if (args.Length < 4)
            {
                Console.Error.WriteLine("usage: pfc inject <assetname> <ddspath> <outuasset>");
                return 1;
            }

            var assetName = args[1];
            var ddsPath = args[2];
            var uassetPath = args[3];

            try
            {
                Console.WriteLine("exporting raw uasset from pak...");
                var offset = PakLookup.ExportRawAndGetOffset(assetName, uassetPath);
                Console.WriteLine($"offset: 0x{offset:X}");

                Console.WriteLine("patching uasset...");
                HexPatcher.Patch(uassetPath, ddsPath, offset);

                Console.WriteLine("done");
                return 0;
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine($"error: {ex.Message}");
                return 1;
            }
        }

        // default mode: pixel format lookup
        var name = Path.GetFileNameWithoutExtension(args[0]);

        try
        {
            var format = PakLookup.GetPixelFormat(name);
            Console.WriteLine(format);
            return 0;
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"error: {ex.Message}");
            return 1;
        }
    }
}