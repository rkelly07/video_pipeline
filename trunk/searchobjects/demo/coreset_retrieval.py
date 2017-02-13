from coreset_structure import CoresetStructure
from demo.models import *
import random

#Function to retrieve using the coreset tree
#Inputs: 
####path to coreset tree (coreset_path)
####query range (q_range)
####query text (q_text)
def coreset_retrieval(coreset_str, q_range, class_label,scene_id,threshold, is_synthetic_retrieval, alpha=0.5):
	
	#first make q_range proper, in case user queries more than the tree range
	#now make the q_range proper
	#last node is always the root node, so its span is the entire tree span
	coreset_t12 = coreset_str.get_t12()
	tree_1, tree_2 = coreset_t12[-1]
	
	q1, q2 = q_range
	q1 = max(tree_1, q1)
	q2 = min(tree_2, q2)	
	q_range = [q1, q2]	
	
	# Make parent_nodes_list and child_nodes_list
	#print "scene id is", scene_id
	#print "coreset path is", coreset_str.get_path()
	parent_nodes_list = coreset_str.get_parent_nodes_list()
	#print "Parent nodes list is", parent_nodes_list
	if len(parent_nodes_list) == 0:
		print "break here for debugging"
	child_nodes_list = coreset_str.get_child_nodes_list() #or directly from coreset_str
	

	coreset_leaves = coreset_str.get_leaf_nodes()

	#find total leaves in range
	leaf_start_ind, leaf_end_ind = get_leaf_indices_in_range(coreset_str, q_range)
	total_leaves_in_range = leaf_end_ind - leaf_start_ind + 1
	#print "total leaves in range are", total_leaves_in_range
	#print "all leaves in this range are", coreset_leaves[leaf_start_ind : leaf_end_ind+1]
	
	
	init_node = coreset_leaves[leaf_end_ind]
	v = init_node
	previous = float('inf')	
	done_nodes = set([])
	done_leaves = []	
	search_range = []
	cur_regions = []
	loop_finished = False
	while True: 
		#print "Done nodes are", done_nodes
		#print "current v is", v
		#print "Its range is", coreset_t12[v-1]
		parent = parent_nodes_list[v-1]
		node_too_big = is_range_over_another(coreset_t12[v-1],q_range) or (parent == 0)
		
		node_out_of_range = are_ranges_disjoint(coreset_t12[v-1], q_range)
		
		#check if the node is already done before
		node_done = is_node_done(v, child_nodes_list[v-1], done_nodes) or node_out_of_range

		if node_done and v not in done_nodes:
			done_nodes.add(v)
		

		
		if (node_too_big and node_done) or len(done_leaves) >= 1*(total_leaves_in_range):
			#print "done leaves are", done_leaves, "with length", len(done_leaves)
			#print "total leaves in range are", total_leaves_in_range
			print "END CONDITION.. RETURNING"
			yield None ###END CONDITION, all nodes finished
			return
		
		#draw for going up/down
		draw = random.random()
		#draw = 0.2
		
		#TODO: verify that you always have to go up if node is done
		if (draw <= alpha and parent>0 and previous != -float('inf') and not node_too_big) or node_done:
			#go to parent
			going_up = True
			previous = v
			#detection_node = v
			v = parent
		else:
			#find a child
			child = choose_child(coreset_str, v, done_nodes)
			if child == v: #came down to leaf or a node whose all children are done
				loop_finished = True
			else:
				v = child
				previous = - float('inf')
			
		
		#Do detections on v when a loop is done
		if loop_finished:
			#print "FINISHED LOOP with the node", v
			loop_finished = False

			if not coreset_str.is_leaf(v):
				#this means all its leaves are done or out of range
				if v not in done_nodes: #don't think this conditional is necessary
					done_nodes.add(v)
			
			if v in done_nodes:
				raise Error('Should not even come here, but lets see')
				v = init_node
				previous = float('inf')
				continue
			else:
				t12 = coreset_t12[v-1]
				node_search_range = get_search_range(t12, q_range)
				regions = get_regions_from_db(node_search_range, class_label,scene_id, threshold, is_synthetic_retrieval)
				cur_regions.append(regions) 
				done_nodes.add(v)
				done_leaves.append(v)
				#print "yielded regions", regions
				yield regions
			#start another loop with initial v
			v = init_node
			previous = float('inf')


def get_regions_from_db(node_search_range, class_label,scene_id, threshold, is_synthetic_retrieval):
	#TODO: potential to improve with only one filter	
	if not is_synthetic_retrieval:
		regions = AppRegion.objects.filter(label__id = class_label.id).filter(scene__id=scene_id).filter(frame__range=node_search_range).filter(confidence__gte=threshold)
	else:
		regions = AppSyntheticRegion.objects.filter(class_id = class_label.id).filter(scene__id=scene_id).filter(frame__range=node_search_range).filter(confidence__gte=threshold)
	return regions


def get_child_nodes_list(parent_nodes_list):
	child_nodes_list = [[]] * len(parent_nodes_list)
	for i in range(len(parent_nodes_list)):
		node_num = i+1
		parent_node = parent_nodes_list[i]
		parent_node_index = parent_node - 1
		child_nodes_list[parent_node_index].append(node_num)
	return child_nodes_list



