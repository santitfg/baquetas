use <hueco_baqueta.scad>
use <utils/utils.scad>

/* ============================================================
   VARIABLES GLOBALES
   Funcionan como $fn: cambialas una sola vez aca arriba y
   afectan a todos los modulos que no sobreescriban el parametro.
   ============================================================ */

// Baqueta / eje
_diametro        = 24;     // diametro interior del eje (mm)
_holgura_a       = 0.5;    // holgura radial extremo A
_holgura_b       = 0.5;    // holgura radial extremo B
_poly_n          = 16;     // resolucion de circulos
_ancho_baqueta   = 40;     // longitud del cilindro macizo (mm)

// Tornillo / tuerca (cambia las 3 lineas de abajo para usar otra rosca en todo el archivo)
_familia_tuerca  = "UNC";       // "UNC" | "UNF" | "metrica" | "whitworth"
_subtipo_tuerca  = "normal";    // "normal" | "delgada" | "autoblocante" | "brida"
_medida_tornillo = 0.1875;      // pulgadas para UNC/UNF/whitworth; mm para metrica

// Defaults de ensamble
_profundidad     = 20;     // grosor de material (profundidad_pieza en hueco_baqueta)
_distancia       = 40;     // separacion entre baquetas en arrays / juntas dobles
_cantidad        = 5;      // cantidad de elementos en arrays
_cantidad_junta_angular        = 2; 

_centrada        = false;
_pasante         = false;
_angulo           = 90;

_cantidad_tornillos=2;

/* ============================================================
   JUNTA DOBLE
   Conecta dos baquetas separadas por distancia.
   rot_a / rot_b: rotacion en Y de cada brazo (grados).
     rot_a=90, rot_b=0   -> perpendicular (default)
     rot_a=0,  rot_b=0   -> en linea
     rot_a=90, rot_b=120 -> con giro parcial
   ============================================================ */
module junta_doble(
    ancho_baqueta      = _ancho_baqueta,
    distancia          = _distancia,
    rot_a              = 90,
    rot_b              = 0,
    cantidad_tornillos = 2,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    holgura_b          = _holgura_b,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    difference() {
        hull() {
            rotate([0, rot_a, 90])
                baqueta_solida(
                    ancho_baqueta   = ancho_baqueta,
                    diametro        = diametro,
                    holgura         = holgura_a,
                    poly_n          = poly_n,
                    familia_tuerca  = familia_tuerca,
                    subtipo_tuerca  = subtipo_tuerca,
                    medida_tornillo = medida_tornillo
                );
            translate([distancia, 0, 0]) rotate([0, rot_b, 90])
                baqueta_solida(
                    ancho_baqueta   = ancho_baqueta,
                    diametro        = diametro,
                    holgura         = holgura_b,
                    poly_n          = poly_n,
                    familia_tuerca  = familia_tuerca,
                    subtipo_tuerca  = subtipo_tuerca,
                    medida_tornillo = medida_tornillo
                );
        }
        rotate([0, rot_a, 90])
            hueco_baqueta(
                cantidad_tornillos = cantidad_tornillos,
                profundidad_pieza  = profundidad_pieza,
                diametro           = diametro,
                holgura            = holgura_a,
                poly_n             = poly_n,
                familia_tuerca     = familia_tuerca,
                subtipo_tuerca     = subtipo_tuerca,
                medida_tornillo    = medida_tornillo
            );
        translate([distancia, 0, 0]) rotate([0, rot_b, 90])
            hueco_baqueta(
                cantidad_tornillos = cantidad_tornillos,
                profundidad_pieza  = profundidad_pieza,
                diametro           = diametro,
                holgura            = holgura_b,
                poly_n             = poly_n,
                familia_tuerca     = familia_tuerca,
                subtipo_tuerca     = subtipo_tuerca,
                medida_tornillo    = medida_tornillo
            );
    }
}


/* ============================================================
   JUNTA ARRAY
   N baquetas en linea con cuatro modos de rotacion:
     "gradual"       -> rotacion distribuida uniformemente en todos los elementos
     "extremos"      -> extremos a rot_principal, cuerpo fijo a rot_cuerpo
     "degrade"       -> extremos a rot_total, cuerpo graduado
     "solo_extremos" -> hull solo entre los dos extremos, sin perforaciones intermedias
                        (rot_a_extremo=0, rot_b_extremo=0, sep_extremos libre)
   ============================================================ */
