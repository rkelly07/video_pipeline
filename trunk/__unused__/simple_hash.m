function res=simple_hash(mesg,prime_number)
mesg=uint8(mesg);
if (prime_number<1 || prime_number>intmax('uint32'))
    error('prime_number is invalid');
end
prime_number=uint32(prime_number);
if (mod(numel(mesg),2)==1)
    mesg(end+1)=uint8(1);
end
res=uint32(1);
mesg=typecast(mesg,'uint16');
for i= 1:numel(mesg)
    res=mod((res*uint32(mesg(i))-uint32(1)),prime_number)+1;
end

end