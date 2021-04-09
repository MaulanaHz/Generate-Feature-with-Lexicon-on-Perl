#!/usr/bin/perl
#
# Author : Taufik Fuadi Abidin & Alim Misbullah
# Mei, June 2011
# 
# Modified by Maulana Hizbullah, 1708107010055
# April 9, 2021
# 
# Department of Informatics
# College of Science, Syiah Kuala University
#
# http://www.informatika.unsyiah.ac.id/tfa
# tfa@informatika.unsyiah.ac.id

use strict;
use warnings;
use Lingua::EN::Bigram;
use FileHandle;

# build n-grams
my $ngrams = Lingua::EN::Bigram->new;

my $PATH = "/mnt/d/Courses/I8.TextdanWebMining/Pertemuan7/Tugas";
my $PATHDATA = "$PATH/data";
my $PATHKAMUS = "$PATH/kamus/";

open OUT,"> $ARGV[0]" or die "Cannot Open File!!!";

my $fh;
my @label = ("otomotif", "bola");
my @dictionary = ("0.4_otomotif_final.txt", "0.4_bola_final.txt");
#my @dictionary = ("kamus_positif.txt","kamus_negatif.txt");

# load and hash kamus positive from category otomotif
print "Load & hash kamus (+)\n"; 
my %hash_otomotif = ();
my @line_positive;
$fh = new FileHandle("cat $PATHKAMUS/$dictionary[0] 2>&1|");

