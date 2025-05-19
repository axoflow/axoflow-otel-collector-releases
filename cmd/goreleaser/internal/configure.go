// Copyright The OpenTelemetry Authors
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package internal

// This file is a script which generates the .goreleaser.yaml file for all
// supported OpenTelemetry Collector distributions.
//
// Run it with `make generate-goreleaser`.

import (
	"fmt"
	"path"
	"strings"

	"github.com/goreleaser/goreleaser-pro/v2/pkg/config"
)

const (
	armArch          = "arm"
	coreDistro       = "axoflow-otel-collector"
	ghcr             = "ghcr.io/axoflow/axoflow-otel-collector"
	binaryNamePrefix = "otelcol"
	imageNamePrefix  = "axoflow-otel-collector"
)

var (
	baseArchs = []string{"amd64", "arm64"}

	imageRepos = []string{ghcr}

	// otelcol (core) distro
	otelColDist = newDistributionBuilder(coreDistro).WithConfigFunc(func(d *distribution) {
		d.buildConfigs = []buildConfig{
			&fullBuildConfig{targetOS: "linux", targetArch: baseArchs},
			&fullBuildConfig{targetOS: "windows", targetArch: baseArchs},
		}
		d.containerImages = newContainerImages(d.name, "linux", baseArchs, containerImageOptions{armVersion: "7"})
		d.containerImageManifests = newContainerImageManifests(d.name, "linux", baseArchs)
	}).WithPackagingDefaults().WithDefaultConfigIncluded().Build()
)

type buildConfig interface {
	Build(dist string) config.Build
	OS() string
	Arch() string
}

type distributionBuilder struct {
	dist        *distribution
	configFuncs []func(*distribution)
}

func newDistributionBuilder(name string) *distributionBuilder {
	return &distributionBuilder{dist: &distribution{name: name}}
}

func (b *distributionBuilder) WithDefaultArchives() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		builds := make([]string, 0, len(d.buildConfigs))
		for _, build := range d.buildConfigs {
			builds = append(builds, fmt.Sprintf("%s-%s", d.name, build.OS()))
		}
		d.archives = b.newArchives(d.name, builds)
	})
	return b
}

func (b *distributionBuilder) WithBinArchive() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		d.archives = append(d.archives, config.Archive{
			Formats: []string{"binary"},
		})
	})
	return b
}

func (b *distributionBuilder) newArchives(dist string, builds []string) []config.Archive {
	return []config.Archive{
		{
			ID:           dist,
			NameTemplate: "{{ .Binary }}_{{ .Version }}_{{ .Os }}_{{ .Arch }}{{ if .Arm }}v{{ .Arm }}{{ end }}{{ if .Mips }}_{{ .Mips }}{{ end }}",
			Builds:       builds,
			Files: []config.File{
				{
					Source: "README_{{.Os}}.md",
				},
			},
		},
	}
}

func (b *distributionBuilder) WithDefaultNfpms() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		d.nfpms = b.newNfpms(d.name)
	})
	return b
}

func (b *distributionBuilder) newNfpms(dist string) []config.NFPM {
	nfpmContents := []config.NFPMContent{
		{
			Source:      fmt.Sprintf("%s.service", dist),
			Destination: path.Join("/lib", "systemd", "system", fmt.Sprintf("%s.service", dist)),
		},
		{
			Source:      fmt.Sprintf("%s.conf", dist),
			Destination: path.Join("/etc", dist, fmt.Sprintf("%s.conf", dist)),
			Type:        "config|noreplace",
		},
	}
	return []config.NFPM{
		{
			ID:          dist,
			Builds:      []string{dist + "-linux"},
			Formats:     []string{"deb", "rpm"},
			License:     "Apache 2.0",
			Description: fmt.Sprintf("OpenTelemetry Collector - %s", dist),
			Maintainer:  "The Axoflow Otel-Collector maintainers <support@axoflow.com>",
			Overrides: map[string]config.NFPMOverridables{
				"rpm": {
					Dependencies: []string{"/bin/sh"},
				},
			},
			NFPMOverridables: config.NFPMOverridables{
				PackageName: dist,
				Scripts: config.NFPMScripts{
					PreInstall:  "preinstall.sh",
					PostInstall: "postinstall.sh",
					PreRemove:   "preremove.sh",
				},
				Contents: nfpmContents,
			},
		},
	}
}

func (b *distributionBuilder) WithDefaultMSIConfig() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		d.msiConfig = b.newMSIConfig(d.name)
	})
	return b
}

func (b *distributionBuilder) newMSIConfig(dist string) []config.MSI {
	files := []string{"axoflow.ico", "README_windows.md"}
	return []config.MSI{
		{
			ID:    dist,
			Name:  fmt.Sprintf("%s_{{ .Version }}_{{ .Os }}_{{ .MsiArch }}", dist),
			WXS:   "windows-installer.wxs",
			Files: files,
		},
	}
}

