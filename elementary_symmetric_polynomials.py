# Implements the algorithm describe in "DPP for Machine Learning" in section 5.2.3 computing the singleton marginals of a k-dpp
import copy

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
        self.elementary_symmetric_polynomials = np.array(np.nan)
        self.left_child = left_child
        self.right_child = right_child

    @classmethod
    def from_eigen_values(cls, eigenvalues):
        node = cls(indexes=list(range(len(eigenvalues))), eigenvalues=eigenvalues)
        node.create_children(eigenvalues)
        return node

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
            if self.right_child.elementary_symmetric_polynomials.all():
                self.right_child.compute_elementary_symmetric_polynomials(k)
            if self.left_child.elementary_symmetric_polynomials.all():
                self.left_child.compute_elementary_symmetric_polynomials(k)
            self.elementary_symmetric_polynomials = np.zeros(k + 1)
            for i in range(k + 1):
                self.elementary_symmetric_polynomials[i] = np.dot(
                    self.left_child.elementary_symmetric_polynomials[: i + 1],
                    np.flip(self.right_child.elementary_symmetric_polynomials[: i + 1]),
                )

    def copy(self, other_node):
        self.indexes = other_node.indexes
        self.eigenvalues = other_node.eigenvalues
        self.elementary_symmetric_polynomials = (
            other_node.elementary_symmetric_polynomials
        )
        self.left_child = other_node.left_child
        self.right_child = other_node.right_child

    def remove_path(self, index):
        if index not in self.indexes:
            return
        if self.left_child.indexes == [index]:
            self.copy(self.right_child)
            return
        elif self.right_child.indexes == [index]:
            self.copy(self.left_child)
            return
        else:
            self.elementary_symmetric_polynomials = np.array(np.nan)
            self.left_child.remove_path(index)
            self.right_child.remove_path(index)
            return

    @classmethod
    def elementary_symmetric_polynomials(cls, eigenvalues, k):
        node = Node.from_eigen_values(eigenvalues)
        node.compute_elementary_symmetric_polynomials(k)
        return node.elementary_symmetric_polynomials

    @classmethod
    def partial_elementary_symmetric_polynomials(cls, eigenvalues, k):
        node = Node.from_eigen_values(eigenvalues)
        node.compute_elementary_symmetric_polynomials(k)
        esp_k = node.elementary_symmetric_polynomials[k]

        n_eigenvalues = len(eigenvalues)
        partial_elementary_symmetric_polynomials = np.zeros(n_eigenvalues)
        for i in range(n_eigenvalues):
            node_copy = copy.deepcopy(node)
            node_copy.remove_path(i)
            node_copy.compute_elementary_symmetric_polynomials(k - 1)
            partial_elementary_symmetric_polynomials[
                i
            ] = node_copy.elementary_symmetric_polynomials[k - 1]

        return esp_k, partial_elementary_symmetric_polynomials
