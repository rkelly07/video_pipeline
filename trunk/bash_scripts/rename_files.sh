a=1
for i in *.jpg; do
  new=$(printf "file%04d.jpg" ${a})
  mv ${i} ${new}
  let a=a+1
done
