load goprotestannotation;
pos_pairs=label_pairs(userdata, 'positive', 200, 40);
neg_pairs=label_pairs(userdata, 'negative', 200, 40, 5, 3000);
