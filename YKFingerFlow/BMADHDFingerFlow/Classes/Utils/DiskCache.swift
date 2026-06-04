// Copyright (c) 2023, Bongmi
// All rights reserved
// Author: liuyuanyuan@bongmi.com
//
// From BMUserBusinessLib

import CryptoKit
import Foundation

final class DiskCache {
  private let keyPrefix: String
  private let defaults: UserDefaults
  private let fileDirectory: URL?

  /// User preferences cache (int/bool via UserDefaults).
  init(userNamespace: String) {
    keyPrefix = "DiskCache.\(userNamespace)."
    defaults = UserDefaults.standard
    fileDirectory = nil
  }

  /// File-backed cache for binary payloads keyed by URL string.
  init(fileNamespace: String) {
    keyPrefix = "DiskCache.\(fileNamespace)."
    defaults = UserDefaults.standard
    let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
    fileDirectory = base?.appendingPathComponent(fileNamespace, isDirectory: true)
    if let fileDirectory {
      try? FileManager.default.createDirectory(at: fileDirectory,
                                               withIntermediateDirectories: true)
    }
  }

  func getInt(for key: KVCacheKey) -> Int {
    defaults.integer(forKey: defaultsKey(for: key))
  }

  func setInt(_ value: Int, for key: KVCacheKey) {
    defaults.set(value, forKey: defaultsKey(for: key))
  }

  func getBool(for key: KVCacheKey) -> Bool {
    defaults.bool(forKey: defaultsKey(for: key))
  }

  func setBool(_ value: Bool, for key: KVCacheKey) {
    defaults.set(value, forKey: defaultsKey(for: key))
  }

  func getData(for key: String) -> Data? {
    guard let fileURL = fileURL(for: key) else { return nil }
    return try? Data(contentsOf: fileURL)
  }

  func setData(_ data: Data, for key: String) {
    guard let fileURL = fileURL(for: key) else { return }
    try? data.write(to: fileURL, options: .atomic)
  }

  private func defaultsKey(for key: KVCacheKey) -> String {
    keyPrefix + key.rawValue
  }

  private func fileURL(for key: String) -> URL? {
    guard let fileDirectory else { return nil }
    let digest = SHA256.hash(data: Data(key.utf8))
    let fileName = digest.map { String(format: "%02x", $0) }.joined()
    return fileDirectory.appendingPathComponent(fileName)
  }
}