func (b *distributionBuilder) WithDefaultSigns() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		d.signs = b.signs()
	})
	return b
}

func (b *distributionBuilder) signs() []config.Sign {
	return []config.Sign{
		{
			Artifacts:   "all",
			Signature:   "${artifact}.sig",
			Certificate: "${artifact}.pem",
			Cmd:         "cosign",
			Args: []string{
				"sign-blob",
				"--output-signature",
				"${artifact}.sig",
				"--output-certificate",
				"${artifact}.pem",
				"${artifact}",
			},
		},
	}
}

func (b *distributionBuilder) WithDefaultDockerSigns() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		d.dockerSigns = b.dockerSigns()
	})
	return b
}

func (b *distributionBuilder) dockerSigns() []config.Sign {
	return []config.Sign{
		{
			Artifacts: "all",
			Args: []string{
				"sign",
				"${artifact}",
			},
		},
	}
}

func (b *distributionBuilder) WithDefaultSBOMs() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		d.sboms = b.sboms()
	})
	return b
}

func (b *distributionBuilder) sboms() []config.SBOM {
	return []config.SBOM{
		{
			ID:        "archive",
			Artifacts: "archive",
		},
		{
			ID:        "package",
			Artifacts: "package",
		},
	}
}

func (b *distributionBuilder) WithDefaultChecksum() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		b.dist.checksum = config.Checksum{
			NameTemplate: fmt.Sprintf("{{ .ProjectName }}_%v_checksums.txt", d.name),
		}
	})
	return b
}

func (b *distributionBuilder) WithPackagingDefaults() *distributionBuilder {
	return b.WithDefaultArchives().
		WithDefaultChecksum().
		WithDefaultNfpms().
		WithDefaultMSIConfig().
		WithDefaultSigns().
		WithDefaultDockerSigns().
		WithDefaultSBOMs()
}

func (b *distributionBuilder) WithConfigFunc(configFunc func(*distribution)) *distributionBuilder {
	b.configFuncs = append(b.configFuncs, configFunc)
	return b
}

func (b *distributionBuilder) WithDefaultConfigIncluded() *distributionBuilder {
	b.configFuncs = append(b.configFuncs, func(d *distribution) {
		for i, container := range d.containerImages {
			container.Files = append(container.Files, "linux_config.yaml")
			container.Files = append(container.Files, "etw_library_license.txt")
			d.containerImages[i] = container
		}

		for i, nfpm := range d.nfpms {
			nfpm.Contents = append(nfpm.Contents, config.NFPMContent{
				Source:      "linux_config.yaml",
				Destination: path.Join("/etc", d.name, "config.yaml"),
				Type:        "config|noreplace",
			})
			d.nfpms[i] = nfpm
		}

		for i := range d.msiConfig {
			d.msiConfig[i].Files = append(d.msiConfig[i].Files, "windows_config.yaml")
			d.msiConfig[i].Files = append(d.msiConfig[i].Files, "etw_library_license.txt")
		}
	})
	return b
}

func (b *distributionBuilder) Build() *distribution {
	for _, configFunc := range b.configFuncs {
		configFunc(b.dist)
	}
	return b.dist
}

type distribution struct {
	// Name of the distribution (i.e. otelcol, otelcol-contrib, k8s)
	name string

	buildConfigs            []buildConfig
	archives                []config.Archive
	msiConfig               []config.MSI
	nfpms                   []config.NFPM
	containerImages         []config.Docker
	containerImageManifests []config.DockerManifest
	signs                   []config.Sign
	dockerSigns             []config.Sign
	sboms                   []config.SBOM
	checksum                config.Checksum
}

func (d *distribution) BuildProject() config.Project {
	builds := make([]config.Build, 0, len(d.buildConfigs))
	for _, buildConfig := range d.buildConfigs {
		builds = append(builds, buildConfig.Build(d.name))
	}

	return config.Project{
		ProjectName: "axoflow-otel-collector-releases",
		Checksum:    d.checksum,
		Env: []string{
			"COSIGN_YES=true",
			"LD_FLAGS=-s -w",
			"CGO_ENABLED=0",
			"BUILD_FLAGS=-trimpath",
		},
		Builds:          builds,
		Archives:        d.archives,
		MSI:             d.msiConfig,
		NFPMs:           d.nfpms,
		Dockers:         d.containerImages,
		DockerManifests: d.containerImageManifests,
		Signs:           d.signs,
		DockerSigns:     d.dockerSigns,
		SBOMs:           d.sboms,
		Version:         2,
		Monorepo: config.Monorepo{
			TagPrefix: "v",
		},
		Partial: config.Partial{By: "target"},
		Release: config.Release{ReplaceExistingArtifacts: true},
	}
}

func newContainerImageManifests(dist, os string, archs []string) []config.DockerManifest {
	tags := []string{`{{ .Version }}`, "latest"}
	var r []config.DockerManifest
	for _, imageRepo := range imageRepos {
		for _, tag := range tags {
			r = append(r, osDockerManifest(imageRepo, tag, dist, os, archs))
		}
	}
	return r
}