while(my $kamus_item = $fh->getline){
	chomp($kamus_item);
	@line_positive = split(",", $kamus_item);
	$kamus_item = $line_positive[0];
	
	next if($kamus_item =~ /^#/ || $kamus_item =~ /^$/);  # empty line or line starts with #
	if(!defined $hash_otomotif{$kamus_item}){
		$hash_otomotif{$kamus_item} = 1;
	}
}
print "Selesai...\n\n";

# load and hash kamus negative from category sepakbola
print "Load & hash kamus (-)\n"; 
my %hash_sepakbola = ();
my @line_negative;
$fh = new FileHandle("cat $PATHKAMUS/$dictionary[1] 2>&1|");

while(my $kamus_item = $fh->getline){
	chomp($kamus_item);
	@line_negative = split(",", $kamus_item);
	$kamus_item = $line_negative[0];
	
	next if($kamus_item =~ /^#/ || $kamus_item =~ /^$/);  # empty line or line starts with #
	if(!defined $hash_sepakbola{$kamus_item}){
		$hash_sepakbola{$kamus_item} = 1;
	}
}
print "Selesai...\n\n";


# open file in each directory
for(my $category = 0; $category < @label; $category++){

	print "\nOpen directory: $PATHDATA/$label[$category]\n";
	opendir IMD, "$PATHDATA/$label[$category]" or die "Cannot Open Directory";
	my @thefiles= readdir(IMD);
	my $length = @thefiles;
	closedir(IMD);

	#examine each file in data directory
	for(my $number = 0; $number <= $length; $number++){
		if ($number > 6000){
			# 6001-8000 for data training
			# 8001-9000 for data testing	
		}
			# 0001-6000 for data feature
		elsif ($number >0 && $number <=6000){
			unless(($thefiles[$number] eq ".") || ($thefiles[$number] eq "..")){
				my $count_attribute = 0;
				my $no = 1;
				my $datafile = $thefiles[$number];      
				my $d_text = `cat $PATHDATA/$label[$category]/$label[$category]-$number.bersih.txt`;

				print "\n\nExamine file: $label[$category]-$number.bersih.txt\n";

				$d_text =~ s/\n+//gs;    
					
				print OUT "$label[$category],";      
				
				my $title = "";
				my $top = "";
				my $middle = "";
				my $bottom = "";

				# calculate title score for each dictionary
				for(my $dict = 0; $dict < @dictionary; $dict++){
					
					# determine which hash to use
					my $hashref;
					if ($dict == 0){ $hashref = \%hash_otomotif; } 
					elsif ($dict == 1) { $hashref = \%hash_sepakbola; }

					# get the texts between <title> ... </title>
					if($d_text =~ /<title>(.*?)<\/title>/){
						$title = $1;
						# calculate title score for each gram 
						for(my $gram = 1; $gram <= 3; $gram++){            								 
							
							my $gram_score = hitung_score_fitur(lc($title), $hashref, $gram);
							
							print "$no:$gram_score ";
							$gram_score = sprintf("%.4f", $gram_score*0.8);
							print OUT "$no:$gram_score "; 

							$count_attribute++;
							$no++;
						}         
					}
					
					# get content from top tag
					if($d_text =~ /<atas>(.*?)<\/atas>/){
						$top = $1;
						# calculate top score for each gram 
						for(my $gram = 1; $gram <= 3; $gram++){            								 
							
							my $gram_score = hitung_score_fitur(lc($top), $hashref, $gram);

							print "$no:$gram_score ";
							$gram_score = sprintf("%.4f", $gram_score*0.6);
							print OUT "$no:$gram_score "; 

							$count_attribute++;
							$no++;
						}
					}

					# get content from middle tag
					if($d_text =~ /<tengah>(.*?)<\/tengah>/){
						$middle = $1;
						# calculate middle score for each gram 
						for(my $gram = 1; $gram <= 3; $gram++){            								 
							
							my $gram_score = hitung_score_fitur(lc($middle), $hashref, $gram);						

							print "$no:$gram_score ";
							$gram_score = sprintf("%.4f", $gram_score*0.4);
							print OUT "$no:$gram_score "; 

							$count_attribute++;
							$no++;
						}
					}

					# get content from bottom tag
					if($d_text =~ /<bawah>(.*?)<\/bawah>/){
						$bottom = $1;
						# calculate bottom score for each gram 
						for(my $gram = 1; $gram <= 3; $gram++){            								 
							
							my $gram_score = hitung_score_fitur(lc($bottom), $hashref, $gram);
							
							print "$no:$gram_score ";
							$gram_score = sprintf("%.4f", $gram_score*0.3);
							print OUT "$no:$gram_score "; 

							$count_attribute++;
							$no++;
						}	
					}
				}
				print OUT "\n";
			}
		}
	}
}

close OUT;
#___DONE___

print("\n");


sub hitung_score_fitur{
	my($data, $hash, $n)=@_;  
	my $count=0;

	#print "r--$kata_kamus--($n)\n";
	my $str_data = clean_string($data);

	#print "c--$title--\n";
	# $ngrams->text($str_data . ".");
	$ngrams->text($str_data . ".");

	my $txt = $ngrams->text;  
	#print "title text : $txt\n";
	
	my @arrkata = $ngrams->ngram($n);
	my $gramlen = @arrkata;
	#print "t---: $gramlen\n";

	foreach my $kata(@arrkata){
		chomp($kata);
		#print "---kt hasil gram : [$gram]---\n";

		next if($kata =~ /^#/ || $kata =~ /^$/);

		if(defined $$hash{$kata}){
		#print "Di kamus : [$gram]\n";
		$count++;
		}
	}
	#print "count match: [$count]->len gram [$gramlen]\n";
	if(@arrkata == 0){
		return 0;
	}
	else {
		return ($count/$gramlen);
	}
}

sub clean_string {
	my $file = shift;
	$file =~ s/<.*?>//g;
	$file =~ s/\s\w+=.*?>/ /g;
	$file =~ s/>//g;
	$file =~ s/&.*?;//g;
	$file =~ s/[\:\]\|\[\?\!\@\#\$\%\*\&\,\/\\\(\)\;]+//g;
	$file =~ s/-/ /g;
	$file =~ s/\s+/ /g;
	$file = lc($file);

	return $file;
}

