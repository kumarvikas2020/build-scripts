######################################################### {COPYRIGHT-TOP} ###
# IBM Confidential
# OCO Source Materials
# 5900-AEO
#
# Copyright IBM Corp. 2020, 2021
#
# The source code for this program is not published or otherwise
# divested of its trade secrets, irrespective of what has been
# deposited with the U.S. Copyright Office.
######################################################### {COPYRIGHT-END} ###
# Build the manager binary
FROM golang:1.13 as builder
LABEL stage=operator-builder

WORKDIR /workspace
# Copy the Go Modules manifests
COPY go.mod go.mod
COPY go.sum go.sum

ENV GOPRIVATE="github.ibm.com"
ARG GIT_TOKEN

RUN [ -z "$GIT_TOKEN" ] && echo "GIT_TOKEN is required" && exit 1 || true

RUN echo -e "machine github.ibm.com\nlogin ${GIT_TOKEN}" > ~/.netrc


# cache deps before building and copying source so that we don't need to re-download as much
# and so that source changes don't invalidate our downloaded layer
RUN go mod download

# Copy the go source
COPY main.go main.go
COPY api/ api/
COPY pkg/ pkg/
COPY internal/ internal/
COPY controllers/ controllers/

# Build
RUN CGO_ENABLED=0 GOOS=linux GOARCH=ppc64le GO111MODULE=on go build -a -o manager main.go

FROM us.icr.io/abp-ubi8/iaf-minimal:latest
WORKDIR /
COPY --from=builder /workspace/manager .
USER 1000:1000

ENTRYPOINT ["/manager"]