module junta_array(
    cantidad           = _cantidad,
    distancia          = _distancia,
    ancho_baqueta      = _ancho_baqueta,
    rot_total          = 90,   // rango completo de rotacion (grados)
    rot_principal      = 90,   // rotacion de extremos en modo "extremos"
    rot_cuerpo         = 45,   // rotacion del cuerpo en modo "extremos"
    modo               = "gradual",  // "gradual" | "extremos" | "degrade" | "solo_extremos"
    rot_a_extremo      = 0,    // rotacion del primer extremo en modo "solo_extremos"
    rot_b_extremo      = 0,    // rotacion del segundo extremo en modo "solo_extremos"
    sep_extremos       = -1,   // separacion entre extremos en "solo_extremos" (-1 = distancia*cantidad)
    cantidad_tornillos = 2,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    holgura_b          = _holgura_b,
    interpolar_holgura = true,   // true: interpola entre holgura_a y holgura_b; false: todos usan holgura_b
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    rot_parcial = rot_total / (cantidad - 1);
    function holgura_en(i) =
        interpolar_holgura
            ? holgura_a + (holgura_b - holgura_a) * (i - 1) / (cantidad - 1)
            : holgura_b;

    function rot_en(i) =
        modo == "extremos"
            ? ((i == 1 || i == cantidad) ? rot_principal : rot_cuerpo)
        : modo == "degrade"
            ? ((i == 1 || i == cantidad) ? rot_total : rot_parcial * i)
        : // "gradual" y "solo_extremos" usan la misma distribucion gradual
            rot_parcial * i;

    if (modo == "solo_extremos") {
        // Hull entre dos extremos; rot y separacion propios, independientes del array.
        _sep = (sep_extremos < 0) ? distancia * cantidad : sep_extremos;
        difference() {
            hull() {
                rotate([0, rot_a_extremo, 90])
                    baqueta_solida(
                        ancho_baqueta   = ancho_baqueta,
                        diametro        = diametro,
                        holgura         = holgura_a,
                        poly_n          = poly_n,
                        familia_tuerca  = familia_tuerca,
                        subtipo_tuerca  = subtipo_tuerca,
                        medida_tornillo = medida_tornillo
                    );
                translate([_sep, 0, 0])
                    rotate([0, rot_b_extremo, 90])
                        baqueta_solida(
                            ancho_baqueta   = ancho_baqueta,
                            diametro        = diametro,
                            holgura         = holgura_b,
                            poly_n          = poly_n,
                            familia_tuerca  = familia_tuerca,
                            subtipo_tuerca  = subtipo_tuerca,
                            medida_tornillo = medida_tornillo
                        );
            }
            rotate([0, rot_a_extremo, 90])
                hueco_baqueta(
                    cantidad_tornillos = cantidad_tornillos,
                    profundidad_pieza  = profundidad_pieza,
                    diametro           = diametro,
                    holgura            = holgura_a,
                    poly_n             = poly_n,
                    familia_tuerca     = familia_tuerca,
                    subtipo_tuerca     = subtipo_tuerca,
                    medida_tornillo    = medida_tornillo
                );
            translate([_sep, 0, 0])
                rotate([0, rot_b_extremo, 90])
                    hueco_baqueta(
                        cantidad_tornillos = cantidad_tornillos,
                        profundidad_pieza  = profundidad_pieza,
                        diametro           = diametro,
                        holgura            = holgura_b,
                        poly_n             = poly_n,
                        familia_tuerca     = familia_tuerca,
                        subtipo_tuerca     = subtipo_tuerca,
                        medida_tornillo    = medida_tornillo
                    );
        }
    } else {
        difference() {
            hull()
                for (i = [1:cantidad])
                    translate([distancia * i, 0, 0])
                        rotate([0, rot_en(i), 90])
                            baqueta_solida(
                                ancho_baqueta   = ancho_baqueta,
                                diametro        = diametro,
                                holgura         = holgura_en(i),
                                poly_n          = poly_n,
                                familia_tuerca  = familia_tuerca,
                                subtipo_tuerca  = subtipo_tuerca,
                                medida_tornillo = medida_tornillo
                            );
            for (i = [1:cantidad])
                translate([distancia * i, 0, 0])
                    rotate([0, rot_en(i), 90])
                        hueco_baqueta(
                            cantidad_tornillos = cantidad_tornillos,
                            profundidad_pieza  = profundidad_pieza,
                            diametro           = diametro,
                            holgura            = holgura_en(i),
                            poly_n             = poly_n,
                            familia_tuerca     = familia_tuerca,
                            subtipo_tuerca     = subtipo_tuerca,
                            medida_tornillo    = medida_tornillo
                        );
        }
    }
}


