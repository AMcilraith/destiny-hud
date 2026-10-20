[CmdletBinding()]
param(
    [string]$ProjectRoot = $PSScriptRoot,
    # Rebuild from src/ and require the result to equal base/ byte for byte (tooling self-check).
    [switch]$VerifyRoundTrip
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$ArchiveName = '9ba626afa44a3aa3.patch_0'
$Utf8 = New-Object System.Text.UTF8Encoding($false)

function Fail([string] $Message) { throw "Destiny HUD build: $Message" }

# base/ holds the 0.2.6 archive. Its textures, decal units and the GPU/stream files are kept
# as they are; only the boot script, the HUD bundle and the strings table are rebuilt from src/.
$Packer = @'
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

public static class HudPlusArchive
{
    const ulong Mix = 0xC6A4A7935BD1E995UL;
    public const ulong LuaType = 0xA14E8DFA2CD117E2UL;
    const int Header = 72, TypeRow = 32, EntryRow = 80;

    public static ulong ResourceHash(string name)
    {
        byte[] data = new UTF8Encoding(false).GetBytes(name);
        unchecked {
            ulong result = (ulong)data.Length * Mix;
            int complete = data.Length / 8 * 8;
            for (int at = 0; at < complete; at += 8) {
                ulong word = BitConverter.ToUInt64(data, at);
                word *= Mix;
                word ^= word >> 47;
                result = (result ^ (word * Mix)) * Mix;
            }
            if (complete != data.Length) {
                ulong tail = 0;
                for (int i = complete; i < data.Length; ++i)
                    tail |= (ulong)data[i] << ((i - complete) * 8);
                result = (result ^ tail) * Mix;
            }
            result ^= result >> 47;
            result *= Mix;
            return result ^ (result >> 47);
        }
    }

    public static byte[] LuaEnvelope(byte[] body)
    {
        byte[] output = new byte[body.Length + 8];
        BitConverter.GetBytes((uint)body.Length).CopyTo(output, 0);
        BitConverter.GetBytes(2U).CopyTo(output, 4);
        body.CopyTo(output, 8);
        return output;
    }

    // Strings resource: magic, language count, id count, language ids, ascending text ids,
    // language-major offsets, then a NUL-terminated blob where equal texts share one copy.
    public static byte[] Strings(uint magic, uint[] languages, uint[] ids, string[][] texts)
    {
        UTF8Encoding utf8 = new UTF8Encoding(false);
        int count = ids.Length, lanes = languages.Length;
        int blobStart = 12 + 4 * count + 4 * lanes + 4 * lanes * count;
        MemoryStream blob = new MemoryStream();
        Dictionary<string, uint> seen = new Dictionary<string, uint>(StringComparer.Ordinal);
        uint[] offsets = new uint[lanes * count];
        for (int lane = 0; lane < lanes; ++lane) {
            for (int row = 0; row < count; ++row) {
                string text = texts[row][lane];
                uint at;
                if (!seen.TryGetValue(text, out at)) {
                    at = (uint)(blobStart + blob.Length);
                    seen[text] = at;
                    byte[] bytes = utf8.GetBytes(text);
                    blob.Write(bytes, 0, bytes.Length);
                    blob.WriteByte(0);
                }
                offsets[lane * count + row] = at;
            }
        }
        using (MemoryStream stream = new MemoryStream())
        using (BinaryWriter writer = new BinaryWriter(stream)) {
            writer.Write(magic); writer.Write((uint)lanes); writer.Write((uint)count);
            foreach (uint lane in languages) writer.Write(lane);
            foreach (uint id in ids) writer.Write(id);
            foreach (uint at in offsets) writer.Write(at);
            writer.Write(blob.ToArray());
            return stream.ToArray();
        }
    }

    // Rewrites the data section in table order; GPU/stream offsets stay valid because those files are untouched.
    public static byte[] Repack(byte[] archive, Dictionary<ulong, byte[]> replace)
    {
        if (BitConverter.ToUInt32(archive, 0) != 0xF0000011U) throw new InvalidDataException("archive magic");
        int types = (int)BitConverter.ToUInt32(archive, 4), count = (int)BitConverter.ToUInt32(archive, 8);
        int table = Header + TypeRow * types;
        int dataStart = table + EntryRow * count;
        byte[] head = new byte[dataStart];
        Array.Copy(archive, head, dataStart);
        MemoryStream data = new MemoryStream();
        HashSet<ulong> used = new HashSet<ulong>();
        long cursor = -1;
        for (int index = 0; index < count; ++index) {
            int row = table + index * EntryRow;
            ulong name = BitConverter.ToUInt64(archive, row);
            long at = (long)BitConverter.ToUInt64(archive, row + 16);
            int length = (int)BitConverter.ToUInt32(archive, row + 56);
            if (cursor < 0) cursor = at;
            if (at != cursor) throw new InvalidDataException("base archive data is not contiguous at entry " + index);
            cursor = at + length;
            byte[] body;
            if (replace.TryGetValue(name, out body)) used.Add(name);
            else { body = new byte[length]; Array.Copy(archive, at, body, 0, length); }
            BitConverter.GetBytes((ulong)(dataStart + data.Length)).CopyTo(head, row + 16);
            BitConverter.GetBytes((uint)body.Length).CopyTo(head, row + 56);
            data.Write(body, 0, body.Length);
        }
        if (cursor != archive.Length) throw new InvalidDataException("base archive has trailing bytes");
        foreach (ulong name in replace.Keys)
            if (!used.Contains(name)) throw new InvalidDataException(string.Format("resource {0:x16} is not in the base archive", name));
        byte[] output = new byte[dataStart + data.Length];
        head.CopyTo(output, 0);
        data.ToArray().CopyTo(output, dataStart);
        return output;
    }
}
'@
Add-Type -TypeDefinition $Packer -Language CSharp

function Read-Text([string] $Path) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "missing $Path" }
    return [IO.File]::ReadAllText($Path, $Utf8).Replace("`r`n", "`n").Replace("`r", "`n")
}

