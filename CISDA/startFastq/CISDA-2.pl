#!/usr/bin/env perl
use strict;
use warnings;





###################################################################################################################################################################################################
###################################################################################################################################################################################################
###################################################################################################################################################################################################

########## Help Infromation ##########
my $HELP_g = '
        Welcome to use CISDA (ChIp-Seq Data Analyzer), version 0.4.0, 2015-07-02.      
        CISDA is a Pipeline for Single-end and Paired-end ChIP-seq Data Analysis by Integrating Lots of Softwares.

        Step 2: Remove adaptors and PCR primers, trim and filter the reads by using Trimmomatic,  
                and quality statistics by using FastQC, NGS_QC_Toolkit and FASTX-toolkit.
                Required softwares in this step: Trimmomatic, FastQC, NGS_QC_Toolkit and FASTX-toolkit.
  
        Usage: 
               perl  CISDA-2.pl    [-v]    [-h]    [-i inputDir]    [-o outDir]  

        For instance: 
                     perl  CISDA-2.pl    -i 2-FASTQ          -o 3-Filtered           
                     perl  CISDA-2.pl    --input 2-FASTQ     --output 3-Filtered    
 
        
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------
        Optional arguments:

        -v, --version        Show version number of this program and exit.

        -h, --help           Show this help message and exit.


        Required arguments:

        -i inputDir,  --input inputDir        inputDir is the name of input folder that contains your FASTQ files,
                                              the suffix of the FASTQ files must be ".fastq".    (no default)

        -o outDir,  --output outDir           outDir is the name of output folder that contains running 
                                              results (fastq format) of this step.      (no default)
                                              The suffix of two paired-end sequencing files: "XXX_1.fastq"  and   "XXX_2.fastq"                            
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------


        Yong Peng @ He lab, yongpeng@email.com, Academy for Advanced Interdisciplinary Studies 
        and Center for Life Sciences (CLS), Peking University, China.     
  
';

my $version_g = "  CISDA (ChIP-Seq Data Analyzer), version 0.4.0, 2015-07-02.";


