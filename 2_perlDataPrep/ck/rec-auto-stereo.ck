// chuck this with other shreds to record to file
// example> chuck foo.ck bar.ck rec (see also rec2.ck)

100::ms => dur len;
"x.wav" => string filename;

if( me.args() )
{
        Std.atoi(me.arg(0))::ms => len;
        me.arg(1) => filename;
}


// pull samples from the dac
// WvOut2 -> stereo operation
dac.right => Gain g => WvOut2 w => blackhole;

// set the prefix, which will prepended to the filename
// do this if you want the file to appear automatically
// in another directory.  if this isn't set, the file
// should appear in the directory you run chuck from
// with only the date and time.
"chuck-session" => w.autoPrefix;

// this is the output file name
filename => w.wavFilename;


// print it out
<<<"writing to file: ", w.filename()>>>;

// any gain you want for the output
.5 => g.gain;

// temporary workaround to automatically close file on remove-shred
null @=> w;
0::samp => dur past;

// infinite time loop...
// ctrl-c will stop it, or modify to desired duration
while( past < len ){
	1::samp => now;
	1::samp +=> past;
}
