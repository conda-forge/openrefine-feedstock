#!/bin/bash
set -euxo pipefail

mvn -B versions:set -DnewVersion="${PKG_VERSION}" -DgenerateBackupPoms=false
# The portable Java distribution works on both Linux and macOS without a bundled JRE.
mvn -B package -P linux -DskipTests

mkdir -p "${PREFIX}/opt" "${PREFIX}/bin"
tar -xzf "packaging/target/openrefine-linux-${PKG_VERSION}.tar.gz" -C "${PREFIX}/opt"
mv "${PREFIX}/opt/openrefine-${PKG_VERSION}" "${PREFIX}/opt/openrefine"

cat > "${PREFIX}/bin/refine" <<'EOF'
#!/bin/bash
exec "$(dirname "$0")/../opt/openrefine/refine" "$@"
EOF
chmod +x "${PREFIX}/bin/refine"