def choose_child(coreset_str, v, done_nodes):
	child_nodes_list = coreset_str.get_child_nodes_list()
	children_idx = child_nodes_list[v-1]
	if children_idx == None:
		children_idx = []
	keyframes = coreset_str.get_all_node_keyframes()
	weights = [1.] * len(children_idx)
	if len(keyframes) > 0 and len(weights) > 0:
		parent_keyframes = keyframes[v-1]
		for c in range(len(children_idx)):
			child_keyframes = keyframes[children_idx[c]-1]
			num_membership = len(get_intersection(child_keyframes, parent_keyframes))
			weights[c] = num_membership +1
		weights = [float(wt)/sum(weights) for wt in weights]

	#gather all time previous children
	children_not_done = [child_id for child_id in children_idx if child_id not in done_nodes]

	if len(children_not_done) == 0:
		return v
	else:

		nweights = [weights[i] for i in range(len(children_idx)) if children_idx[i] in children_not_done]
		nweights = [float(wt)/sum(nweights) for wt in nweights]
		p = random.random()

		cweights = list(running_sum(nweights))
		gt_p = len([wt for wt in cweights if p<wt]) #num cweights greter than(gt) p
		return children_not_done[len(cweights) - gt_p]
		#return children_not_done[gt_p-1]


def running_sum(array):
  	tot = 0
  	for item in array:
  		tot += item
  		yield tot


def find_children(nodes, parent_node):
	children_idx = []
	for i in range(len(nodes)):
		if nodes[i] == parent_node:
			children_idx.append(i+1)
	return children_idx


def get_intersection(list1, list2):
	return list(set(list1) & set(list2))


def get_last_containing_leaf(coreset_str, q_range):
	leaves = coreset_str.get_leaf_nodes()
	coreset_t12 = coreset_str.get_t12()
	if len(q_range) == 2:
		q_t1, q_t2 = q_range
	else:
		raise Error("Query range isn't of length 2");

	#binary search on leaves
	start_ind = 0
	end_ind = len(leaves)
	while True:
		mid_ind = (start_ind + end_ind)/2
		leaf = leaves[mid_ind]
		leaf_t1, leaf_t2 = coreset_t12[leaf-1]
		if leaf_t2 < q_t2:
			start_ind = mid_ind #go to right half
		else:
			if leaf_t1 < q_t2:
				#sanity check
				end_leaf_ind = get_leaf_indices_in_range(coreset_str, q_range)[1]
				assert end_leaf_ind == mid_ind
				return (leaf, mid_ind)
			else:
				end_ind = mid_ind #go to left half

			


def get_leaf_indices_in_range(coreset_str, q_range):
	coreset_t12 = coreset_str.get_t12()
	#node 1 is always a leaf, so its t12 indicates range(size) of a leaf
	leaf_size = coreset_t12[0][1] - coreset_t12[0][0] +1
	
	#last node is always the root node, so its span is the entire tree span
	tree_1, tree_2 = coreset_t12[-1]
	
	q1, q2 = q_range
	q1 = max(tree_1, q1)
	q2 = min(tree_2, q2)
	
	first_leaf_ind = (q1-1)/leaf_size
	last_leaf_ind = (q2-1)/leaf_size	

	return [first_leaf_ind, last_leaf_ind]


#return True if first range is a "super-range" of second range
def is_range_over_another(first_range,sec_range):
	return first_range[0] <= sec_range[0] and first_range[1] >= sec_range[1]


def is_node_done(node, child_nodes, done_nodes):
	node_done = False
	if child_nodes == None: #node is leaf
		node_done = node in done_nodes
	else: #not a leaf
		#if all the children are done, the node is done as well
		node_done = all(child in done_nodes for child in child_nodes)
	return node_done


def are_ranges_disjoint(range_a, range_b):
	a1, a2 = range_a
	b1, b2 = range_b
	return b1 > a2 or a1 > b2

def get_search_range(t12, q_range):
	search_range = [max(t12[0], q_range[0]), min(t12[1], q_range[1])]
	if search_range[0] >= search_range[1]:
		search_range = []
	return search_range


def coreset_uniform_retrieval(coreset_str, q_range, class_label, scene_id, threshold, is_synthetic_retrieval):
	#first make q_range proper, in case user queries more than the tree range
	#now make the q_range proper
	#last node is always the root node, so its span is the entire tree span
	coreset_t12 = coreset_str.get_t12()
	tree_1, tree_2 = coreset_t12[-1]
	
	q1, q2 = q_range
	q1 = max(tree_1, q1)
	q2 = min(tree_2, q2)	
	q_range = [q1, q2]
	
	coreset_leaves = coreset_str.get_leaf_nodes()
	
	leaf_start_ind, leaf_end_ind = get_leaf_indices_in_range(coreset_str, q_range)
	leaves_in_range = coreset_leaves[leaf_start_ind : leaf_end_ind+1]
	num_leaves_in_range = len(leaves_in_range)
	#print "total leaves in range are", num_leaves_in_range
	#print "all leaves in this range are", coreset_leaves[leaf_start_ind : leaf_end_ind+1]
	
	done_nodes = set([])
	cur_regions = []
	while True:
		if len(done_nodes) == len(leaves_in_range): #all leaves finished sampling
			#END CONDITION
			yield None
			return
		
		#sample uniformly a leaf from the leaves in range
		v = random.choice(leaves_in_range)
		if v in done_nodes:
			continue
		else:
			t12 = coreset_t12[v-1]
			node_search_range = get_search_range(t12, q_range)
			regions = get_regions_from_db(node_search_range, class_label,scene_id, threshold, is_synthetic_retrieval )
			cur_regions.append(regions) 
			done_nodes.add(v)
			#print "yielded regions", regions
			yield regions