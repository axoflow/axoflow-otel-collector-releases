// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

package internal

import (
	"strings"

	"github.com/goreleaser/goreleaser-pro/v2/pkg/config"
)

func BuildDistribution(dist string, _ bool) config.Project {
	switch dist {
	case axoflowOtelCollector:
		// if onlyBuild {
		// 	return axoflowOtelCollectorBuildOnlyDist.buildProject()
		// }
		return axoflowOtelCollectorDist.buildProject()
	default:
		panic("Unknown distribution")
	}
}

func armVersions() []string {
	return []string{"7"}
}

// imageName translates a distribution name to a container image name.
func imageName(dist string, opts containerImageOptions) string {
	if opts.binaryRelease {
		return imageNamePrefix + "-" + dist
	}
	return strings.Replace(dist, binaryNamePrefix, imageNamePrefix, 1)
}
