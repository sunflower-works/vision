package version

// Version is the current module version following SemVer.
// It is a variable (not const) so it can be overridden at build time via -ldflags "-X .../version.Version=vX.Y.Z".
// Bump this when cutting a new release and update CHANGELOG.md accordingly.
var Version = "v0.1.0"
