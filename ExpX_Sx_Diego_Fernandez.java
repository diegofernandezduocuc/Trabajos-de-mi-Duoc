import java.util.Scanner;
import java.util.HashSet;
import java.util.Set;
//puse el limite de edad en 160 por que me fije que podia ponerle 999 y 160 es mas realista.
public class ExpX_Sx_Diego_Fernandez {
    private static final double PRECIO_BASE = 10000;
    private static final double DESCUENTO_ESTUDIANTE = 0.10;
    private static final double DESCUENTO_ADULTO_MAYOR = 0.15;
    private static final int EDAD_MAXIMA = 160;
    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            double descuento, precioFinal;
            String seguir = "si";
            int opcionMenu, edad = 0;
            char fila = 0;
            int asiento = 0;
            Set asientosOcupados = new HashSet<>();
            System.out.println("///////////////////////Hola bienvenido a TeatroMoro cuarta edicion///////////////////////");
            System.out.println();
            System.out.println("El teatro cuenta con 3 filas (A, B, C) y 5 asientos en cada fila. Cuando ingrese la fila, poner letra en mayusculas.");
            System.out.println("El precio fijo de una entrada es de $" + PRECIO_BASE + " a los que se le aplicaran descuentos de estudiante de un 10% a menores de 18 y descuento 15% a adultos mayores de 60.");
            System.out.println();
            while (seguir.equals("si")) {
                
// aqui despliego el menuu.
                System.out.println("/-/-/-/-/-/-/-/-/-//Menu Principal Del TeatroMoro/-/-/-/-/-/-/-/-/-/");
                System.out.println("");
                for (int i = 1; i <= 2; i++) {
                    if (i == 1) {
                        System.out.println(i + ". Seleccionar fila y asiento/Comprar entrada");
                    } else {
                        System.out.println(i + ". Salir y cerrar Menu");
                    }
                }
                System.out.print("______________________: ");
                System.out.print("Seleccione el numero de la opcion que desea: ");
                opcionMenu = scanner.nextInt();
                
// aqui compro las entradas.
                switch (opcionMenu) {
                    case 1 -> {
     // aqui esta  la ubicacion del asiento
                        boolean asientoValido = false;
                        while (!asientoValido) {
                            System.out.print("Ingrese la fila (A, B, C): ");
                            fila = scanner.next().charAt(0);
                            System.out.print("Ingrese el numero de asiento (1-5): ");
                            asiento = scanner.nextInt();
                            String asientoSeleccionado = fila + String.valueOf(asiento);
                            if (asientosOcupados.contains(asientoSeleccionado)) {
                                System.out.println("El asiento ya está ocupado. Por favor, seleccione otro asiento.");
                            } else if ((fila == 'A' || fila == 'B' || fila == 'C') && (asiento >= 1 && asiento <= 5)) {
                                asientosOcupados.add(asientoSeleccionado);
                                asientoValido = true;
                            } else {
                                System.out.println("Ubicacion no valida. Intente de nuevo.");
                            }
                        }
 // Aqui le pido la edad a la persona.
                        boolean edadValida = false;
                        while (!edadValida) {
                            System.out.print("Por favor, para hacer efectivo su descuento ingrese su edad: ");
                            edad = scanner.nextInt();
                            if (edad < 0 || edad > EDAD_MAXIMA) {
                                System.out.println("La edad ingresada no es valida. Por favor, intente nuevamente.");
                            } else {
                                edadValida = true;
                            }
                        }
 // aqui estan los descuentos.
                        if (edad < 18) {
                            descuento = PRECIO_BASE * DESCUENTO_ESTUDIANTE;  // 10% de descuento para estudiantes
                        } else if (edad >= 60) {
                            descuento = PRECIO_BASE * DESCUENTO_ADULTO_MAYOR;  // 15% de descuento para personas de la tercera edad
                        } else {
                            descuento = 0;
                        }
  // Calculo del precio total a pagar
                        precioFinal = PRECIO_BASE - descuento;
    //  Visualización de la compra 
                        System.out.println("=============================");
                        System.out.println("Resumen de la compra:");
                        System.out.println("=============================");
                        System.out.println("Ubicacion del asiento: " + fila + "/" + asiento);
                        System.out.println("Precio base de la entrada: $" + PRECIO_BASE);
                        System.out.println("Descuento aplicado: $" + descuento);
                        System.out.println("Precio final a pagar: $" + precioFinal);
                    }
                    case 2 -> {
                        System.out.println("Saliendo del sistema...");
                        seguir = "no";
                    }
                    default -> System.out.println("Opcion no valida. Intente de nuevo.");
                }
// aqui le pregunto si desea realizar otra compra.
                if (seguir.equals("si")) {
                    System.out.print("____Desea volver al menu y  realizar otra compra?____ en minusculas* (si/no): ");
                    seguir = scanner.next();
                    if (seguir.equals("no")) {
                        System.out.println("GRACIAS POR COMPRAR EN TEATRO MORO NOS VEMOS!");
                        System.out.println("________________________________________________:");
                        System.out.println("Total de asientos comprados fila y numero:");
                        for (Object asientoComprado : asientosOcupados) {
                            System.out.println(asientoComprado);
                            System.out.println("________________________________________________:");
                        }
                    }
                }
            }
        }
    }
}
