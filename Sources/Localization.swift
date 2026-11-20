import Foundation

/// Read interface text in the user's preferred supported application language.
func L(_ key: String) -> String {
  Bundle.main.localizedString(forKey: key, value: nil, table: nil)
}
