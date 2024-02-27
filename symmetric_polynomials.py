#Implements the algorithm describe in "DPP for Machine Learning" in section 5.2.3 computing the singleton marginals of a k-dpp

import numpy as np

class Node:
    def __init__(self, indexes=None, eigen_values=None, symmetric_polynomials=None, left_child=None, right_child=None):
        self.indexes = indexes
        self.eigen_values = eigen_values
        self.symmetric_polynomials = symmetric_polynomials
        self.left_child = left_child
        self.right_child = right_child