/* ============================================================
   JUNTA T
   Dos baquetas perpendiculares; el segundo brazo gira 90 en Y.
   cantidad_main: tornillos en el brazo principal
   cantidad_rama: tornillos en el brazo transversal
   ============================================================ */
module junta_T(
    ancho_baqueta      = 60,
    desface_centro     = [0, 0, -5],
    cantidad_main      = 2,
    cantidad_rama      = 1,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    holgura_b          = _holgura_b,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    difference() {
        hull() {
            baqueta_solida(
                ancho_baqueta   = ancho_baqueta,
                diametro        = diametro,
                holgura         = holgura_a,
                poly_n          = poly_n,
                familia_tuerca  = familia_tuerca,
                subtipo_tuerca  = subtipo_tuerca,
                medida_tornillo = medida_tornillo
            );
            translate([ancho_baqueta, 0, 0]) rotate([0, 90, 0])
                baqueta_solida(
                    ancho_baqueta   = ancho_baqueta,
                    diametro        = diametro,
                    holgura         = holgura_b,
                    poly_n          = poly_n,
                    familia_tuerca  = familia_tuerca,
                    subtipo_tuerca  = subtipo_tuerca,
                    medida_tornillo = medida_tornillo
                );
        }
        hueco_baqueta(
            cantidad_tornillos    = cantidad_main,
            profundidad_pieza     = profundidad_pieza,
            largo_hueco_principal = ancho_baqueta,
            desface_centro        = desface_centro,
            diametro              = diametro,
            holgura               = holgura_a,
            poly_n                = poly_n,
            familia_tuerca        = familia_tuerca,
            subtipo_tuerca        = subtipo_tuerca,
            medida_tornillo       = medida_tornillo
        );
        translate([ancho_baqueta, 0, 0]) rotate([0, 90, 0])
            hueco_baqueta(
                cantidad_tornillos    = cantidad_rama,
                profundidad_pieza     = profundidad_pieza,
                largo_hueco_principal = ancho_baqueta,
                diametro              = diametro,
                holgura               = holgura_b,
                poly_n                = poly_n,
                familia_tuerca        = familia_tuerca,
                subtipo_tuerca        = subtipo_tuerca,
                medida_tornillo       = medida_tornillo
            );
    }
}




/* ============================================================
   JUNTA Angulo
   Dos baquetas perpendiculares; el segundo brazo gira 90 en Y.
   cantidad_main: tornillos en el brazo principal
   cantidad_rama: tornillos en el brazo transversal
   ============================================================ */
