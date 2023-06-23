//Consigna:
// Trabajo práctico 1

// ---------------------

// Hacer un efecto de delay estereo con opciones como:

// -Tiempo de retardo del canal izquierdo

// -Tiempo de retardo del canal derecho

// -Un botón de Bypass

// -Volumen master al final de la cadena

// ---------------------

import("stdfaust.lib");

//Sliders:

tiempo_l = hslider("Delay L [style:knob]", 0, 0, 2, 0.01);
tiempo_r = hslider("Delay R [style:knob]", 0, 0, 2, 0.01);
gain_l = hslider("Feedback L [style:knob]", 0, 0, 1, 0.01);
gain_r = hslider("Feedback R [style:knob]", 0, 0, 1, 0.01);

//Sistema de Delay:
rebote_l = (@(ma.SR*tiempo_l):bypass) : *(gain_l);
rebote_r = (@(ma.SR*tiempo_r):bypass) : *(gain_r);

rebote_s = hgroup("Delay", rebote_l, rebote_r);

//Sistema de Feedback:
eco_l = +~rebote_l;
eco_r = +~rebote_r;

eco_s = hgroup("Feedback", eco_l , eco_r);

//Boton Bypass:

bypass = *(1-checkbox("Bypass"));

//Sistema de volumen:
mute = *(1-checkbox("Mute"));
monoamp_p = *(vslider("Volume[style:knob]", 1, 0, 5, 0.01)): mute;
stereoamp_p = hgroup("Master", monoamp_p, monoamp_p);


process = hgroup("Main", eco_s : stereoamp_p);
