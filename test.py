import numpy as np

from symmetric_polynomials import Node

n = 3
indexes = list(range(n))
eigenvalues = np.random.default_rng().normal(10, 10,n)

node = Node(indexes=indexes, eigenvalues=eigenvalues)

print(node)