module junta_angulo(
    ancho_baqueta      = 60,
    desface_centro     = [0, 0, -5],
    cantidad_main      = 2,
    cantidad_tornillos      = _cantidad_tornillos,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    holgura_b          = _holgura_b,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo,
    centrada           = _centrada,
    pasante            = _pasante,
    cantidad           = _cantidad_junta_angular,
    angulo_total             = _angulo


) {
    difference() {
       
        //translate([ 0,ancho_baqueta, 0])rotate([0, 0,angulo ])
        //rotate_around(angulo, [0, 0,ancho_baqueta], [0,0, 0]){
        c= cantidad- 1;
        paso_ang= angulo_total / c;
        
        for(rot_y=[0:paso_ang:angulo_total])
         hull() {
        rotate([0, 0,rot_y ])
        translate([ 0,ancho_baqueta, 0])rotate([0, 0,90 ])
            baqueta_solida(
                ancho_baqueta   = ancho_baqueta,
                diametro        = diametro,
                holgura         = holgura_a,
                poly_n          = poly_n,
                familia_tuerca  = familia_tuerca,
                subtipo_tuerca  = subtipo_tuerca,
                medida_tornillo = medida_tornillo
            );
            //}
            translate([0, 0, 0]) rotate([0, 90, 0])
            
                baqueta_solida(
                    ancho_baqueta   = ancho_baqueta,
                    diametro        = diametro,
                    holgura         = holgura_b,
                    poly_n          = poly_n,
                    familia_tuerca  = familia_tuerca,
                    subtipo_tuerca  = subtipo_tuerca,
                    medida_tornillo = medida_tornillo
                );
        }
 for(rot_y=[0:paso_ang:angulo_total])
        rotate([0, 0,rot_y ])
        translate([ 0,ancho_baqueta, 0])rotate([0, 180,90])        hueco_baqueta(
            cantidad_tornillos    = cantidad_main,
            profundidad_pieza     = profundidad_pieza,
            largo_hueco_principal = ancho_baqueta,
            desface_centro        = desface_centro,
            diametro              = diametro,
            holgura               = holgura_a,
            poly_n                = poly_n,
            familia_tuerca        = familia_tuerca,
            subtipo_tuerca        = subtipo_tuerca,
            medida_tornillo       = medida_tornillo
        );
        translate([0, 0, 0]) rotate([0,90, 0])
            hueco_baqueta(
                profundidad_pieza     = profundidad_pieza,
                largo_hueco_principal = ancho_baqueta,
                diametro              = diametro,
                holgura               = holgura_b,
                poly_n                = poly_n,
                familia_tuerca        = familia_tuerca,
                subtipo_tuerca        = subtipo_tuerca,
                medida_tornillo       = medida_tornillo,
                cantidad_tornillos    = cantidad_tornillos,
                angulo_tornillo        = angulo_total/2,
                );
                //profundidad_avellano // escribir module hueco_baqueta(

   }
    
    //MEJORAR EL AVELLANADO ya que la profundidad 
    //    cantidad_tornillos    = cantidad_tornillos,
    //angulo_tornillo       = angulo_tornillo,
}


/* ============================================================
   JUNTA Costilla
   Dos baquetas perpendiculares; el segundo brazo gira 90 en Y.
   cantidad_main: tornillos en el brazo principal
   cantidad_rama: tornillos en el brazo transversal
   ============================================================ */
module junta_Costilla(
    ancho_baqueta      = 60,
    desface_centro     = [0, 0, -5],
    cantidad_main      = 2,
    cantidad_rama      = 1,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    holgura_b          = _holgura_b,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    difference() {
        hull() {
            baqueta_solida(
                ancho_baqueta   = ancho_baqueta,
                diametro        = diametro,
                holgura         = holgura_a,
                poly_n          = poly_n,
                familia_tuerca  = familia_tuerca,
                subtipo_tuerca  = subtipo_tuerca,
                medida_tornillo = medida_tornillo
            );
            translate([ancho_baqueta, 0, 0]) rotate([0, 90, 0])
                baqueta_solida(
                    ancho_baqueta   = ancho_baqueta,
                    diametro        = diametro,
                    holgura         = holgura_b,
                    poly_n          = poly_n,
                    familia_tuerca  = familia_tuerca,
                    subtipo_tuerca  = subtipo_tuerca,
                    medida_tornillo = medida_tornillo
                );
        }
        hueco_baqueta(
            cantidad_tornillos    = cantidad_main,
            profundidad_pieza     = profundidad_pieza,
            largo_hueco_principal = ancho_baqueta,
            desface_centro        = desface_centro,
            diametro              = diametro,
            holgura               = holgura_a,
            poly_n                = poly_n,
            familia_tuerca        = familia_tuerca,
            subtipo_tuerca        = subtipo_tuerca,
            medida_tornillo       = medida_tornillo
        );
        translate([ancho_baqueta, 0, 0]) rotate([0, 90, 0])
            hueco_baqueta(
                cantidad_tornillos    = cantidad_rama,
                profundidad_pieza     = profundidad_pieza,
                largo_hueco_principal = ancho_baqueta,
                diametro              = diametro,
                holgura               = holgura_b,
                poly_n                = poly_n,
                familia_tuerca        = familia_tuerca,
                subtipo_tuerca        = subtipo_tuerca,
                medida_tornillo       = medida_tornillo
            );
    }
}


