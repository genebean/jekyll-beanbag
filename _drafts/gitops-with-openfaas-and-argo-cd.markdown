---
author: gene
title: GitOps with OpenFaaS and Argo CD
---

This is a quick look at how you can apply the GitOps principal of a git repository being the source of truth to OpenFaaS running in Kubernetes. I’ll cover managing OpenFaaS itself with Argo CD and how that management can be extended the functions you deploy.

## Components

Let’s first outline the components used and what role each plays:

* OpenFaaS: the framework and code for running functions 
* OpenFaaS Operator: allows managing functions with kubectl
* Argo CD: a Continuous Delivery tool centered on GitOps
* k3s: a lightweight Kubernetes distribution from Rancher
* MetalLB: a load-balancer implementation for bare metal Kubernetes clusters
* nginx-ingress: a Kubernetes ingress controller
* ExternalDNS: synchronizes exposed ingresses with a DNS provider
* cert-manager: a tool for automating management of Let’s Encrypt certificates in Kubernetes

## Diving In