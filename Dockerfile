############################
# Versions
############################
ARG ALPINE_VERSION=3.17
ARG AWS_VERSION="2.13.0"
ARG KUBE_VERSION="v1.35.0"
ARG KUBECTX_VERSION="v0.9.5"
ARG HELM_VERSION="v3.19.4"
ARG TGENV_VERSION="v0.0.3"
ARG TFENV_VERSION="v3.0.0"
ARG TF_DOCS_VERSION="0.21.0"
ARG TERRAGRUNT_VERSION="0.97.0"
ARG TERRAFORM_VERSION="1.14.3"
ARG AZ_CLI_VERSION="2.81.0"
ARG HCLOUD_VERSION="1.59.0"
ARG OCI_CLI_VERSION="3.71.4"
ARG GCLOUD_VERSION="443.0.0"

################ BASE BUILDER ################
FROM python:3.10-alpine${ALPINE_VERSION} AS base-builder
RUN apk add --no-cache git unzip groff build-base libffi-dev cmake curl bash coreutils jq ncurses openssh python3 py3-pip

################ AWS CLI ################
FROM base-builder AS aws-cli-builder
ARG AWS_VERSION
RUN git clone --depth 1 -b ${AWS_VERSION} https://github.com/aws/aws-cli.git \
 && cd aws-cli \
 && ./configure --with-install-type=portable-exe --with-download-deps \
 && make && make install \
 && rm -rf /usr/local/lib/aws-cli/aws_completer \
           /usr/local/lib/aws-cli/awscli/data/ac.index \
           /usr/local/lib/aws-cli/awscli/examples \
 && find /usr/local/lib/aws-cli/awscli/data -name "completions-1*.json" -delete \
 && find /usr/local/lib/aws-cli/awscli/botocore/data -name "examples-1.json" -delete \
 && (cd /usr/local/lib/aws-cli; for a in *.so*; do test -f /lib/$a && rm $a; done)

################ KUBECTL + KUBECTX/KUBENS ################
FROM base-builder AS kube-tools-builder
ARG KUBE_VERSION
ARG KUBECTX_VERSION

RUN curl -fsSL https://dl.k8s.io/release/${KUBE_VERSION}/bin/linux/amd64/kubectl -o /usr/local/bin/kubectl \
 && chmod +x /usr/local/bin/kubectl

RUN git clone --depth 1 -b ${KUBECTX_VERSION} https://github.com/ahmetb/kubectx /kubectx \
 && cp /kubectx/kubectx /kubectx/kubens /usr/local/bin/ \
 && chmod +x /usr/local/bin/kubectx /usr/local/bin/kubens \
 && rm -rf /kubectx

################ HELM ################
FROM base-builder AS helm-builder
ARG HELM_VERSION
RUN curl -fsSL https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -o /helm.tar.gz \
 && tar -xzf /helm.tar.gz \
 && mv linux-amd64/helm /usr/local/bin/helm \
 && chmod +x /usr/local/bin/helm \
 && rm -rf linux-amd64 helm.tar.gz

################ TF TOOLS (tgenv/tfenv + terraform-docs) ################
FROM base-builder AS tf-tools-builder
ARG TGENV_VERSION
ARG TFENV_VERSION
ARG TF_DOCS_VERSION

RUN git clone --depth 1 -b ${TGENV_VERSION} https://github.com/cunymatthieu/tgenv.git /usr/local/tgenv \
 && git clone --depth 1 -b ${TFENV_VERSION} https://github.com/tfutils/tfenv.git /usr/local/tfenv

RUN curl -fsSL "https://github.com/terraform-docs/terraform-docs/releases/download/v${TF_DOCS_VERSION}/terraform-docs-v${TF_DOCS_VERSION}-linux-amd64.tar.gz" -o /terraform-docs.tar.gz \
 && tar -xzf /terraform-docs.tar.gz \
 && mv terraform-docs /usr/local/bin/terraform-docs \
 && chmod +x /usr/local/bin/terraform-docs \
 && rm -f /terraform-docs.tar.gz

################ AZ CLI ################
FROM base-builder AS az-cli-builder
ARG AZ_CLI_VERSION
RUN pip install --no-cache-dir "azure-cli==${AZ_CLI_VERSION}" \
 && echo "azure-cli installed"