/* ============================================================
   UNION LINEAL
   Dos baquetas colineales con sus huecos descentrados hacia
   la junta (desface_centro opuesto en cada extremo).
   ============================================================ */
module union_lineal(
    ancho_baqueta      = 60,
    desface_centro     = [0, 0, -5],
    cantidad_tornillos = 2,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    holgura_b          = _holgura_b,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    difference() {
        hull() {
            baqueta_solida(
                ancho_baqueta   = ancho_baqueta,
                diametro        = diametro,
                holgura         = holgura_a,
                poly_n          = poly_n,
                familia_tuerca  = familia_tuerca,
                subtipo_tuerca  = subtipo_tuerca,
                medida_tornillo = medida_tornillo
            );
            translate([ancho_baqueta, 0, 0])
                baqueta_solida(
                    ancho_baqueta   = ancho_baqueta,
                    diametro        = diametro,
                    holgura         = holgura_b,
                    poly_n          = poly_n,
                    familia_tuerca  = familia_tuerca,
                    subtipo_tuerca  = subtipo_tuerca,
                    medida_tornillo = medida_tornillo
                );
        }
        hueco_baqueta(
            cantidad_tornillos    = cantidad_tornillos,
            profundidad_pieza     = profundidad_pieza,
            largo_hueco_principal = ancho_baqueta,
            desface_centro        = desface_centro,
            diametro              = diametro,
            holgura               = holgura_a,
            poly_n                = poly_n,
            familia_tuerca        = familia_tuerca,
            subtipo_tuerca        = subtipo_tuerca,
            medida_tornillo       = medida_tornillo
        );
        translate([ancho_baqueta, 0, 0])
            hueco_baqueta(
                cantidad_tornillos    = cantidad_tornillos,
                profundidad_pieza     = profundidad_pieza,
                largo_hueco_principal = ancho_baqueta,
                desface_centro        = [0, 0, -ancho_baqueta],
                diametro              = diametro,
                holgura               = holgura_b,
                poly_n                = poly_n,
                familia_tuerca        = familia_tuerca,
                subtipo_tuerca        = subtipo_tuerca,
                medida_tornillo       = medida_tornillo
            );
    }
}


/* ============================================================
   TERMINAL / TAPON
   Un solo extremo de baqueta, cerrado.
   ============================================================ */
module terminal(
    ancho_baqueta      = 60,
    desface_centro     = [0, 0, -5],
    cantidad_tornillos = 2,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    difference() {
        baqueta_solida(
            ancho_baqueta   = ancho_baqueta,
            diametro        = diametro,
            holgura         = holgura_a,
            poly_n          = poly_n,
            familia_tuerca  = familia_tuerca,
            subtipo_tuerca  = subtipo_tuerca,
            medida_tornillo = medida_tornillo
        );
        hueco_baqueta(
            cantidad_tornillos    = cantidad_tornillos,
            profundidad_pieza     = profundidad_pieza,
            largo_hueco_principal = ancho_baqueta,
            desface_centro        = desface_centro,
            diametro              = diametro,
            holgura               = holgura_a,
            poly_n                = poly_n,
            familia_tuerca        = familia_tuerca,
            subtipo_tuerca        = subtipo_tuerca,
            medida_tornillo       = medida_tornillo
        );
    }
}


/* ============================================================
   TERMINAL CON EXTREMO GENÉRICO
   El children() define la forma del extremo/capuchón.

   alinear:
     "extremo"  -> origen del children() se ubica en la cara
                   exterior del cuerpo (x = ancho_baqueta/2).
                   Útil para esferas centradas en ese plano.
     "centrado" -> origen del children() coincide con el centro
                   del cuerpo (x = 0). Posicionamiento manual.

   cortar_cuerpo (default: false):
     false -> union simple: baqueta_solida + children().
              Solo se resta hueco_baqueta (comportamiento por defecto).
     true  -> adicionalmente recorta la parte del children() que
              quedaría dentro del cuerpo (x < extremo_x), dejando
              solo el capuchón que sobresale.
   ============================================================ */
