# 🧰 DevOps Tools Docker Image

A lightweight, all-in-one **DevOps toolkit** container built on **Alpine Linux** with **Python 3.10**.  
It bundles the most commonly used **cloud CLIs**, **Kubernetes tools**, and **Terraform ecosystem utilities** — ready to use instantly in any environment.

Ideal for **IaC developers**, **multi-cloud engineers**, and **CI/CD pipelines** that need a consistent DevOps CLI workspace.

## 🚀 Features

- 🧩 **Cloud CLIs**
  - AWS CLI (`aws`)
  - Azure CLI (`az`)
  - Google Cloud SDK (`gcloud`, `gsutil`, `bq`)
  - Oracle Cloud CLI (`oci`)
  - Hetzner Cloud CLI (`hcloud`)
- ☸️ **Kubernetes Tools**
  - `kubectl`
  - `kubectx` / `kubens`
  - `helm`
- 🪄 **Terraform Stack**
  - Terraform via `tfenv`
  - Terragrunt via `tgenv`
  - `terraform-docs`
- 🧱 **Base Utilities**
  - `bash`, `curl`, `git`, `jq`, `ncurses`, `openssh`, `python3/pip`
- 🔒 Runs as a non-root user `devops`  
- 🧩 Multi-cloud ready and easy to extend

---

## 🧩 Included Versions

> Versions are pinned as build `ARG`s in the [Dockerfile](Dockerfile) and kept
> current by Renovate. The table below is synced from those values.

| Tool | Version |
|------|----------|
| Alpine | 3.24 |
| Python | 3.10 |
| AWS CLI | 2.13.0 |
| Azure CLI | 2.90.0 |
| Google Cloud SDK | 443.0.0 |
| OCI CLI | 3.92.0 |
| Hetzner CLI | 1.67.0 |
| kubectl | v1.37.0 |
| kubectx / kubens | v0.11.0 |
| Helm | v4.2.4 |
| tfenv | v3.2.2 |
| tgenv | v0.0.3 |
| Terraform | 1.16.0 |
| Terragrunt | 0.99.5 |
| terraform-docs | 0.24.0 |
| SOPS | 3.12.1 |

---

## 🐳 Usage Examples

### Run interactively
```bash
docker run -it --rm ghcr.io/derzkiy-dobryak/devops-tools:latest /bin/bash
```

### Mount current working directory

```bash
docker run -it --rm \
  -v $(pwd):/workdir \
  ghcr.io/derzkiy-dobryak/devops-tools:latest
```

### Example: Terraform

```bash
docker run -it --rm \
  -v $(pwd):/workdir \
  ghcr.io/derzkiy-dobryak/devops-tools:latest \
  terraform plan
```

### Example: Kubernetes

```bash
docker run -it --rm \
  -v ~/.kube/config:/home/devops/.kube/config:ro \
  ghcr.io/derzkiy-dobryak/devops-tools:latest \
  kubectl get pods
```

---

## 🧰 Create a Local CLI Wrapper

You can add a simple function to your shell (e.g. `~/.bashrc` or `~/.zshrc`)
to make using this image as easy as running a normal CLI command.

```bash
# Path to your configuration storage (adjust as needed)
DEVOPS_HOME="$HOME/.config/devops-tools"

# Create and use the wrapper function
devops_tools() {
  docker run --rm --name devops-$RANDOM --network=host -it \
    -v "$DEVOPS_HOME/ssh:/home/devops/.ssh" \
    -v "$DEVOPS_HOME/kube:/home/devops/.kube" \
    -v "$DEVOPS_HOME/aws:/home/devops/.aws" \
    -v "$DEVOPS_HOME/azure:/home/devops/.azure" \
    -v "$DEVOPS_HOME/gcp:/home/devops/.config/gcloud" \
    -v "$DEVOPS_HOME/oci:/home/devops/.oci" \
    -v "$DEVOPS_HOME/hetzner:/home/devops/.config/hcloud" \
    -v "$DEVOPS_HOME/terraform:/home/devops/.terraform.d" \
    -v "$DEVOPS_HOME/terragrunt:/home/devops/.terragrunt.d" \
    -v "$(pwd):/workdir" \
    -w /workdir \
    ghcr.io/derzkiy-dobryak/devops-tools:latest "$@"
}

# Optional alias for quick access
alias dt=devops_tools
```

Now you can run:

```bash
dt terraform apply
dt kubectl get pods
dt aws s3 ls
```

This setup keeps your local credentials in `~/.config/devops-tools`
and automatically mounts them into the container at runtime.

---

## ⚙️ Environment Details

* Default user: `devops`
* Home directory: `/home/devops`
* Working directory: `/workdir`
* PATH includes:

  ```
  /usr/local/tgenv/bin
  /usr/local/tfenv/bin
  /usr/local/bin
  /usr/local/gcloud/bin
  ```

---

## 🧱 Build Locally

To build your own version:

```bash
git clone https://github.com/derzkiy-dobryak/devops-tools-docker.git
cd devops-tools-docker

docker build -t devops-tools:latest .
```

Override versions if needed:

```bash
docker build \
  --build-arg TERRAFORM_VERSION=1.5.0 \
  --build-arg HELM_VERSION=v3.13.0 \
  -t devops-tools:custom .
```

---

## 🛠️ Extending the Image

Add more tools with a simple `Dockerfile`:

```dockerfile
FROM ghcr.io/derzkiy-dobryak/devops-tools:latest
RUN apk add --no-cache make aws-sam-cli
```

---

## 🔒 Security

* Base image and every bundled tool version are pinned and updated via Renovate
  (including base-image digest pinning and SHA-pinned GitHub Actions).
* `kubectl` and `helm` downloads are checksum-verified during the build.
* Every push builds an [SBOM][sbom] and [SLSA provenance][prov] attestation and
  runs a [Trivy][trivy] scan; results land in the repo's *Security → Code
  scanning* tab and a `CRITICAL` finding fails the build.
* The image runs as the non-root `devops` user. Mount credentials read-only and
  drop capabilities you don't need, e.g. `--cap-drop ALL --security-opt no-new-privileges`.
* **Platform:** `linux/amd64` only (tool binaries are amd64); on Apple Silicon
  Docker runs it via emulation.

[sbom]: https://docs.docker.com/build/metadata/attestations/sbom/
[prov]: https://docs.docker.com/build/metadata/attestations/slsa-provenance/
[trivy]: https://trivy.dev/

---

## 🧾 License

MIT License

---

## 💡 Maintainer

**Maintainer:** [SilentVoltage](https://github.com/SilentVoltage)

**Registry:** `ghcr.io/derzkiy-dobryak/devops-tools`

---