########## Keys and Values ##########
if ($#ARGV   == -1) { print  "\n$HELP_g\n\n";  exit 0; }       ## when there are no any command argumants.
if ($#ARGV%2 ==  0) { @ARGV = (@ARGV, "-h");           }       ## when the number of command argumants is odd. 
my %args = @ARGV;


########## Initialize  Variables ##########
my $input_g  = '2-FASTQ';      ## This is only an initialization  value or suggesting value, not default value.
my $output_g = '3-Filtered';   ## This is only an initialization  value or suggesting value, not default value.


########## Available Arguments ##########
my $available = "  -v  --version    -h  --help    -i  --input    -o    --output  ";
my $boole_g = 0;
while( my ($key, $value) = each %args ) {
    if($available !~ m/\s$key\s/) {print  "    Cann't recognize $key\n";  $boole_g = 1; }
}
if($boole_g == 1) {
    print "\n    The Command Line Arguments are wrong!\n";
    print '    Please see help message by using "perl  CISDA-2.pl  -h" ';
    print "\n\n";
    exit 0;
}


########## Get Arguments ##########
if ( ( exists $args{'-v' } )  or  ( exists $args{'--version' } )  )     { print  "\n$version_g\n\n";    exit 0; }
if ( ( exists $args{'-h' } )  or  ( exists $args{'--help'    } )  )     { print  "\n$HELP_g\n\n";       exit 0; }
if ( ( exists $args{'-i' } )  or  ( exists $args{'--input'   } )  )     { ($input_g  = $args{'-i' })  or  ($input_g  = $args{'--input' });  }else{print   "\n -i or --input  is required.\n\n";   print  "\n$HELP_g\n\n";       exit 0; }                                               
if ( ( exists $args{'-o' } )  or  ( exists $args{'--output'  } )  )     { ($output_g = $args{'-o' })  or  ($output_g = $args{'--output'});  }else{print   "\n -o or --output is required.\n\n";   print  "\n$HELP_g\n\n";       exit 0; }      



########### Conditions #############
$input_g  =~ m/^\S+$/   ||  die   "\n$HELP_g\n\n";
$output_g =~ m/^\S+$/   ||  die   "\n$HELP_g\n\n";


######### Print Command Arguments to Standard Output ###########
print  "\n\n
        ################ Your Arguments ###############################
                Input  folder:     $input_g
                Output folder:     $output_g
        ###############################################################  
\n\n";


###################################################################################################################################################################################################
###################################################################################################################################################################################################
###################################################################################################################################################################################################









print "\n\n        Running......";
if ( !(-e $output_g) )  { mkdir $output_g || die; }




print "\n\n        Detecting single-end and paired-end FASTQ files in input folder......";
opendir(my $DH_input, $input_g) || die;     
my @inputFiles = readdir($DH_input);
my @singleEnd = ();
my @pairedEnd = ();
open(seqFiles_FH, ">", "$output_g/singleEnd-pairedEnd-Files.txt")  or  die; 
for ( my $i=0; $i<=$#inputFiles; $i++ ) {     
    next unless $inputFiles[$i] =~ m/\.fastq$/;
    next unless $inputFiles[$i] !~ m/^[.]/;
    next unless $inputFiles[$i] !~ m/[~]$/;
    next unless $inputFiles[$i] !~ m/^unpaired/;
    if ($inputFiles[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])\.fastq$/) {   ## sinlge end sequencing files.
        $inputFiles[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])\.fastq$/  or  die;  
        $singleEnd[$#singleEnd+1] =  $inputFiles[$i];
        print  "\n\n        Single-end sequencing files:  $inputFiles[$i]\n";
        print seqFiles_FH  "Single-end sequencing files: $inputFiles[$i]\n";
    }else{     ## paired end sequencing files.
        $inputFiles[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])_([1-2])\.fastq$/  or  die; 
        if ($inputFiles[$i] =~ m/^(\w+_\w+_\w+_\w+_Rep[1-9])_1\.fastq$/) { ## The two files of one paired sequencing sample are always side by side. 
            my $temp = $1;
            my $end1 = $temp."_1.fastq";
            my $end2 = $temp."_2.fastq";
            (-e  "$input_g/$end1")  or die;  
            (-e  "$input_g/$end2")  or die;
            $pairedEnd[$#pairedEnd+1] =  $end1;
            $pairedEnd[$#pairedEnd+1] =  $end2;
            print  "\n\n        Paired-end sequencing files: $end1,  $end2\n";
            print seqFiles_FH  "Paired-end sequencing files: $end1,  $end2\n";
        }
    }
}
( ($#pairedEnd+1)%2 == 0 )  or die;
print   seqFiles_FH  "\n\n\n\n\n";
print   seqFiles_FH  "All single-end sequencing files:  @singleEnd\n\n\n\n\n\n";
print   seqFiles_FH  "All paired-end sequencing files:  @pairedEnd\n\n\n\n\n\n";
print    "\n\n";
print    "\n\n        All single-end sequencing files:  @singleEnd\n\n";
print    "\n\n        All paired-end sequencing files:  @pairedEnd\n\n";
my $numSingle = $#singleEnd + 1;
my $numPaired = $#pairedEnd + 1;
print seqFiles_FH   "\nThere are $numSingle single-end sequencing files.\n";
print seqFiles_FH   "\nThere are $numPaired paired-end sequencing files.\n";
print     "\n\n        There are $numSingle single-end sequencing files.\n";
print     "\n\n        There are $numPaired paired-end sequencing files.\n";








my $Trimmomatic = "/home/yp/ProgramFiles/1-NGStools/4-Filter/Trimmomatic/trimmomatic-0.33.jar";
print "\n\n        Filtering the reads by using Trimmomatic ......";
for (my $i=0; $i<=$#pairedEnd; $i=$i+2) {
        $pairedEnd[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])_1\.fastq$/   or  die;
        $pairedEnd[$i] =~ m/^(\S+)_1.fastq$/ or die;
        my $temp = $1;   
        my $end1 = $temp."_1.fastq";
        my $end2 = $temp."_2.fastq";
        ($end2 eq $pairedEnd[$i+1])  or  die;
        open(tempFH, ">>", "$output_g/paired-end-files.txt")  or  die;
        print  tempFH  "$end1,  $end2\n";
        system("java  -jar  $Trimmomatic  PE   -threads 12     $input_g/$end1  $input_g/$end2           $output_g/$end1  $output_g/unpaired-$end1    $output_g/$end2  $output_g/unpaired-$end2        ILLUMINACLIP:0-Other/TruSeqAdapter/All.fasta:2:30:10   LEADING:3   TRAILING:3   SLIDINGWINDOW:4:15   MINLEN:25    >>$output_g/$temp.runLog  2>&1");                       
}
for (my $i=0; $i<=$#singleEnd; $i++) {   
        $singleEnd[$i] =~ m/^(\w+_\w+_\w+_\w+_Rep[1-9])\.fastq$/   or  die; 
        my $temp = $1; 
        system("java  -jar  $Trimmomatic  SE   -threads 12     $input_g/$temp.fastq  $output_g/$temp.fastq    ILLUMINACLIP:0-Other/TruSeqAdapter/All.fasta:2:30:10   LEADING:3   TRAILING:3   SLIDINGWINDOW:4:15   MINLEN:25    >>$output_g/$temp.runLog  2>&1");                    
        ##system("rm   $input_g/$temp.fastq");  
}













print "\n\n        Detecting single-end and paired-end FASTQ files in output folder ......";
{#######
opendir(my $DH_output, $output_g) || die;     
my @outputFiles = readdir($DH_output);
my @singleEnd = ();
my @pairedEnd = ();
open(seqFiles_FH, ">", "$output_g/singleEnd-pairedEnd-Files-thisFolder.txt")  or  die; 
for ( my $i=0; $i<=$#outputFiles; $i++ ) {     
    next unless $outputFiles[$i] =~ m/\.fastq$/;
    next unless $outputFiles[$i] !~ m/^[.]/;
    next unless $outputFiles[$i] !~ m/[~]$/;
    next unless $outputFiles[$i] !~ m/^unpaired/;
    if ($outputFiles[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])\.fastq$/) {   ## sinlge end sequencing files.
        $outputFiles[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])\.fastq$/  or  die;  
        $singleEnd[$#singleEnd+1] =  $outputFiles[$i];
        print  "\n\n        Single-end sequencing files: $outputFiles[$i]\n";
        print seqFiles_FH  "Single-end sequencing files: $outputFiles[$i]\n";
    }else{     ## paired end sequencing files.
        $outputFiles[$i] =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])_([1-2])\.fastq$/  or  die; 
        if ($outputFiles[$i] =~ m/^(\w+_\w+_\w+_\w+_Rep[1-9])_1\.fastq$/) { ## The two files of one paired sequencing sample are always side by side. 
            my $temp = $1;
            my $end1 = $temp."_1.fastq";
            my $end2 = $temp."_2.fastq";
            (-e  "$output_g/$end1")  or die;  
            (-e  "$output_g/$end2")  or die;
            $pairedEnd[$#pairedEnd+1] =  $end1;
            $pairedEnd[$#pairedEnd+1] =  $end2;
            print  "\n\n        Paired-end sequencing files: $end1,  $end2\n";
            print seqFiles_FH  "Paired-end sequencing files: $end1,  $end2\n";
        }
    }
}
( ($#pairedEnd+1)%2 == 0 )  or die;
print   seqFiles_FH  "\n\n\n\n\n";
print   seqFiles_FH  "All single-end sequencing files:  @singleEnd\n\n\n\n\n\n";
print   seqFiles_FH  "All paired-end sequencing files:  @pairedEnd\n\n\n\n\n\n";
print    "\n\n";
print    "\n\n        All single-end sequencing files:  @singleEnd\n\n";
print    "\n\n        All paired-end sequencing files:  @pairedEnd\n\n";
my $numSingle = $#singleEnd + 1;
my $numPaired = $#pairedEnd + 1;
print seqFiles_FH   "\nThere are $numSingle single-end sequencing files.\n";
print seqFiles_FH   "\nThere are $numPaired paired-end sequencing files.\n";
print     "\n\n        There are $numSingle single-end sequencing files.\n";
print     "\n\n        There are $numPaired paired-end sequencing files.\n";








my $FastQCdir       = "$output_g/FastQC";
my $FastQCdir_10mer = "$output_g/FastQC_10mer";
my $NGSQCToolkit    = "$output_g/NGSQCToolkit";
my $NGSQCToolPaired = "$output_g/NGSQCToolkit_PairedEnd";
my $FASTXtoolkit    = "$output_g/FASTXtoolkit";
if ( !( -e $FastQCdir)       )   { mkdir $FastQCdir        ||  die; }
if ( !( -e $FastQCdir_10mer) )   { mkdir $FastQCdir_10mer  ||  die; }
if ( !( -e $NGSQCToolkit)    )   { mkdir $NGSQCToolkit     ||  die; }
if ( !( -e $NGSQCToolPaired) )   { mkdir $NGSQCToolPaired  ||  die; }
if ( !( -e $FASTXtoolkit)    )   { mkdir $FASTXtoolkit     ||  die; }
  



print "\n\n        Detecting the quality of single-end FASTQ files by using FastQC......";
for ( my $i=0; $i<=$#singleEnd; $i++ ) {     
    my $temp = $singleEnd[$i]; 
    $temp =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])\.fastq$/   or  die;
    $temp =~ s/\.fastq$//  ||  die;
    system( "fastqc    --outdir $FastQCdir   --threads 10    --kmers 7     $output_g/$temp.fastq       >> $FastQCdir/$temp.runLog   2>&1" );  
} 




print "\n\n        Detecting the quality of paired-end FASTQ files by using FastQC and NGS_QC_Toolkit......";
for ( my $j=0; $j<=$#pairedEnd; $j=$j+2 ) {     
    my $temp1 = $pairedEnd[$j]; 
    my $temp2 = $pairedEnd[$j+1]; 
    $temp1 =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])_1\.fastq$/   or  die;
    $temp2 =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])_2\.fastq$/   or  die;
    $temp1 =~ s/\.fastq$//  ||  die;
    $temp2 =~ s/\.fastq$//  ||  die;
    system( "fastqc    --outdir $FastQCdir   --threads 10    --kmers 7     $output_g/$temp1.fastq       >> $FastQCdir/$temp1.runLog   2>&1" );  
    system( "fastqc    --outdir $FastQCdir   --threads 10    --kmers 7     $output_g/$temp2.fastq       >> $FastQCdir/$temp2.runLog   2>&1" );  
    print  seqFiles_FH  "\n\nquality statistics: $temp1,  $temp2\n";
    my $temp = $temp1;
    $temp =~ s/_1$//  ||  die;
    if ( !(-e "$NGSQCToolPaired/$temp") )   { mkdir  "$NGSQCToolPaired/$temp"  ||  die; }
    system( "IlluQC.pl   -pe $output_g/$temp1.fastq   $output_g/$temp2.fastq   N  A     -processes 10   -onlyStat    -outputFolder $NGSQCToolPaired/$temp    >> $NGSQCToolPaired/$temp/$temp.runLog  2>&1" ); 
} 

    