type containerImageOptions struct {
	armVersion string
	winVersion string
}

func (o *containerImageOptions) version() string {
	if o.armVersion != "" {
		return o.armVersion
	}
	return o.winVersion
}

func newContainerImages(dist string, targetOS string, targetArchs []string, opts containerImageOptions) []config.Docker {
	images := []config.Docker{}
	for _, targetArch := range targetArchs {
		images = append(images, dockerImageWithOS(dist, targetOS, targetArch, opts))
	}
	return images
}

type fullBuildConfig struct {
	targetOS     string
	targetArch   []string
	armVersion   []string
	ppc64Version []string
}

func (c *fullBuildConfig) Build(dist string) config.Build {
	buildConfig := config.Build{
		ID:     dist + "-" + c.targetOS,
		Dir:    "_build",
		Binary: dist,
		BuildDetails: config.BuildDetails{
			Flags:   []string{"{{ .Env.BUILD_FLAGS }}"},
			Ldflags: []string{"{{ .Env.LD_FLAGS }}"},
		},
		Goos:    []string{c.targetOS},
		Goarch:  c.targetArch,
		Goarm:   c.armVersion,
		Goppc64: c.ppc64Version,
	}

	return buildConfig
}

func (c *fullBuildConfig) OS() string {
	return c.targetOS
}

func (c *fullBuildConfig) Arch() string {
	return c.targetArch[0]
}

func dockerImageWithOS(dist, os, arch string, opts containerImageOptions) config.Docker {
	osArch := osArch{os: os, arch: arch, version: opts.version()}
	var imageTemplates []string
	for _, prefix := range imageRepos {
		imageTemplates = append(
			imageTemplates,
			fmt.Sprintf("%s/%s:{{ .Version }}-%s", prefix, imageName(dist), osArch.imageTag()),
			fmt.Sprintf("%s/%s:latest-%s", prefix, imageName(dist), osArch.imageTag()),
		)
	}

	label := func(name, template string) string {
		return fmt.Sprintf("--label=org.opencontainers.image.%s={{%s}}", name, template)
	}
	imageConfig := config.Docker{
		ImageTemplates: imageTemplates,
		Dockerfile:     "Dockerfile",
		Use:            "buildx",
		BuildFlagTemplates: []string{
			"--pull",
			fmt.Sprintf("--platform=%s", osArch.buildPlatform()),
			label("created", ".Date"),
			label("name", ".ProjectName"),
			label("revision", ".FullCommit"),
			label("version", ".Version"),
			label("source", ".GitURL"),
			"--label=org.opencontainers.image.licenses=Apache-2.0",
		},
		Goos:   os,
		Goarch: arch,
	}
	if arch == armArch {
		imageConfig.Goarm = opts.armVersion
	}
	return imageConfig
}

type osArch struct {
	os, arch, version string
}

func (o *osArch) buildPlatform() string {
	switch o.os {
	case "linux":
		switch o.arch {
		case armArch:
			return fmt.Sprintf("linux/arm/v%s", o.version)
		}
	}
	return fmt.Sprintf("linux/%s", o.arch)
}

func (o *osArch) imageTag() string {
	switch o.os {
	case "linux":
		switch o.arch {
		case armArch:
			return fmt.Sprintf("armv%s", o.version)
		}
	}
	return o.arch
}

func BuildDist(dist string) config.Project {
	switch dist {
	case coreDistro:
		return otelColDist.BuildProject()
	default:
		panic("Unknown distribution")
	}
}

func osDockerManifest(prefix, version, dist, os string, archs []string) config.DockerManifest {
	var imageTemplates []string
	for _, arch := range archs {
		switch arch {
		case armArch:
			for _, armVers := range armVersions(dist) {
				dockerArchTag := (&osArch{os: os, arch: arch, version: armVers}).imageTag()
				imageTemplates = append(
					imageTemplates,
					fmt.Sprintf("%s/%s:%s-%s", prefix, imageName(dist), version, dockerArchTag),
				)
			}
		default:
			imageTemplates = append(
				imageTemplates,
				fmt.Sprintf("%s/%s:%s-%s", prefix, imageName(dist), version, arch),
			)
		}
	}

	return config.DockerManifest{
		NameTemplate:   fmt.Sprintf("%s/%s:%s", prefix, imageName(dist), version),
		ImageTemplates: imageTemplates,
	}
}

func armVersions(dist string) []string {
	return []string{"7"}
}

// imageName translates a distribution name to a container image name.
func imageName(dist string) string {
	return strings.Replace(dist, binaryNamePrefix, imageNamePrefix, 1)
}

// archName translates architecture to docker platform names.
func archName(arch, armVersion string) string {
	switch arch {
	case armArch:
		return fmt.Sprintf("%s/v%s", arch, armVersion)
	default:
		return arch
	}
}
