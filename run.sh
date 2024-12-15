#!/bin/bash

mkdir -p compiled images

# ############ Convert friendly and compile to openfst ############
for i in friendly/*.txt; do
	echo "Converting friendly: $i"
	python3 compact2fst.py  $i  > sources/$(basename $i ".txt").txt
done


# ############ convert words to openfst ############
for w in tests/*.str; do
	echo "Converting words: $w"
	./word2fst.py `cat $w` > tests/$(basename $w ".str").txt
done


# ############ Compile source transducers ############
for i in sources/*.txt tests/*.txt; do
	echo "Compiling: $i"
    fstcompile --isymbols=syms.txt --osymbols=syms.txt $i | fstarcsort > compiled/$(basename $i ".txt").fst
done

# ############ CORE OF THE PROJECT  ############

echo -e "\nCreating 'metaphoneLN' and 'invertMetaphoneLN'"
fstcompose compiled/step1.fst compiled/step2.fst > compiled/comp_steps_12.fst
fstcompose compiled/comp_steps_12.fst compiled/step3.fst > compiled/comp_steps_123.fst
fstcompose compiled/comp_steps_123.fst compiled/step4.fst > compiled/comp_steps_1234.fst
fstcompose compiled/comp_steps_1234.fst compiled/step5.fst > compiled/comp_steps_12345.fst
fstcompose compiled/comp_steps_12345.fst compiled/step6.fst > compiled/comp_steps_123456.fst
fstcompose compiled/comp_steps_123456.fst compiled/step7.fst > compiled/comp_steps_1234567.fst
fstcompose compiled/comp_steps_1234567.fst compiled/step8.fst > compiled/comp_steps_12345678.fst
fstcompose compiled/comp_steps_12345678.fst compiled/step9.fst > compiled/metaphoneLN.fst

rm compiled/comp_steps*.fst

fstinvert compiled/metaphoneLN.fst > compiled/invertMetaphoneLN.fst

# ############ generate PDFs  ############
echo "Starting to generate PDFs"
for i in compiled/*.fst; do
	if [ $(basename $i) != metaphoneLN.fst ] && [ $(basename $i) != invertMetaphoneLN.fst ] && 
		[ $(basename $i) != t-79730-std1-out-invert.fst ] && [ $(basename $i) != t-79730-std1-out.fst ]; then
		#echo "Creating image: images/$(basename $i '.fst').pdf"
		fstdraw --portrait --isymbols=syms.txt --osymbols=syms.txt $i | dot -Tpdf > images/$(basename $i '.fst').pdf
	fi
done

echo -e "\nStarting Step tests"
for i in 1 2 3 4 5 6 7 8 9; do
	for t in compiled/t-79730-step$i-*.fst; do
		echo -e "\ntesting step$i on $(basename $t)"
    	fstcompose $t compiled/step$i.fst | fstshortestpath | fstproject --project_type=output |
    	fstrmepsilon | fsttopsort | fstprint --acceptor --isymbols=./syms.txt
	done
done

echo -e "\nTesting metaphoneLN"
fstcompose compiled/t-79730-std1-in.fst compiled/metaphoneLN.fst > compiled/t-79730-std1-out.fst
fstshortestpath compiled/t-79730-std1-out.fst | fstproject --project_type=output | fstrmepsilon | fsttopsort | 
fstprint --acceptor --isymbols=./syms.txt

echo -e "\nTesting invertMetaphoneLN"
fstcompose compiled/invertMetaphoneLN.fst compiled/t-79730-std1-out.fst > compiled/t-79730-std1-out-invert.fst
fstshortestpath compiled/t-79730-std1-out-invert.fst | fstproject --project_type=output | fstrmepsilon | fsttopsort | 
fstprint --acceptor --isymbols=./syms.txt





