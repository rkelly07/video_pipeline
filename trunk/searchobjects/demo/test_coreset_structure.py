#Testing coreset_structure.py
from coreset_structure import CoresetStructure

coreset_path = '/home/serverdemo/LOCAL_DATA/coresets/simple_coreset/simpler_tree_0408184702.mat'
coreset_str = CoresetStructure(coreset_path)

#test all functions
nodes = coreset_str.get_coreset_nodes()
print "Nodes are: ", nodes
parent_list = coreset_str.get_parent_nodes_list()
print "Parent list is", parent_list
children_list = coreset_str.get_child_nodes_list()
print "Children list is", children_list
leaves = coreset_str.get_leaf_nodes()
print "Leaves are", leaves
T12 = coreset_str.get_t12()
print "T12 is", T12
