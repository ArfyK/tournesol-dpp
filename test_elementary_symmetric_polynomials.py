import copy

import numpy as np

from dppy.exact_sampling import elementary_symmetric_polynomials
from elementary_symmetric_polynomials import Node, BinaryTree

n = 3
indexes = list(range(n))
eigenvalues = np.random.default_rng().normal(10, 10, n)

try:
    print("Test create_children")
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
    print("create_children failed")

print("\n")

print("Test the computation of elementary symmetric polynomials")
bt.root.compute_elementary_symmetric_polynomials(n)
# print(bt.root.elementary_symmetric_polynomials)
# print(bt.root.right_child.elementary_symmetric_polynomials)
# print(bt.root.left_child.elementary_symmetric_polynomials)

esp = elementary_symmetric_polynomials(bt.root.eigenvalues, n)
# print(esp)
for i in range(n + 1):
    try:
        assert bt.root.elementary_symmetric_polynomials[i] == esp[i][n]
    except AssertionError:
        print(bt.root.elementary_symmetric_polynomials[i])
        print(esp[i][n])

print("\n")
print("Test the path removing algorithm")
for i in range(n):
    print(i)
    bt_copy = copy.deepcopy(bt)
    bt_copy.root.remove_path(i)
    node = bt_copy.root

    print(node.indexes)
    print(node.eigenvalues)

    print(node.right_child.indexes)
    print(node.right_child.eigenvalues)

    print(node.left_child.indexes)
    print(node.left_child.eigenvalues)

print('\n')
print("Test calculation of e^{-n}_{k-1}")
for i in range(n):
    bt_copy = copy.deepcopy(bt)
    bt_copy.root.remove_path(i)
    bt_copy.root.compute_elementary_symmetric_polynomials(n - 1)
    esp = elementary_symmetric_polynomials(
        np.concatenate((bt.root.eigenvalues[:i], bt.root.eigenvalues[i + 1 :])), n - 1
    )
    try:
        assert np.array_equal(bt_copy.root.elementary_symmetric_polynomials, esp[:,n - 1])
    except AssertionError:
        print(bt_copy.root.elementary_symmetric_polynomials)
        print(esp[:,n - 1])
