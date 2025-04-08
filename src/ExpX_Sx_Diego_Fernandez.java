import java.util.Scanner;
import java.util.HashSet;
import java.util.Set;

public class ExpX_Sx_Diego_Fernandez {
    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            double precioBase = 10000;
            double descuento, precioFinal;
            String seguir = "si";
            int opcionMenu, edad;
            char fila = 0;
            int asiento = 0;
            Set<String> asientosOcupados = new HashSet<>();
            System.out.println("///////////////////////Hola bienvenido a TeatroMoro cuarta edicion///////////////////////");
            System.out.println();
            System.out.println("El teatro cuenta con 3  filas (A, B, C) y 5 asientos en cada fila, cuando ingrese la fila poner Letra en Mayusculas.");
            System.out.println("El precio fijo de una entrada es de $" + precioBase + " a los que se le aplicaran descuentos de estudiante de un 10% a menores de   18   y descuento 15% a adultos mayores de   60.   ");
            System.out.println();
            while (seguir.equals("si")) {
                // Paso 1: Despliegue del menú principal
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
                System.out.print("Seleccione el numero de la Opcion que desea:  ");
                opcionMenu = scanner.nextInt();
                
                // Paso 2: Compra de entradas
                switch (opcionMenu) {
                    case 1 -> {
                        // Solicitar la ubicación del asiento
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
                                System.out.println("Ubicación no válida. Intente de nuevo.");
                            }
                        }
                        
                        // Solicitar la edad del usuario
                        System.out.print("Por favor para hacer efectivo su descuento Ingrese su edad: ");
                        edad = scanner.nextInt();
                        if (edad < 0) {
                            System.out.println("La edad ingresada no es válida. Por Favor Intente nuevamente.");
                        } else {
                            // Aplicar descuentos
                            if (edad < 18) {
                                descuento = precioBase * 0.10;  // 10% de descuento para estudiantes
                            } else if (edad >= 60) {
                                descuento = precioBase * 0.15;  // 15% de descuento para personas de la tercera edad
                            } else {
                                descuento = 0;
                            }
                            
                            // Calcular el precio final
                            precioFinal = precioBase - descuento;
                            
                            // Paso 3: Visualización del resumen de la compra
                            System.out.println("=============================");
                            System.out.println("Resumen de la compra:");
                            System.out.println("=============================");
                            System.out.println("Ubicacion del asiento: " + fila + "/"+ asiento);
                            System.out.println("Precio base de la entrada: $" + precioBase);
                            System.out.println("Descuento aplicado: $" + descuento);
                            System.out.println("Precio final a pagar: $" + precioFinal);
                        }
                    }
                    case 2 -> {
                        System.out.println("Saliendo del sistema...");
                        seguir = "no";
                    }
                    default -> System.out.println("Opcion no valida. Intente de nuevo.");
                }
                
                // Paso 4: Preguntar si desea realizar otra compra
                if (seguir.equals("si")) {
                    System.out.print(" ____Desea realizar otra compra?____  en minusculas* (si/no) : ");
                    seguir = scanner.next();
                    if (seguir.equals("no")) {
                        System.out.println("GRACIAS POR COMPRAR EN TEATRO MORO NOS VEMOS!:");
                        System.out.println("________________________________________________:");
                        System.out.println("Total de Asientos comprados fila y numero:");
                        for (String asientoComprado : asientosOcupados) {
                            System.out.println(asientoComprado);
                            System.out.println("________________________________________________:");
                        }
                    }
                }
            }
        }
    }
}
