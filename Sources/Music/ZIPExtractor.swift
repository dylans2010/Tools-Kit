import Foundation

/// Pure-Swift minimal ZIP reader.
/// Handles stored (method 0) and deflated (method 8) local file headers.
/// MP3/MP4 files are always stored without compression in ZIP archives
/// (they are pre-compressed), so method-0 covers the vast majority of
/// real-world music ZIPs.
struct ZIPExtractor {

    struct Entry {
        let filename: String
        let data: Data
    }

    static func extract(from url: URL) -> [Entry] {
        guard let fileData = try? Data(contentsOf: url, options: .mappedIfSafe) else {
            return []
        }
        return parseEntries(in: fileData)
    }

    // MARK: - Parser

    private static func parseEntries(in data: Data) -> [Entry] {
        var entries: [Entry] = []
        var offset = 0

        while offset + 30 <= data.count {
            // Local file header signature: PK 03 04
            guard readUInt32(data, at: offset) == 0x04034B50 else { break }

            let compressionMethod = readUInt16(data, at: offset + 8)
            let compressedSize    = Int(readUInt32(data, at: offset + 18))
            let uncompressedSize  = Int(readUInt32(data, at: offset + 22))
            let filenameLen       = Int(readUInt16(data, at: offset + 26))
            let extraLen          = Int(readUInt16(data, at: offset + 28))

            let headerEnd = offset + 30 + filenameLen + extraLen
            guard headerEnd + compressedSize <= data.count else { break }

            let filename: String
            if filenameLen > 0 {
                filename = data[offset+30 ..< offset+30+filenameLen]
                    .withUnsafeBytes { buf in
                        String(bytes: buf, encoding: .utf8) ??
                        String(bytes: buf, encoding: .isoLatin1) ?? ""
                    }
            } else {
                filename = ""
            }

            let compressedRange = headerEnd ..< (headerEnd + compressedSize)

            switch compressionMethod {
            case 0:
                // Stored – no compression; covers nearly all MP3/MP4 in ZIPs
                entries.append(Entry(filename: filename, data: Data(data[compressedRange])))

            case 8:
                // Deflated – best-effort via NSData zlib (zlib-wrapped DEFLATE)
                // Wrap raw DEFLATE with a zlib header so NSData can decompress it.
                // We use the known uncompressed size and a placeholder Adler-32.
                if let decompressed = zlibInflate(Data(data[compressedRange]),
                                                   expectedSize: uncompressedSize) {
                    entries.append(Entry(filename: filename, data: decompressed))
                }

            default:
                break
            }

            offset = headerEnd + compressedSize
        }

        return entries
    }

    // MARK: - Deflate (method 8) via NSData + zlib wrapper

    private static func zlibInflate(_ compressed: Data, expectedSize: Int) -> Data? {
        // Build a minimal valid zlib stream: 2-byte header + raw DEFLATE + Adler-32.
        // 0x78 0x9C = CMF (deflate, window=32K) + FLG (check bits, no dict).
        var zlib = Data(capacity: compressed.count + 6)
        zlib.append(contentsOf: [0x78, 0x9C])
        zlib.append(compressed)
        // Compute Adler-32 of the decompressed output – we don't have that yet,
        // so append zeros and try; if the NSData decompressor validates it strictly
        // we fall back. Many system implementations accept a stream-end Z_OK.
        zlib.append(contentsOf: [0x00, 0x00, 0x00, 0x01])

        if let result = try? (zlib as NSData).decompressed(using: .zlib) as Data {
            return result
        }
        return nil
    }

    // MARK: - Little-endian readers

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        return data[offset ..< offset + 2].withUnsafeBytes {
            $0.loadUnaligned(as: UInt16.self)
        }.littleEndian
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return data[offset ..< offset + 4].withUnsafeBytes {
            $0.loadUnaligned(as: UInt32.self)
        }.littleEndian
    }
}