print "\n\n        Detecting the quality of all FASTQ files by using FastQC, NGS_QC_Toolkit and FASTX-Toolkit......";
for ( my $i=0; $i<=$#outputFiles; $i++ ) {     
    next unless $outputFiles[$i] =~ m/\.fastq$/;
    next unless $outputFiles[$i] !~ m/^[.]/;
    next unless $outputFiles[$i] !~ m/[~]$/;
    next unless $outputFiles[$i] !~ m/^unpaired/;
    my $temp = $outputFiles[$i]; 
    $temp =~ m/^(\w+)_(\w+)_(\w+)_(\w+)_(Rep[1-9])(_?)([1-2]?)\.fastq$/   or  die;
    $temp =~ s/\.fastq$//  ||  die;
    system( "fastqc    --outdir $FastQCdir_10mer    --threads 10    --kmers 10    $output_g/$temp.fastq       >> $FastQCdir_10mer/$temp.runLog   2>&1" );  
    if ( !(-e "$NGSQCToolkit/$temp") )   { mkdir  "$NGSQCToolkit/$temp"  ||  die; }
    system( "IlluQC.pl  -se $output_g/$temp.fastq   N  A    -processes 10   -onlyStat    -outputFolder $NGSQCToolkit/$temp                >> $NGSQCToolkit/$temp/$temp.runLog   2>&1" );      
    system( "fastx_quality_stats                        -i $output_g/$temp.fastq                    -o $FASTXtoolkit/$temp.txt            >> $FASTXtoolkit/$temp.runLog   2>&1" ); 
    system( "fastq_quality_boxplot_graph.sh             -i $FASTXtoolkit/$temp.txt     -t $temp     -o $FASTXtoolkit/$temp.quality.png    >> $FASTXtoolkit/$temp.runLog   2>&1" ); 
    system( "fastx_nucleotide_distribution_graph.sh     -i $FASTXtoolkit/$temp.txt     -t $temp     -o $FASTXtoolkit/$temp.nucDis.png     >> $FASTXtoolkit/$temp.runLog   2>&1" ); 
}



}########






print "\n\n        Job Done! Cheers! \n\n";
























