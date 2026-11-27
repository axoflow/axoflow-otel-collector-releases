# Mechanical upstream Go API changes, applied by bump-fork-component.sh to every .go file of a
# fork component. Append a rule whenever a bump hits a new rename, with the release it came in.
# verify-fork-component.sh catches anything a rule gets wrong (e.g. a duplicate import).

# core v0.158/v0.161: xconfmap.Validate removed -> confmap.Validate
s#"go.opentelemetry.io/collector/confmap/xconfmap"#"go.opentelemetry.io/collector/confmap"#
s#xconfmap\.Validate\(#confmap.Validate(#g

# contrib v0.162: pkg/pdatautil removed, hashing moved to core pdata/xpdata/xhash
s#"github.com/open-telemetry/opentelemetry-collector-contrib/pkg/pdatautil"#"go.opentelemetry.io/collector/pdata/xpdata/xhash"#
s#pdatautil\.MapHash\(#xhash.MapHash(#g