module terminal_cosa(
    ancho_baqueta      = 60,
    desface_centro     = [0, 0, -5],
    alinear            = "extremo",   // "extremo" | "centrado"
    cortar_cuerpo      = true,
    cantidad_tornillos = 2,
    profundidad_pieza  = _profundidad,
    diametro           = _diametro,
    holgura_a          = _holgura_a,
    poly_n             = _poly_n,
    familia_tuerca     = _familia_tuerca,
    subtipo_tuerca     = _subtipo_tuerca,
    medida_tornillo    = _medida_tornillo
) {
    extremo_x = ancho_baqueta / 2;
    offset_x  = (alinear == "extremo") ? extremo_x : 0;

    difference() {
        union() {
            baqueta_solida(
                ancho_baqueta   = ancho_baqueta,
                diametro        = diametro,
                holgura         = holgura_a,
                poly_n          = poly_n,
                familia_tuerca  = familia_tuerca,
                subtipo_tuerca  = subtipo_tuerca,
                medida_tornillo = medida_tornillo
            );
            if (cortar_cuerpo) {
                // Solo la parte del children() que sobresale del extremo.
                difference() {
                    translate([offset_x, 0, 0]) children();
                    translate([extremo_x - 500, 0, 0]) cube(1000, center = true);
                }
            } else {
                // Union directa: el children() se superpone libremente con el cuerpo.
                translate([offset_x, 0, 0]) children();
            }
        }
        hueco_baqueta(
            cantidad_tornillos    = cantidad_tornillos,
            profundidad_pieza     = profundidad_pieza,
            largo_hueco_principal = ancho_baqueta,
            desface_centro        = desface_centro,
            diametro              = diametro,
            holgura               = holgura_a,
            poly_n                = poly_n,
            familia_tuerca        = familia_tuerca,
            subtipo_tuerca        = subtipo_tuerca,
            medida_tornillo       = medida_tornillo
        );
    }
}


/* ============================================================
   DEMO
   Una instancia de cada junta con los valores por defecto.
   ============================================================ */

// Doble perpendicular (rot_a=90, rot_b=0, default)
junta_doble();

// Doble en linea (ambos a 0)
translate([-100, -50, 0])
    junta_doble(rot_a = 0, rot_b = 0);

// Doble con giro parcial (120)
translate([-100, 50, 0])
    junta_doble(rot_a = 90, rot_b = 120);

// Array gradual (rotacion distribuida uniformemente)
translate([100, 0, 0])
    junta_array(modo = "gradual");

// Array extremos (extremos 90, cuerpo 45)
translate([100, -150, 0])
    junta_array(modo = "extremos");

// Array degrade (extremos a rot_total, cuerpo graduado)
translate([100, -250, 0])
    junta_array(modo = "degrade");

// Array solo extremos: hull entre el primero y el ultimo, sin perforaciones intermedias
translate([100, -350, 0])
    junta_array(modo = "solo_extremos");

// Junta T
translate([100, 100, 0])
    junta_T();

    
// Junta angulo
translate([-100, 360, 0])
    color([.75,0,.25])junta_angulo();
    
translate([100, 250, 0])
    color([1,0,0])junta_Costilla();

    
    
// Union lineal
translate([300, 100, 0])
    union_lineal();

// Terminal / tapon
translate([300, 200, 0])
    terminal();

// Terminal con extremo esférico (union directa, default)
translate([300, 300, 0])
    terminal_cosa()
        sphere(
            d  = grosor_baqueta(_diametro, _holgura_a, _familia_tuerca, _subtipo_tuerca, _medida_tornillo),
            $fn = _poly_n
        );

// Terminal con extremo cilíndrico (con recorte del lado del cuerpo activado)
translate([300, 400, 0])
    terminal_cosa(cortar_cuerpo = true)
        cylinder(r = 20, h = 22);
