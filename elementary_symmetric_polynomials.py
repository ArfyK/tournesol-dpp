# Implements the algorithm describe in "DPP for Machine Learning" in section 5.2.3 computing the singleton marginals of a k-dpp

import numpy as np


class Node:
    def __init__(
        self,
        indexes=None,
        eigenvalues=None,
        left_child=None,
        right_child=None,
    ):
        self.indexes = indexes
        self.eigenvalues = eigenvalues
        self.elementary_symmetric_polynomials = None
        self.left_child = left_child
        self.right_child = right_child

    def create_children(self, eigenvalues):
        n = len(self.indexes)
        if n > 1:
            self.right_child = Node(
                indexes=self.indexes[: n // 2],
                eigenvalues=eigenvalues[self.indexes[: n // 2]],
            )
            self.right_child.create_children(eigenvalues)
            self.left_child = Node(
                indexes=self.indexes[n // 2 :],
                eigenvalues=eigenvalues[self.indexes[n // 2 :]],
            )
            self.left_child.create_children(eigenvalues)

    def compute_elementary_symmetric_polynomials(self, k):
        if len(self.indexes) == 1:
            self.elementary_symmetric_polynomials = np.concatenate(
                ([1], self.eigenvalues, np.zeros(k - 1))
            )
        else:
            self.right_child.compute_elementary_symmetric_polynomials(k)
            self.left_child.compute_elementary_symmetric_polynomials(k)
            self.elementary_symmetric_polynomials = np.zeros(k+1)
            for i in range(k+1):
                self.elementary_symmetric_polynomials[i] = np.dot(
                    self.left_child.elementary_symmetric_polynomials[:i+1],
                    np.flip(self.right_child.elementary_symmetric_polynomials[:i+1]),
                )


class BinaryTree:
    def __init__(self, eigenvalues):
        self.root = Node(eigenvalues=eigenvalues, indexes=list(range(eigenvalues.size)))
        self.root.create_children(eigenvalues)
