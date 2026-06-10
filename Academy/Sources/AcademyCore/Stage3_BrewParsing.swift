import Foundation

// ╔════════════════════════════════════════════════════════════════════╗
// ║  STAGE 3 — Parse Homebrew's JSON with Codable                     ║
// ║                                                                    ║
// ║  Grade yourself:  ./academy check 3                                ║
// ║  Concepts:        Tutorial chapter 4                               ║
// ╚════════════════════════════════════════════════════════════════════╝
//
// `brew info --json=v2 --installed` returns JSON shaped like this:
//
// {
//   "formulae": [
//     {
//       "name": "wget",
//       "desc": "Internet file retriever",
//       "versions": { "stable": "1.24.5" },
//       "installed": [ { "version": "1.24.0" } ],
//       "outdated": true,
//       "deprecated": false,
//       "deprecation_reason": null,
//       "deprecation_replacement_formula": null,
//       "deprecation_replacement_cask": null,
//       "disabled": false,
//       "disable_reason": null,
//       "disable_replacement_formula": null,
//       "disable_replacement_cask": null
//     }
//   ]
// }

// ── EXERCISE 3.1 ─────────────────────────────────────────────────────
// Decode the JSON above into [Package] (your Stage 1 struct).
//
// Steps:
//   1. In this file, declare *private* Decodable structs that mirror the
//      JSON: a response struct holding `formulae`, and a formula struct
//      with the fields shown above (match the snake_case names exactly;
//      nested objects become nested structs; anything that can be null
//      is an Optional).
//   2. Convert the String to Data:   json.data(using: .utf8)
//      (use `guard let` — return [] if it fails)
//   3. Decode:   try JSONDecoder().decode(YourResponse.self, from: data)
//   4. Map each formula to a Package with compactMap:
//        • skip formulae whose `installed` array is empty (guard let on
//          installed.last?.version)
//        • manager: .brew
//        • description ← desc, installedVersion ← installed.last.version,
//          latestVersion ← versions.stable, plus the flag/reason fields
//        • replacement: pick the FIRST non-nil of
//            disable_replacement_formula
//            ?? deprecation_replacement_formula
//            ?? disable_replacement_cask
//            ?? deprecation_replacement_cask
public func parseBrewInfo(_ json: String) throws -> [Package] {
    // TODO(you): declare your Decodable structs above or inside this
    // function, then decode and map.
    return []
}
