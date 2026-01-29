// Copyright The OpenTelemetry Authors
// SPDX-License-Identifier: Apache-2.0

package internal

import (
	"slices"
)

var (
	axoflowOtelCollectorDist = newDistributionBuilder(axoflowOtelCollector).withConfigFunc(func(d *distribution) {
		d.BuildConfigs = []buildConfig{
			&fullBuildConfig{TargetOS: "linux", TargetArch: baseArchs, BuildDir: defaultBuildDir, ArmVersion: []string{"7"}},
			&fullBuildConfig{TargetOS: "windows", TargetArch: baseArchs, BuildDir: defaultBuildDir},
		}
		d.ContainerImages = slices.Concat(
			newContainerImages(d.Name, "linux", baseArchs, containerImageOptions{armVersion: "7"}),
			// newContainerImages(d.Name, "windows", winContainerArchs, containerImageOptions{winVersion: "2019"}),
			// newContainerImages(d.Name, "windows", winContainerArchs, containerImageOptions{winVersion: "2022"}),
		)
		d.ContainerImageManifests = slices.Concat(
			newContainerImageManifests(d.Name, "linux", baseArchs, containerImageOptions{}),
		)
	}).withPackagingDefaults().withDefaultConfigIncluded().build()
)
