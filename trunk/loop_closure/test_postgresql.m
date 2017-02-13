javaaddpath('/usr/share/java/postgresql-jdbc3-9.1.jar')
javaaddpath('/usr/share/java/postgresql-jdbc4-9.1.jar')
conn = database('postgres','postgres','fdhdfjaol','org.postgresql.Driver','jdbc:postgresql://localhost:5432/postgres')
res = fetch(conn,'show tables from postgresql')
T = tables(conn);
fastinsert(conn,'fabmap_leads_table',{'idx','filepointer'},{1,'file1'})
