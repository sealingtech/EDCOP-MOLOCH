# EDCOP Moloch

Table of Contents
-----------------
 
* [Configuration Guide](#configuration-guide)
	* [Image Repository](#image-repository)
	* [Networks](#networks)
	* [Persistent Storage](#persistent-storage)
	* [Node Selector](#node-selector)
	* [Ingress](#ingress)
	* [Moloch Configuration](#moloch-configuration)
		* [Performance](#performance)
		* [Environment Variables](#environment-variables)
		* [Resource Limits](#resource-limits)
	
# Configuration Guide

Within this configuration guide, you will find instructions for modifying Moloch's helm chart. All changes should be made in the *values.yaml* file.
Please share any bugs or feature requests via GitHub issues.
 
## Image Repository

By default, the image is pulled from Docker's Hub, which is a customized Moloch image with the ability to specify viewer/capture only nodes. This value should not be changed because the configuration depends on the environment variables specified in the yamls.
 
```
images:
  moloch: miked235/moloch
```
 
## Networks

Moloch only uses 2 interfaces because it can only be deployed in passive mode to record traffic. By default, these interfaces are named *calico* and *passive*. 

```
networks:
  overlay: calico
  passive: passive
```
 
To find the names of your networks, use the following command:
 
```
# kubectl get networks
NAME		AGE
calico		1d
passive		1d
inline-1	1d
inline-2	1d
```

## Persistent Storage

These values tell Kubernetes where Moloch's PCAPs and logs should be stored on the host for persistent storage. The *raw* option is for Moloch's raw PCAP files and the *logs* option is for Moloch's capture/viewer logs. By default, these values are set to */bulk/EDCOP/moloch/* but should be changed according to your logical volume setup. 

```
volumes:
  logs: /bulk/EDCOP/moloch/logs
  raw: /bulk/EDCOP/moloch/raw
```
	  
## Node Selector

This value tells Kubernetes which hosts the daemonset and statefulset should be deployed to by using labels given to the hosts. The viewer nodes run on the master while the capture nodes run on the workers. Hosts without the defined label will not receive pods. 
 
```
nodeSelector:
  worker: worker
  viewer: master
```
 
To find out what labels your hosts have, please use the following:
```
# kubectl get nodes --show-labels
NAME		STATUS		ROLES		AGE		VERSION		LABELS
master 		Ready		master		1d		v1.10.0		...,nodetype=master
minion-1	Ready		<none>		1d		v1.10.0		...,nodetype=minion
minion-2	Ready		<none>		1d		v1.10.0		...,nodetype=minion
```

## Ingress

In order to serve web traffic to the GUIs provided by the tools, we use Traefik in conjuction with Kubernetes ingress objects. This value should be the FQDN of your EDCOP host. By default, Moloch will be available at $FQDN/moloch/

```
ingress:
  host: physial.edcop.io
```

## Moloch Configuration

Moloch is used as a FPCAP solution, so some configuration is required for optimal performance. Clusters that run Moloch  will need 2 networks: an overlay and passive tap network.

### Performance

Before tweaking Moloch's performance, you need to define how many instances should be run. The value below should be equal to the number of *worker* nodes you have. Unfortunately, there is no Statefulset-Daemonset, so we're stuck defining the number of nodes we need until there is a better way.

```
molochConfig:
  workerNodes: 3
```

Moloch allows you to set limits on many different performance settings, but the ones included in the ```values.yaml``` are the most important. Before configuring these values, you should read Moloch's best practices at https://github.com/aol/moloch/wiki/Settings#High_Performance_Settings. By default, these values are set to Moloch's recommended settings. 

```
molochConfig:
  performance:
    maxStreams: 1000000
    maxPacketsInQueue: 200000
    maxPackets: 10000
    packetThreads: 5
    pcapWriteSize: 262143
    tpacketv3Threads: 2
```

### Environment Variables

In order to make Moloch more secure, you need to set a couple of passwords for Moloch's data transfer and access to its viewer. You can set the cluster and encrypt passwords to something random, but the admin password will be used to access the web interface as the admin superuser. You could use something like pwgen to create random passwords, but this isn't necessary. 

```
molochConfig:
  env:
    adminpw: supersecretpw
    clusterpw: anothersupersecretpw
    encryptpw: randencryptpw
```

### Resource Limits

You can set limits on Moloch to ensure it doesn't use more CPU/memory space than necessary. Finding the right balance can be tricky, so some testing may be required. 

```
molochConfig:
  requests:
    cpu: 100m
    memory: 64Mi
  limits:
    cpu: 2
    memory: 4G
```
