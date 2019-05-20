use strict;
use warnings;
use Statistics::Basic qw(:all nofill);
use GIS::Distance;
use Math::Trig;
use intensityProcessor;

####################
##### settings #####
####################

my %f = (   dataIn => $ARGV[0],
            sndIn => $ARGV[1],
            csvOut => $ARGV[2],
            xmlOut => $ARGV[3],
            sndDir => $ARGV[4]
        );

my %s = (
            legLenMil => $ARGV[5] * 60000,
            key => 'sens', 
            cvRange => 90, # how big a range are we taking the comparative mean
            svRange => 8, # how much are we smoothing the value
            sigChange => 3.2, #how big a change do we think is significant?
            distPerPoint => 20, # in metres
            sndFileType => "mp3", # file output type
        );

##################
##### gogogo #####
##################

my $rah = &processCSV($f{dataIn});
my $size = @{$rah};
my $start = &markSpikes($rah, \%s);
my $ip = intensityProcessor->new($rah, $start, $s{distPerPoint}, $s{legLenMil});
my $rah_o = $ip->process();
my $outsize = @{$rah_o};
open my $f_Csv, '>', $f{csvOut} or die "outfile didn't work?!\n";
open my $f_Xml, '>', $f{xmlOut} or die "$! xmloutfile didn't work?!\n";
print $f_Csv 'id,millisStart,millisEnd,timeStart,timeEnd,lat,lon,val,intensity,old_intensity,leg' . "\n";
system "mkdir $f{sndDir}";
print $f_Xml "<legs>\n<leg>\n";
my $prevleg = 0;
my @sndprocess;
my $o;
for (my $i=0; $i<$outsize; $i++){
    $o = $rah_o->[$i];
    print $f_Csv "$i,$o->{millisSt},$o->{millisTo},$o->{timeSt},$o->{timeTo},$o->{lat},$o->{lon},0,$o->{intens_avg},$o->{intens_ttl}, $o->{leg}\n";
    my $ss = $o->{millisSt}/1000;
    my $t = ($o->{millisTo} - $o->{millisSt})/1000;
    my $cmd = "ffmpeg -ss $ss -t $t -i $f{sndIn} $f{sndDir}/$i.$s{sndFileType}\n";
    print "Adding $cmd to sndprocess\n";
    push @sndprocess, $cmd;
    if ($o->{leg} > $prevleg){
        &outputXMLRecord($f_Xml, $o, $i);
        foreach my $poi (@{$ip->{_poi}->[$o->{leg}]}){
            &outputXMLInterest($poi, $f_Xml);
        }
        print $f_Xml "</leg>\n<leg>\n";
        $prevleg++;
    }
    &outputXMLRecord($f_Xml, $o, $i);
}
foreach my $poi (@{$ip->{_poi}->[$o->{leg}]}){
    &outputXMLInterest($poi, $f_Xml);
}
print $f_Xml "</leg>\n</legs>\n";
close $f_Csv;
close $f_Xml;
&splitSoundFile(\@sndprocess);


## ## ## ## ## ## ## ##
#######################
##### subroutines #####
#######################

##### file processing #####

sub processCSV{
    my $file = shift;
    open DATA, '<', $file or die "file didn't work?!\n";
    my @data = <DATA>;
    my $datasize = @data;
    chomp $data[0];
    my @header = split(",", $data[0]);
    my $headersize = @header;
    my $ra_data;
    for (my $i=1; $i<$datasize; $i++){ 
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

##### peak finding #####

sub markSpikes{
    my ($rah, $rh_s) = @_;
    my $start = 1;
    my $size = @{$rah};
    for (my $i=0; $i<$size-1; $i++){
        my $rh_m = &getBoundedMeans($rah, $i, $rh_s);
        $rah->[$i]->{spike} = 0;
        if ($rah->[$i]->{time} eq "waiting on GPS"){$start++};
        if ($rh_m->{sv} > ($rh_m->{cv} + $s{sigChange})){$rah->[$i]->{spike} = 1};
    #    my $l = $rah->[$i];
    #    print "$l->{lat},$l->{lon}, $l->{spike}\n";
    }
    return $start;
}

sub getBoundedMeans{
    my ($rah, $i, $s) = @_;
    my $size = @{$rah};
    my %bnd = ( 
                sv => &getBounds($i, $s{svRange}, $size), 
                cv => &getBounds($i, $s{cvRange}, $size)
              );
    my %arr = ( 
                sv => &getArrayFromHashKey($rah, $s->{key}, $bnd{sv}->{stt}, $bnd{sv}->{end}), 
                cv => &getArrayFromHashKey($rah, $s->{key}, $bnd{cv}->{stt}, $bnd{cv}->{end})
              );
    my %m = ( 
                sv => mean($arr{sv}),
                cv => mean($arr{cv})
            );
    return \%m;
}

sub getBounds{
    my ($i, $range, $size) = @_;   
#    print "received $i $range $size\n";
    my $rtn;
    if ($i < ($range/2)){
        $rtn->{stt} = 0;
        $rtn->{end} = $range;
    }elsif ($i+($range/2) >= $size){
        $rtn->{stt} = $size - $range - 1;
        $rtn->{end} = $size - 1        
    }else{
        $rtn->{stt} = $i - int($range/2);
        $rtn->{end} = $i + int($range/2);
    }
#    print "Looking at $rtn->{stt} to $rtn->{end}.\n";
    return $rtn;
}

sub getArrayFromHashKey{
    my ($rah, $key, $stt, $end) = @_;
    my @a;
    for (my $i=$stt; $i<$end; $i++){
        push @a, $rah->[$i]->{$key};
    }
    return \@a;
}

##### output functions #####

sub outputXMLRecord{
    my ($f_Xml, $o, $i) = @_;
    print $f_Xml "\n\t<record>\n\t\t<id>$i</id>\n\t\t<millisStart>$o->{millisSt}</millisStart>";
    print $f_Xml "\n\t\t<millisEnd>$o->{millisTo}</millisEnd>\n\t\t<timeStart>$o->{timeSt}</timeStart>";
    print $f_Xml "\n\t\t<timeEnd>$o->{timeTo}</timeEnd>\n\t\t<lat>$o->{lat}</lat>";
    print $f_Xml "\n\t\t<lon>$o->{lon}</lon>\n\t\t<val>0</val>";
    print $f_Xml "\n\t\t<intensity>$o->{intens_avg}</intensity>\n\t\t<old_intensity>$o->{intens_ttl}</old_intensity>\n\t</record>\n";
}

sub outputXMLInterest{
    my ($p, $xml) = @_;
    print "printing point of interest\n";
    print $xml "\t<interest_point>\n";
    my $endDiv = ($p->{millisInterest} - $p->{millisSt}) / ($p->{millisEnd} - $p->{millisSt});                                                                                              
    my $startDiv = 1 - $endDiv;
    my $lat = ($p->{latInterest} * $startDiv) + ($p->{latEnd} * $endDiv);
    my $lon = ($p->{lonInterest} * $startDiv) + ($p->{lonEnd} * $endDiv);
    print $xml "\t\t<lat>$lat</lat>\n";
    print $xml "\t\t<lon>$lon</lon>\n";
    print $xml "\t</interest_point>\n";
}


sub splitSoundFile{
    my $ra = shift;
    foreach my $sp(@{$ra}){
        system $sp;
    }
}



##### generic functions #####

sub printHash{
    my $rh = shift;
    foreach my $key (keys %{$rh}) {
        my $value = $rh->{$key};
        print "$key : $value,";
    }
    print "\n";
}

