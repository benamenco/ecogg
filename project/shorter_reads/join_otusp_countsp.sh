sed s/$/$"\t"OTUs/ otusp.dat > tmp1
sed s/$/$"\t"Counts/ countsp.dat > tmp2
cat tmp1 tmp2 > otusp_countsp.dat
rm tmp1 tmp2