################ Hetzner CLI ################
FROM base-builder AS hetzner-cli-builder
ARG HCLOUD_VERSION
RUN curl -fsSL https://github.com/hetznercloud/cli/releases/download/v${HCLOUD_VERSION}/hcloud-linux-amd64.tar.gz -o /hcloud.tar.gz \
 && tar -xzf /hcloud.tar.gz \
 && mv hcloud /usr/local/bin/hcloud \
 && chmod +x /usr/local/bin/hcloud \
 && rm -f /hcloud.tar.gz

################ OCI CLI ################
FROM base-builder AS oracle-cli-builder
ARG OCI_CLI_VERSION
RUN pip install --no-cache-dir "oci-cli==${OCI_CLI_VERSION}" \
 && echo "oci-cli installed"

################ GCloud CLI ################
FROM base-builder AS gcloud-cli-builder
ARG GCLOUD_VERSION
RUN curl -fsSL "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GCLOUD_VERSION}-linux-x86_64.tar.gz" -o /gcloud.tar.gz \
 && tar -xzf /gcloud.tar.gz \
 && mv google-cloud-sdk /usr/local/gcloud \
 && /usr/local/gcloud/install.sh --quiet --path-update=false --bash-completion=false --rc-path=/dev/null \
 && ln -s /usr/local/gcloud/bin/gcloud /usr/local/bin/gcloud \
 && ln -s /usr/local/gcloud/bin/gsutil /usr/local/bin/gsutil \
 && ln -s /usr/local/gcloud/bin/bq /usr/local/bin/bq \
 && rm -f /gcloud.tar.gz

################ DEVOPS TOOLS ################
FROM python:3.10-alpine${ALPINE_VERSION} AS devops-tools

ARG TERRAGRUNT_VERSION
ARG TERRAFORM_VERSION

RUN apk add --no-cache bash curl git jq ncurses openssh python3 py3-pip
RUN addgroup -S devops && adduser -S devops -G devops -h /home/devops

COPY --from=aws-cli-builder /usr/local/lib/aws-cli/ /usr/local/lib/aws-cli/
RUN ln -s /usr/local/lib/aws-cli/aws /usr/local/bin/aws

COPY --from=kube-tools-builder /usr/local/bin/kubectl /usr/local/bin/kubectl
COPY --from=kube-tools-builder /usr/local/bin/kubectx /usr/local/bin/kubectx
COPY --from=kube-tools-builder /usr/local/bin/kubens /usr/local/bin/kubens
COPY --from=helm-builder /usr/local/bin/helm /usr/local/bin/helm

COPY --from=tf-tools-builder /usr/local/tgenv /usr/local/tgenv
COPY --from=tf-tools-builder /usr/local/tfenv /usr/local/tfenv
COPY --from=tf-tools-builder /usr/local/bin/terraform-docs /usr/local/bin/terraform-docs

COPY --from=az-cli-builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=az-cli-builder /usr/local/bin/az /usr/local/bin/az

COPY --from=hetzner-cli-builder /usr/local/bin/hcloud /usr/local/bin/hcloud

COPY --from=oracle-cli-builder /usr/local/lib/python3.10/site-packages /usr/local/lib/python3.10/site-packages
COPY --from=oracle-cli-builder /usr/local/bin/oci /usr/local/bin/oci

COPY --from=gcloud-cli-builder /usr/local/gcloud /usr/local/gcloud

RUN ln -s /usr/local/gcloud/bin/gcloud /usr/local/bin/gcloud \
 && ln -s /usr/local/gcloud/bin/gsutil /usr/local/bin/gsutil \
 && ln -s /usr/local/gcloud/bin/bq /usr/local/bin/bq

RUN mkdir -p /home/devops/bin \
 && chown -R devops:devops /home/devops \
 && chown -R root:root /usr/local/bin /usr/local/lib /usr/local/gcloud || true \
 && chmod +x /usr/local/bin/* && chmod +x /usr/local/tgenv/bin/* || true

USER root
ENV HOME=/home/devops
ENV PATH="/usr/local/tgenv/bin:/usr/local/tfenv/bin:/usr/local/bin:/usr/local/gcloud/bin:$PATH"
WORKDIR /home/devops

RUN tfenv install ${TERRAFORM_VERSION} && tfenv use ${TERRAFORM_VERSION} \
 && tgenv install ${TERRAGRUNT_VERSION} && tgenv use ${TERRAGRUNT_VERSION}

USER devops

WORKDIR /workdir
