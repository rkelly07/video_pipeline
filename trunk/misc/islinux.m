% Returns 1 if ISUNIX and not ISMAC
function result = islinux()
result = isunix && not(ismac);