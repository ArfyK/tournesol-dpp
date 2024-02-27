import numpy as np

from dppy.exact_sampling import elementary_symmetric_polynomials
from elementary_symmetric_polynomials import Node, BinaryTree

n = 2
indexes = list(range(n))
eigenvalues = np.random.default_rng().normal(10, 10, n)

try:
    print("Test Node and Binary tree")
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
except:
    pass

print("\n")

print("Test the computation of elementary symmetric polynomials")
try:
    bt.root.compute_elementary_symmetric_polynomials(n)
    #print(bt.root.elementary_symmetric_polynomials)
    #print(bt.root.right_child.elementary_symmetric_polynomials)
    #print(bt.root.left_child.elementary_symmetric_polynomials)

    esp = elementary_symmetric_polynomials(bt.root.eigenvalues, n)
    #print(esp)
    for i in range(n+1):
        assert bt.root.elementary_symmetric_polynomials[i] == esp[i][n]
except:
    pass
