Instance File Format

Each file contains information about the number of services, clients, and clusters, followed by a list of edges that define connections between services and clients. The format is specified as follows:

1. Header Information

The first line contains three integers separated by spaces:
S: the number of services.
C: the number of clients.
K: the number of clusters.

2. Edge List

Each subsequent line contains two integers representing an edge:
s: service code.
t: client code connected to the service s.
