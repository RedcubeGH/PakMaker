// author: Redcube
static class HexPatcher
{
    // marks the end of the uasset file
    static readonly byte[] EndMarker = { 0xC1, 0x83, 0x2A, 0x9E };

    // classic DDS header is 128 bytes (4 magic + 124 header). texconv adds an extra 20-byte DX10 header
    const int DdsHeaderSizeLegacy = 128;
    const int DdsHeaderSizeDx10 = 148;

    public static void Patch(string uassetPath, string ddsPath, long mipOffset)
    {
        var uasset = File.ReadAllBytes(uassetPath);
        var dds = File.ReadAllBytes(ddsPath);

        var ddsHeaderSize = GetDdsHeaderSize(dds);

        var markerIndex = FindLastMarker(uasset, mipOffset);
        if (markerIndex == -1)
            throw new Exception("end marker C1 83 2A 9E not found");

        var start = mipOffset + 1;      // byte after the offset
        var end = markerIndex;          // byte before C1
        var length = end - start;

        if (length <= 0)
            throw new Exception("bad range, marker sits before or at mip offset");

        if (dds.Length < ddsHeaderSize + length)
            throw new Exception($"dds too small, need {length} bytes after the header, got {dds.Length - ddsHeaderSize}");

        Array.Copy(dds, ddsHeaderSize, uasset, start, length);
        File.WriteAllBytes(uassetPath, uasset);
    }

    static int GetDdsHeaderSize(byte[] dds)
    {
        if (dds.Length < DdsHeaderSizeLegacy || dds[0] != (byte)'D' || dds[1] != (byte)'D' || dds[2] != (byte)'S' || dds[3] != (byte)' ')
            throw new Exception("dds file missing DDS magic header");

        // DDS_PIXELFORMAT.dwFourCC lives at file offset 84
        var isDx10 = dds[84] == (byte)'D' && dds[85] == (byte)'X' && dds[86] == (byte)'1' && dds[87] == (byte)'0';
        return isDx10 ? DdsHeaderSizeDx10 : DdsHeaderSizeLegacy;
    }

    static long FindLastMarker(byte[] data, long searchFloor)
    {
        for (var i = data.Length - EndMarker.Length; i >= searchFloor; i--)
        {
            if (data[i] == EndMarker[0] &&
                data[i + 1] == EndMarker[1] &&
                data[i + 2] == EndMarker[2] &&
                data[i + 3] == EndMarker[3])
            {
                return i;
            }
        }

        return -1;
    }
}