$Src = Join-Path $ProjectRoot 'src'
$Base = Join-Path $ProjectRoot 'base'
$BaseArchive = Join-Path $Base $ArchiveName
foreach ($Path in @($BaseArchive, "$BaseArchive.gpu_resources", "$BaseArchive.stream")) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { Fail "missing $Path" }
}

# HUD bundle: modules in modules.json order, wrapped exactly like the shipped 0.2.6 bundle.
$Order = @((Read-Text (Join-Path $Src 'modules.json') | ConvertFrom-Json) | ForEach-Object { $_ })
$Seen = @{}
$Bundle = New-Object System.Text.StringBuilder
[void]$Bundle.Append((Read-Text (Join-Path $Src 'bundle_head.lua')))
foreach ($Name in $Order) {
    if ($Name -notmatch '^[a-z0-9_]+(\.[a-z0-9_]+)*$') { Fail "bad module name '$Name'" }
    if ($Seen.ContainsKey($Name)) { Fail "module '$Name' listed twice" }
    $Seen[$Name] = $true
    $Body = Read-Text (Join-Path $Src "modules/$Name.lua")
    if (-not $Body.EndsWith("`n")) { $Body += "`n" }
    [void]$Bundle.Append("modules[`"$Name`"] = function(require)`n").Append($Body).Append("end`n")
}
foreach ($File in Get-ChildItem -LiteralPath (Join-Path $Src 'modules') -Filter '*.lua') {
    if (-not $Seen.ContainsKey($File.BaseName)) { Fail "src/modules/$($File.Name) is not listed in modules.json" }
}
[void]$Bundle.Append((Read-Text (Join-Path $Src 'bundle_tail.lua')))

# Strings: every row lists English first; rows with fewer languages reuse English for the rest.
$Table = Read-Text (Join-Path $Src 'strings/strings.json') | ConvertFrom-Json
$Languages = [uint32[]]@($Table.languages | ForEach-Object { [Convert]::ToUInt32($_, 16) })
$Rows = @($Table.strings.PSObject.Properties | ForEach-Object {
    $Texts = @($_.Value)
    if ($Texts.Count -lt 1 -or $Texts.Count -gt $Languages.Count) { Fail "string $($_.Name) needs 1..$($Languages.Count) texts" }
    $Full = New-Object string[] $Languages.Count
    for ($i = 0; $i -lt $Languages.Count; ++$i) { $Full[$i] = if ($i -lt $Texts.Count) { [string]$Texts[$i] } else { [string]$Texts[0] } }
    [pscustomobject]@{ Id = [uint32]$_.Name; Texts = $Full }
} | Sort-Object Id)
$StringsBytes = [HudPlusArchive]::Strings([Convert]::ToUInt32($Table.magic, 16), $Languages,
    [uint32[]]@($Rows | ForEach-Object { $_.Id }), [string[][]]@($Rows | ForEach-Object { ,$_.Texts }))

# Every option text id must be in strings.json.
$Known = @{}
foreach ($Row in $Rows) {
    if ($Known.ContainsKey([string]$Row.Id)) { Fail "duplicate string id $($Row.Id)" }
    $Known[[string]$Row.Id] = $true
}
$OptionsText = Read-Text (Join-Path $Src 'modules/game.options.lua')
$Referenced = @([regex]::Matches($OptionsText, '\["(?:title|description|heading|group)"\]=(\d+)') | ForEach-Object { $_.Groups[1].Value })
foreach ($Choices in [regex]::Matches($OptionsText, '\["choices"\]=\{([^}]*)\}')) {
    $Referenced += @([regex]::Matches($Choices.Groups[1].Value, '\d{4,}') | ForEach-Object { $_.Value })
}
foreach ($Id in $Referenced) {
    if (-not $Known.ContainsKey($Id)) { Fail "game.options names string $Id, which strings.json lacks" }
}

$Replace = New-Object 'System.Collections.Generic.Dictionary[uint64,byte[]]'
$Replace[[HudPlusArchive]::ResourceHash('boot')] = [HudPlusArchive]::LuaEnvelope($Utf8.GetBytes((Read-Text (Join-Path $Src 'boot.lua'))))
$Replace[[HudPlusArchive]::ResourceHash('mods/hd2_hud/hd2_hud_plus')] = [HudPlusArchive]::LuaEnvelope($Utf8.GetBytes($Bundle.ToString()))
$Replace[[Convert]::ToUInt64((Read-Text (Join-Path $Src 'strings/resource.txt')).Trim(), 16)] = $StringsBytes
$Archive = [HudPlusArchive]::Repack([IO.File]::ReadAllBytes($BaseArchive), $Replace)

if ($VerifyRoundTrip) {
    $Original = [IO.File]::ReadAllBytes($BaseArchive)
    if ($Original.Length -ne $Archive.Length) { Fail "round trip size $($Archive.Length) != $($Original.Length)" }
    for ($i = 0; $i -lt $Original.Length; ++$i) { if ($Original[$i] -ne $Archive[$i]) { Fail "round trip differs at byte $i" } }
    Write-Host 'Round trip: rebuilt archive equals base/ byte for byte.'
    return
}

$Manifest = Read-Text (Join-Path $ProjectRoot 'manifest.json') | ConvertFrom-Json
if ($Manifest.Guid -ne '6f4c2a91-8e17-4b5d-a3c6-1d9e7b04f2a8') { Fail 'manifest Guid must stay the Destiny HUD id' }
$Out = Join-Path $ProjectRoot 'dist/Destiny HUD'
if (Test-Path -LiteralPath $Out) { Remove-Item -LiteralPath $Out -Recurse -Force }
New-Item -ItemType Directory -Path $Out | Out-Null
[IO.File]::WriteAllBytes((Join-Path $Out $ArchiveName), $Archive)
Copy-Item -LiteralPath "$BaseArchive.gpu_resources", "$BaseArchive.stream" -Destination $Out
foreach ($Name in @('manifest.json', 'icon.png', 'README.md')) { Copy-Item -LiteralPath (Join-Path $ProjectRoot $Name) -Destination $Out }
$Hash = (Get-FileHash -LiteralPath (Join-Path $Out $ArchiveName) -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Host "Built $Out ($($Archive.Length) bytes, sha256 $Hash)"
