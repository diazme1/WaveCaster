	
// Import

import("stdfaust.lib");

//MIDI
frecuencia = nentry("freq", 440, 20, 20000, 1);
velocity = nentry("gain", 1, 0, 1, 0.01);

// Note On - Note Off
gateDeNotas = button("gate");

//Envolvente
ataque = vslider("Attack[unit:ms]", 1, 0.1, 1000, 1)/1000;
decay = vslider("Decay[unit:ms]", 100, 0, 1000, 1)/1000;
sustain = vslider("Sustain[unit:ms]", 0.5, 0, 1, 0.01);
release = vslider("Release[unit:ms]", 50, 0, 1000, 1)/1000;

envolvente = hgroup("Envolvente", en.adsr(ataque, decay, sustain, release, gateDeNotas));

// Oscilador Onda Cuadrada, Senoidal y Diente de Sierra
osc_sq = os.square(frecuencia) * envolvente * velocity;
osc_sn = os.osc(frecuencia) * envolvente * velocity;
osc_sw = os.sawtooth(frecuencia) * envolvente * velocity;

//Selector de tipo de onda:
s = nentry("Selector[style:menu{\'Cuadrada\':0;\'Seno\':1;\'Sierra\':2}]",0,0,2,1) : int;
sig = (osc_sq,osc_sn, osc_sw ): select3(s)<: _, _;

//Sliders parámetros efecto Delay:
tiempo_l = hslider("Delay L [style:knob]", 0, 0, 2, 0.01);
tiempo_r = hslider("Delay R [style:knob]", 0, 0, 2, 0.01);
gain_l = hslider("Feedback L [style:knob]", 0, 0, 0.90, 0.01);
gain_r = hslider("Feedback R [style:knob]", 0, 0, 0.90, 0.01);

//Boton Bypass Delay:
bypass = *(1-checkbox("Bypass"));

//Sistema de Delay:
rebote_l = (@(ma.SR*tiempo_l):bypass) : *(gain_l);
rebote_r = (@(ma.SR*tiempo_r):bypass) : *(gain_r);

rebote_s = hgroup("Delay", rebote_l, rebote_r);

//Sistema de Feedback:
eco_l = +~rebote_l;
eco_r = +~rebote_r;

delay_s = hgroup("Delay", eco_l , eco_r);

//Sistema de volumen:
mute = *(1-checkbox("Mute"));
monoamp_l = *(vslider("Volume L[unit:dB][style:knob]", 1, 0, 5, 0.01)): mute <: vumeter_l;
monoamp_r = *(vslider("Volume R[unit:dB][style:knob]", 1, 0, 5, 0.01)): mute <: vumeter_r;
stereoamp_p = hgroup("Master", monoamp_l, monoamp_r);

// VU Meter
vumeter_l = attach(_,abs : ba.linear2db : vbargraph("VU L[unit:dB]",-60,0));
vumeter_r = attach(_,abs : ba.linear2db : vbargraph("VU R[unit:dB]",-60,0));

//OSC(sig) + Volumen(stereoamp_p)
master = hgroup("Sintetizador", sig : stereoamp_p);

//TGroup separando Delay y Sintetizador en la gráfica
tab = tgroup("Sintetizador", master : delay_s);

process = tab;