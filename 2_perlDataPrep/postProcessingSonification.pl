use strict;
use warnings;

my $dataFileIn = $ARGV[0];
my $structureFileIn = $ARGV[1];
my $dirOut = $ARGV[2];
my $freqMin = 100;
my $freqMax = 1000;

my $rah_data = &processCSV($dataFileIn);
my $rah_structure = &processCSV($structureFileIn);
my $range = &findMinMaxValue($rah_data, "sens");
&printHash($rah_structure->[0]);

system "mkdir $dirOut";
system "mkdir $dirOut/raw";
system "mkdir $dirOut/raw/compiled";

my $k = 0;
my $size = @{$rah_data};
my $soxline = "";
my %snd;
#my @sox;
my $c=0;
my $f=0;
for (my $i=0; $i+1<$size; $i++){
    my $rd = $rah_data->[$i];
#    &printHash($rd);
    my $rs = $rah_structure->[$k];
#    &printHash($rs);
    if ($rd->{millis} > $rs->{millisStart}){
        my $freqFract = (1 + $rd->{sens} - $range->{min}) / $range->{max};
        my $freqOut = ($freqFract * ($freqMax - $freqMin)) + $freqMin;
        my $dur = $rah_data->[$i+1]->{millis} - $rd->{millis};
        my $file = "$rs->{id}.mp3";
#        print "emit $freqOut to $file for $dur milliseconds\n";
        my $fileOut; 
        my $s = "$freqOut-$dur";
        if ($snd{$s}){
            $fileOut = $snd{$s};
        }else{
            $fileOut = "$dirOut/raw/$rs->{id}-$f.wav";
            system "chuck ck/fm2:$dur:$freqOut:50:50 ck/rec-auto-stereo:$dur:$fileOut";
            $snd{"$freqOut-$dur"} = $fileOut;
        }
        $soxline .= "$fileOut ";
        $f++;
#        push @sox, $fileOut;
        if ($c > 1000){
            print "compiling at $f\n";
            &compileFile($soxline, $rs->{id});
            $soxline = "";
            $c=0;
            $f=0;
        }
        $c++;
    }
    if ($rd->{millis} >= $rs->{millisEnd} || $i+2 == $size){
        $k++;
        print "compiling at $f\n";
        &compileFile($soxline, $rs->{id});
        $soxline = "";
        $f=0;
        $c=0;
    }
}


sub compileFile{
    my ($soxline, $id) = @_;
    print "compiling $id\n";
    my $destFile = "$dirOut/$id.wav";
    my $compfile = "$dirOut/raw/compiled/$id.wav";
    if (-e $destFile){
        system "sox $destFile $soxline $compfile";            
        system "cp $compfile $destFile";
    }else{
        system "sox $soxline $destFile";
    }
}

sub findMinMaxValue{
    my ($rah, $key) = @_;
    my $size = @{$rah};
    my $rtn->{min} = 1024;
    $rtn->{max} = 0;
    for(my $i=0; $i<$size; $i++){
        my $val = $rah->[$i]->{$key};
        if ($val > $rtn->{max}){
            $rtn->{max} = $val;
        }
        if($val < $rtn->{min}){
            $rtn->{min} = $val;
        }
    }
    return $rtn;
}


sub processCSV{
    my $file = shift;         
    open DATA, '<', $file or die "file didn't work?!\n";                                                                                           
    my @data = <DATA>;        
    my $datasize = @data;
    chomp $data[0];           
    my @header = split(",", $data[0]);
    my $headersize = @header;
    my $ra_data;
    for (my $i=0; $i<$datasize; $i++){ 
        chomp $data[$i];
#        if ($csv->parse($data[$i])){     
           # print $data[$i] . "\n";       
            my @value = split(",", $data[$i]);
            my $rh_line;
            for (my $k=0; $k<$headersize; $k++){
               # print "$k - " . $header[$k] . ": " . $value[$k] . "\n"; 
                $rh_line->{$header[$k]} = $value[$k];                                                                                              
            }
            push @{$ra_data}, $rh_line;
 #       }else{print 'error in processing';}                                                                                                       
    }
    close (DATA);
    return $ra_data;
}

sub printHash{
    my $rh = shift;
    foreach my $key (keys %{$rh}) {
        my $value = $rh->{$key};       
        print "$key : $value,";        
    }
    print "\n";
}


