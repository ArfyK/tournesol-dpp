# Implements the algorithm describe in "DPP for Machine Learning" in section 5.2.3 computing the singleton marginals of a k-dpp

import numpy as np


class Node:
    def __init__(
        self,
        indexes=None,
        eigenvalues=None,
        symmetric_polynomials=None,
        left_child=None,
        right_child=None,
    ):
        self.indexes = indexes
        self.eigenvalues = eigenvalues
        self.symmetric_polynomials = symmetric_polynomials
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


class BinaryTree:
    def __init__(self, eigenvalues):
        self.root = Node(eigenvalues=eigenvalues, indexes=list(range(eigenvalues.size)))
        self.root.create_children(eigenvalues)


