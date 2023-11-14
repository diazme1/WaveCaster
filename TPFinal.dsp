/* VST pensado para el procesamiento de audio para podcasting o radio con efectos útiles. Algunos de estos tendrán presets, al mismo tiempo que parámetros modificables. 

Funcionalidades:
  -Procesamiento de al menos 2 entradas de audio con redireccionamiento a L+R por igual para voces. Control de volumen de cada canal por separado. 
  -Entrada de tercer canal. (pendiente)
  -Salida estéreo, con mute de master y control de volumen l y r. 
  -Ecualización con presets para recitado de voces.
  -Compresor (sidechain?)
  -Gate
  -Boton de fade-out (pendiente)
  -Disparador de banco de samples (pendiente)
*/

//Control de volumen canales de entrada:

import("stdfaust.lib");

mute = *(1-checkbox("Mute"));
canal_1(in1) = in1*0.10*(vslider("Input 1", 1, 0, 4, 0.0001))
                <:_,_,_: 
                eq
                <:_,_: 
                gate :> _ :  
                comp : 
                mute;
canal_2(in2) = in2*0.10*(vslider("Input 2", 1, 0, 4, 0.0001))
                <:_,_,_: 
                eq  
                <:_,_: 
                gate :> _ :   
                comp : 
                mute;
canal_stereo_1(in1) = vgroup("Canal 1",canal_1(in1), canal_1(in1));
canal_stereo_2(in2) = vgroup("Canal 2", canal_2(in2), canal_2(in2));


//Ecualización:

filtro_reson_h = fi.resonbp(400, 1, 1) , fi.resonbp(1000, 1.5, 1) , fi.resonbp(3000, 1, 1) :>_;
filtro_reson_m = fi.resonbp(450, 1, 1) , fi.resonbp(1500, 1.5, 1) , fi.resonbp(3500, 1, 1) :>_;

eq_hombre = fi.highpass(2, 100) <:_,_,_: filtro_reson_h : fi.lowpass(1, 16800);
eq_mujer = fi.highpass(2, 100) <:_,_,_: filtro_reson_m : fi.lowpass(1, 18000);

s = vslider("EQ [style:radio{'Plano':0;'Hombre':1;'Mujer':2}]", 0, 0, 2, 1);
eq = vgroup("Ecualizador", ((_, eq_hombre, eq_mujer): select3(s)));

//Compresión:

compresorSimple(lad, rat, thr, att, rel, preGain, postGain, entrada) =
                    entrada * ba.db2linear(preGain) @ max(0, floor(0.5 + ma.SR * lad))
                    * compGain(rat, thr, att, rel, entrada * ba.db2linear(preGain))
                    * ba.db2linear(postGain)
    with {
        compGain(rat, thr, att, rel) =
                an.amp_follower_ar(att, rel) :
                ba.linear2db : outminusindb(rat, thr) :
                kneesmooth(att) : ba.db2linear;
        kneesmooth(att) = si.smooth(ba.tau2pole(att/2.0));
        outminusindb(rat, thr, level) = max(level-thr,0.0)
                                        * (1.0/max(ma.EPSILON, float(rat))-1.0);
    };

ampl = hslider("[0]Pre gain (dB)", 0, -18, 18, 0.1);
makeup =  hslider("[3]Post gain (dB)", 0, -18, 18, 0.1);
thresh = hslider("[1]Threshold (dB)", 0, -80, 0, 1);
ratio = hslider("[2]Ratio X:1 [scale:exp]", 3, 1, 5, 0.5);

comp = vgroup("Compresor", (compresorSimple(5/1000, ratio, thresh, 5/1000, 100/1000, ampl, makeup)));

//Gate:

gate = dm.gate_demo;


masterIns(in1, in2) = hgroup("Inputs", canal_stereo_1(in1), canal_stereo_2(in2));

//Fade-out:

gt = 1-checkbox("Fade-out");
fade_out = *(en.adsr(1, 1, 1, 4, gt));

//Máster de L+R con vumetro:

vumeter_l =  attach(_,abs : ba.linear2db : vbargraph("VU L[unit:dB]",-60,0));
vumeter_r =  attach(_,abs : ba.linear2db : vbargraph("VU R[unit:dB]",-60,0));

monoamp_l(l) = l *(vslider("Volume L", 1, 0, 4, 0.0001):si.smoo): fade_out : mute <: vumeter_l;
monoamp_r(r) = r *(vslider("Volume R", 1, 0, 4, 0.0001):si.smoo): fade_out : mute <: vumeter_r;

masterOuts(l,r) = hgroup("Master", monoamp_l(l), monoamp_r(r));

//TGroup Main:

main(in1, in2) = tgroup("Podcasting", masterIns(in1,in2):>_,_: masterOuts);


process(in1, in2) = main(in1, in2);   