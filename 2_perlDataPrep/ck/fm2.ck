// basic FM synthesis using sinosc


1000::ms => dur len;
450 => int carrier;
50 => int modulator;
100 => int vol;

if( me.args() )
{
    Std.atoi(me.arg(0))::ms => len;
    Std.atoi(me.arg(1)) => carrier;
    Std.atoi(me.arg(2)) => modulator;
    Std.atoi(me.arg(3)) => vol;
}


// modulator to carrier
SinOsc m => SinOsc c => dac;

// carrier frequency
carrier => c.freq;
// modulator frequency
modulator => m.freq;
// index of modulation
vol => m.gain;

// phase modulation is FM synthesis (sync is 2)
2 => c.sync;

0::ms => dur past;
20::ms => dur gap;

// time-loop
while( past < len )
{
    1::samp => now;
    1::samp +=> past;
    if (past > (len - gap))
    {
        0 => c.freq;
        0 => m.freq;
    }

}
