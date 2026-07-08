// author: Redcube
static class TexconvFormatMap
{
    static readonly Dictionary<string, string> Map = new(StringComparer.OrdinalIgnoreCase)
    {
        // All the sot formats
        ["PF_DXT1"] = "BC1_UNORM",
        ["PF_DXT3"] = "BC2_UNORM",
        ["PF_DXT5"] = "BC3_UNORM",
        ["PF_BC4"] = "BC4_UNORM",
        ["PF_BC5"] = "BC5_UNORM",
        ["PF_BC6H"] = "BC6H_UF16",
        ["PF_BC7"] = "BC7_UNORM",
    };

    public static string? Resolve(string pixelFormat, out string? reason)
    {
        if (Map.TryGetValue(pixelFormat, out var tcFormat))
        {
            reason = null;
            return tcFormat;
        }

        var known = string.Join(", ", Map.Keys.OrderBy(k => k, StringComparer.OrdinalIgnoreCase));
        reason = $"no texconv mapping for {pixelFormat} yet. Known formats: {known}. " +
                  "Add an entry to TexconvFormatMap.cs if you know the matching DXGI format name.";
        return null;
    }
}