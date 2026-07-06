// author: Redcube
static class HexPatcher
{
    // marks the end of the uasset file
    static readonly byte[] EndMarker = { 0xC1, 0x83, 0x2A, 0x9E };

    const int DdsHeaderSize = 128;

    public static void Patch(string uassetPath, string ddsPath, long mipOffset)
    {
        var uasset = File.ReadAllBytes(uassetPath);
        var dds = File.ReadAllBytes(ddsPath);

        var markerIndex = FindLastMarker(uasset, mipOffset);
        if (markerIndex == -1)
            throw new Exception("end marker C1 83 2A 9E not found");

        var start = mipOffset + 1;      // byte after the offset
        var end = markerIndex;          // byte before C1
        var length = end - start;

        if (length <= 0)
            throw new Exception("bad range, marker sits before or at mip offset");

        if (dds.Length < DdsHeaderSize + length)
            throw new Exception($"dds too small, need {length} bytes after the header, got {dds.Length - DdsHeaderSize}");

        Array.Copy(dds, DdsHeaderSize, uasset, start, length);
        File.WriteAllBytes(uassetPath, uasset);
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