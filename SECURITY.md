# Security

Please do not report suspected vulnerabilities in a public issue. Use GitHub's private vulnerability reporting on the `The-CodeCave/shipd-cli` repository and include the affected CLI version, platform, reproduction steps, and impact.

Release installers verify SHA-256 checksums, but current artifacts are not independently signed and macOS artifacts are not notarized. Treat a checksum as an integrity check from the same GitHub Release, not as independent publisher attestation.
