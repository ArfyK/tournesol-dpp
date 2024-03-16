import copy
import time

import numpy as np

from dppy.exact_sampling import elementary_symmetric_polynomials
from elementary_symmetric_polynomials import Node

n = 3
indexes = list(range(n))
eigenvalues = np.random.default_rng().normal(10, 10, n)

try:
    print("Test create_children")
    node = Node.from_eigen_values(eigenvalues)

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
node.compute_elementary_symmetric_polynomials(n)

esp = elementary_symmetric_polynomials(eigenvalues, n)
# print(esp)
for i in range(n + 1):
    try:
        assert node.elementary_symmetric_polynomials[i] == esp[i][n]
    except AssertionError:
        print(node.elementary_symmetric_polynomials[i])
        print(esp[i][n])

print("\n")
print("Test the path removing algorithm")
for i in range(n):
    print(i)
    node_copy = copy.deepcopy(node)
    node_copy.remove_path(i)

    print(node_copy.indexes)
    print(node_copy.eigenvalues)

    print(node_copy.right_child.indexes)
    print(node_copy.right_child.eigenvalues)

    print(node_copy.left_child.indexes)
    print(node_copy.left_child.eigenvalues)

print("\n")
print("Test calculation of e^{-n}_{k-1}")
for i in range(n):
    node_copy = copy.deepcopy(node)
    node_copy.remove_path(i)
    node_copy.compute_elementary_symmetric_polynomials(n - 1)
    esp = elementary_symmetric_polynomials(
        np.concatenate((node.eigenvalues[:i], node.eigenvalues[i + 1 :])), n - 1
    )
    try:
        assert np.array_equal(node_copy.elementary_symmetric_polynomials, esp[:, n - 1])
    except AssertionError:
        print(node_copy.elementary_symmetric_polynomials)
        print(esp[:, n - 1])

print("\n")
print("Test Node.elementary_symmetric_polynomials")
my_esp = Node.elementary_symmetric_polynomials(eigenvalues, n)
esp = elementary_symmetric_polynomials(eigenvalues, n)
try:
    assert np.array_equal(my_esp, esp[:, n])
except AssertionError:
    print(my_esp)
    print(esp[:, n])

print("\n")
print("Test Node.partial_elementary_symmetric_polynomials")
my_esp_k, my_partials = Node.partial_elementary_symmetric_polynomials(eigenvalues, n)
esp = elementary_symmetric_polynomials(eigenvalues, n)
try:
    assert my_esp_k == esp[n, n]
except AssertionError:
    print(my_esp_k)
    print(esp[n, n])

for i in range(n):
    partial_esp = elementary_symmetric_polynomials(
        np.concatenate((eigenvalues[:i], eigenvalues[i + 1 :])), n - 1
    )
    try:
        assert my_partials[i] == partial_esp[n - 1, n - 1]
    except AssertionError:
        print(my_partials[i])
        print(partial_esp[n - 1, n - 1])

print("\n")
print("Compare computation times")
n = 500
k = 10
print("n = " + str(n))
print("k = " + str(k))
eigenvalues = np.random.default_rng().normal(10, 10, n)

time_start = time.time()
Node.partial_elementary_symmetric_polynomials(eigenvalues, k)
time_elapsed = time.time() - time_start
print("Binary tree algorithm took: " + str(time_elapsed))

time_start = time.time()
for i in range(k):
    elementary_symmetric_polynomials(
        np.concatenate((eigenvalues[:i], eigenvalues[i + 1 :])), k - 1
    )
time_elapsed = time.time() - time_start
print("Naive algorithm took: " + str(time_elapsed))
