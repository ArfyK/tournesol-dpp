import numpy as np

from symmetric_polynomials import Node, BinaryTree

n = 3
indexes = list(range(n))
eigenvalues = np.random.default_rng().normal(10, 10, n)

bt = BinaryTree(eigenvalues)
node = bt.root

print(node.indexes)
print(node.eigenvalues)
print(node.right_child)
print(node.left_child)

node.create_children(node.eigenvalues)
print(node.right_child.indexes)
print(node.right_child.eigenvalues)

print(node.left_child.indexes)
print(node.left_child.eigenvalues)

print(node.left_child.right_child.indexes)
print(node.left_child.right_child.eigenvalues)

print(node.left_child.left_child.indexes)
print(node.left_child.left_child.eigenvalues)
