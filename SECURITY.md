# Security

Please do not report suspected vulnerabilities in a public issue. Use GitHub's private vulnerability reporting on the `The-CodeCave/shipd-cli` repository and include the affected CLI version, platform, reproduction steps, and impact.

Release installers verify SHA-256 checksums. From v0.1.1 onward, macOS binaries also carry Developer ID signatures and pass Apple notarization; v0.1.0 is unsigned. Standalone executables cannot carry stapled tickets, so Gatekeeper may require an online ticket lookup. Linux and Windows artifacts do not have independent signatures. A checksum alone is an integrity check from the same GitHub Release, not independent publisher attestation.
