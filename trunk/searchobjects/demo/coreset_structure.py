import numpy as np
from scipy import io
import pdb

#Input: path to mat file representing coreset structure
class CoresetStructure:
	coreset = None
	leaves = []
	child_nodes_list = []

	def __init__(self,coreset_path):
		self.path = coreset_path
		self.coreset = self.load_coreset(coreset_path)


	#PRIVATE FUNCTIONS
	def load_coreset(self,coreset_path):
		mat = io.loadmat(coreset_path)
		coreset = mat['simple_coreset']
		self.coreset = coreset
		return coreset
	
	def get_path(self):
		return self.path

	#PUBLIC FUNCTIONS
	def get_coreset(self):
		if self.coreset == None:
			return load_coreset
		return self.coreset

	def get_coreset_nodes(self):
		return self.coreset['Nodes'][0][0][0] #TODO

	def get_child_nodes_list(self):
		#pdb.set_trace()
		if len(self.child_nodes_list) > 0:
			return self.child_nodes_list

		parent_nodes_list = self.get_parent_nodes_list()
		child_nodes_list = [None] * len(parent_nodes_list)
		for i in range(len(parent_nodes_list)-1): #because last node is root's parent
			node_num = i+1
			parent_node = parent_nodes_list[i]
			parent_node_index = parent_node - 1
			if child_nodes_list[parent_node_index] == None:
				child_nodes_list[parent_node_index] = []
			child_nodes_list[parent_node_index].append(node_num)
		self.child_nodes_list = child_nodes_list
		return child_nodes_list

	def get_parent_nodes_list(self):
		return self.coreset['TreeStructure'][0][0][0]

	def get_t12(self):
		return self.coreset['T12'][0][0]

	def get_leaf_nodes(self): #TODO: can be done in O(1) if recorded during tree creation
		if len(self.leaves) > 0:
			return self.leaves

		leaf_nodes = []
		nodes = self.get_coreset_nodes()
		for node_ind in range(len(nodes)):
			node = nodes[node_ind]
			node_type = node['NodeType'][0]
			if node_type.lower() == 'leaf':
				#node_num are index+1
				leaf_nodes.append(node_ind + 1)
		self.leaves = leaf_nodes
		return leaf_nodes
	
	def get_all_node_keyframes(self):
		keyframes = []
		nodes = self.get_coreset_nodes()
		for node_ind in range(len(nodes)):
			node_keyframes = nodes[node_ind]['KeyFrames'][0]
			keyframes.append(node_keyframes)
		return keyframes
	
	
	def get_keyframes(self):
		nodes = self.get_coreset_nodes()
		leaves = self.get_leaf_nodes()
		keyframes = []
		for node_ind in range(len(leaves)): 
		        keyframes.extend(nodes[leaves[node_ind]-1]['KeyFrames'][0])
		return keyframes
	
	def is_leaf(self, node):
		node_str = self.get_coreset_nodes()[node-1]
		return node_str['NodeType'][0].lower() == 'leaf'