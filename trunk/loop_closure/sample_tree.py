import random
import pdb

#nodes start with 1
def sample_tree(nodes, initial_node, alpha, keyframes=[]):
	v = initial_node
	previous = float('inf')
	vpath = [v]

	node_idx = range(1, len(nodes)+1)

	while True:
		parent = nodes[v-1] #node_num starts with 1
		vpath.append(parent)

		#draw = random.random()

		draw = 0.4

		if draw <= alpha and parent>0 and previous != -float('inf'):
			#go to parent
			previous = v
			v = parent

		else:
			#go to a time-previous child
			pdb.set_trace()
			children_idx = find_children(nodes, v)
			weights = [1.] * len(children_idx)
			if len(keyframes) > 0 and len(weights) > 0:
				parent_keyframes = keyframes[v-1]
				for c in range(len(children_idx)):
					child_keyframes = keyframes[children_idx[c]]
					num_membership = len(get_intersection(child_keyframes, parent_keyframes))
					weights[c] = num_membership +1
				weights = [float(wt)/sum(weights) for wt in weights]

			#gather all time previous children
			time_previous_children = children_idx
			if previous > 0:
				time_previous_children = [child_id for child_id in children_idx if child_id < previous]

			if len(time_previous_children) == 0:
				res = v
				vpath.append(v)
				return (res, vpath)
			else:
				tpc_idx = get_intersection(children_idx, time_previous_children)
				pdb.set_trace()
				nweights = [weights[i] for i in tpc_idx]
				nweights = [float(wt)/sum(nweights) for wt in nweights]
				p = random.random()

				cweights = list(running_sum(nweights))
				idx = len([wt for wt in cweights if p<wt])
				previous = - float('inf')
				v = time_previous_children[idx]

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


def get_intersection(child_keyframes, parent_keyframes):
	return list(set(child_keyframes) & set(parent_keyframes))


def main():
	nodes= [3, 3, 7, 6, 6, 7, 15, 10, 10, 14, 13, 13, 14, 15, 0];
	init_node=14;
	(res, vpath)=sample_tree(nodes,init_node,0.2);


if __name__ == "__main__":
	main()