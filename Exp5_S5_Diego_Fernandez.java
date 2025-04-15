import java.util.Scanner;
import java.util.HashSet;
import java.util.Set;

public class Exp5_S5_Diego_Fernandez  {
    public static void main(String[] args) {
        try (Scanner scanner = new Scanner(System.in)) {
            double precioBaseVIP = 25000;
            double precioBasePlatea = 16000;
            double precioBaseGeneral = 10000;
            double descuento, precioFinal;
            String seguir = "si";
            int opcionMenu, edad;
            String fila = "";
            int asiento = 0;
            Set<String> asientosOcupados = new HashSet<>();
            Set<String> entradasCompradas = new HashSet<>();
            System.out.println("/////////////////////////Hola bienvenido a TeatroMoro quinta edicion/////////////////////////");
            System.out.println();
            System.out.println("El teatro cuenta con 3 filas (VIP, Platea, General) y 5 asientos en cada fila.");
            System.out.println("El precio fijo de las entradas es de $25000 para VIP, $16000 para Platea, y $10000 para General, a los que se le aplicaran descuentos de estudiante de un 10% a menores de 18 y descuento 15% a adultos mayores de 60.");
            System.out.println();
            while (seguir.equals("si")) {
       
// Este es Despliegue del menu principal
                System.out.println("/-/-/-/-/-/-/-/-/-// Menu Principal Del TeatroMoro /-/-/-/-/-/-/-/-/-/");
                System.out.println("");
                for (int i = 1; i <= 6; i++) {  // Cambiado de 5 a 6 para incluir la nueva opción
                    if (i == 1) {
                        System.out.println(i + ". Comprar  una  entrada");
                    } else if (i == 2) {
                        System.out.println(i + ". Buscar todas las entradas compradas");
                    } else if (i == 3) {
                        System.out.println(i + ". Comprar multiples entradas con  (descuento base del 10%)");
                    } else if (i == 4) {
                        System.out.println(i + ". Mostrar tipos de descuentos disponibles");
                    } else if (i == 5) {
                        System.out.println(i + ". Eliminar una entrada especifica");
                    } else {
                        System.out.println(i + ". Salir y cerrar Menu");
                    }
                }
                System.out.print("______________________: ");
                System.out.print("Seleccione el numero de la Opcion que desea:  ");
                opcionMenu = scanner.nextInt();
                
        //  Compra de entradas
                switch (opcionMenu) {
                    case 1 -> {
        // Solicitar la ubicación del asiento
                        boolean asientoValido = false;
                        while (!asientoValido) {
                            System.out.print("Ingrese la fila (VIP, Platea, General. Escribir textualmente como se muestra.): ");
                            fila = scanner.next();
                            System.out.print("Ingrese el numero de asiento (1-5): ");
                            asiento = scanner.nextInt();
                            String asientoSeleccionado = fila + asiento;
                            if (asientosOcupados.contains(asientoSeleccionado)) {
                                System.out.println("El asiento ya esta ocupado. Por favor, seleccione otro asiento.");
                            } else if ((fila.equals("VIP") || fila.equals("Platea") || fila.equals("General")) && (asiento >= 1 && asiento <= 5)) {
                                asientosOcupados.add(asientoSeleccionado);
                                asientoValido = true;
                            } else {
                                System.out.println("Ubicacion no valida. Intente de  nuevo.");
                            }
                        }
                        
          // aqui se Determina el precio base según la fila
                        double precioBase = 0;
                        if (fila.equals("VIP")) {
                            precioBase = precioBaseVIP;
                        } else if (fila.equals("Platea")) {
                            precioBase = precioBasePlatea;
                        } else if (fila.equals("General")) {
                            precioBase = precioBaseGeneral;
                        }
                        
                        // Solicitar la edad del usuario
                        System.out.print("Por favor para hacer efectivo su descuento Ingrese su  edad: ");
                        edad = scanner.nextInt();
                        if (edad < 0) {
                            System.out.println("La  edad  ingresada no es valida. Por Favor Intente nuevamente.");
                        } else {
            // aplicar descuentos
                            if (edad < 18) {
                                descuento = precioBase * 0.10;  // 10% de descuento para estudiantes
                            } else if (edad >= 60) {
                                descuento = precioBase * 0.15;  // 15% de descuento para personas de la tercera edad
                            } else {
                                descuento = 0;
                            }
                            
          // el calculo del  precio final
                            precioFinal = precioBase - descuento;
                            
               // Visualizacion del resumen de la compra
                            System.out.println("=============================");
                            System.out.println("Resumen de la compra:");
                            System.out.println("=============================");
                            System.out.println("Ubicacion del asiento: " + fila + "/" + asiento);
                            System.out.println("Precio base de la entrada: $" + precioBase);
                            System.out.println("Descuento aplicado: $" + descuento);
                            System.out.println("Precio final a pagar: $" + precioFinal);
                            
            // Guardar la entrada comprada
                            entradasCompradas.add("Fila: " + fila + ", Asiento: " + asiento + ", Precio: $" + precioFinal);
                        }
                    }
                    case 2 -> {
       // Mostrar todas las entradas compradas
                        System.out.println("=============================");
                        System.out.println("Entradas compradas:");
                        System.out.println("=============================");
                        for (String entrada : entradasCompradas) {
                            System.out.println(entrada);
                        }
                    }
                    case 3 -> {
       // Comprar múltiples entradas con descuento base del 10%
                        System.out.print("Ingrese la cantidad de entradas que desea comprar (minimo 2): ");
                        int cantidadEntradas = scanner.nextInt();
                        if (cantidadEntradas < 2) {
                            System.out.println("No alcanza la cantidad minima de entradas requeridas para el descuento.");
                        } else {
                            for (int i = 0; i < cantidadEntradas; i++) {
                                System.out.println("Compra de entrada " + (i + 1) + ":");
                                boolean asientoValido = false;
                                while (!asientoValido) {
                                    System.out.print("Ingrese la fila (VIP, Platea, General): ");
                                    fila = scanner.next();
                                    System.out.print("Ingrese el numero de asiento (1-5): ");
                                    asiento = scanner.nextInt();
                                    String asientoSeleccionado = fila + String.valueOf(asiento);
                                    if (asientosOcupados.contains(asientoSeleccionado)) {
                                        System.out.println("El asiento ya esta ocupado. Por favor, seleccione otro asiento.");
                                    } else if ((fila.equals("VIP") || fila.equals("Platea") || fila.equals("General")) && (asiento >= 1 && asiento <= 5)) {
                                        asientosOcupados.add(asientoSeleccionado);
                                        asientoValido = true;
                                    } else {
                                        System.out.println("Ubicacion no valida. Intente de nuevo.");
                                    }
                                }
                                
         //  Determinar el precio base según la fila
                                double precioBase = 0;
                                if (fila.equals("VIP")) {
                                    precioBase = precioBaseVIP;
                                } else if (fila.equals("Platea")) {
                                    precioBase = precioBasePlatea;
                                } else if (fila.equals("General")) {
                                    precioBase = precioBaseGeneral;
                                }
                                
              //   Solicitar  la edad del usuario
                                System.out.print("Por favor para hacer efectivo  su descuento Ingrese su  edad: ");
                                edad = scanner.nextInt();
                                if (edad < 0) {
                                    System.out.println("La edad ingresada no es valida. Por Favor Intente nuevamente.");
                                } else {
                     // Aplicar lo descuentos
                                    descuento = precioBase * 0.10;  // Descuento  base del 10%
                                    if (edad < 18) {
                                        descuento += precioBase * 0.10;  // 10% de descuento adicional  para estudiantes
                                    } else if (edad >= 60) {
                                        descuento += precioBase * 0.15;  // 15% de descuento  adicional para personas de la tercera edad
                                    }
                                    
               //Calcular el precio final
                                    precioFinal = precioBase - descuento;
                                    
                  // bVisualizacion del resumen de la compra
                                    System.out.println("=============================");
                                    System.out.println("Resumen de la compra:");
                                    System.out.println("=============================");
                                    System.out.println("Ubicacion del asiento: " + fila + "/" + asiento);
                                    System.out.println("Precio base de la entrada: $" + precioBase);
                                    System.out.println("Descuento aplicado: $" + descuento);
                                    System.out.println("Precio final a pagar: $" + precioFinal);
                                    
       // Guardar la entrada comprada
                                    entradasCompradas.add("Fila: " + fila + ", Asiento: " + asiento + ", Precio: $" + precioFinal);
                                }
                            }
                        }
                    }
                    case 4 -> {
     // Mostrar tipos de descuentos disponibles
                        System.out.println("=============================");
                        System.out.println("aqui se muestra los tipos de descuentos disponibles:");
                        System.out.println("=============================");
                        System.out.println("1. Descuento del 10% para menores de 18 (edad).");
                        System.out.println("2. Descuento del 15% para mayores de 60 (edad)");
                        System.out.println("3. Descuento base del 10% para la compra de multiples entradas.");
                        System.out.println("=============================");
                    }
                    case 5 -> {
   // Eliminar una entrada específica
                        System.out.print("Ingrese la fila de la entrada a eliminar (VIP, Platea, General): ");
                        fila = scanner.next();
                        System.out.print("Ingrese el numero de asiento de la entrada a eliminar (1-5): ");
                        asiento = scanner.nextInt();
                        String asientoAEliminar = fila + asiento;
                        if (asientosOcupados.contains(asientoAEliminar)) {
                            
                            System.out.println("La entrada ha sido eliminada exitosamente.");
                        } else {
                            System.out.println("No se encontro una entrada con esa ubicacion.");
                        }
                    }
case 6 -> {
                        System.out.println("Saliendo del sistema...");
                        seguir = "no";
                    }
                    default -> System.out.println("Opcion no valida. Intente de nuevo.");
                }
                
  //  Preguntar si desea realizar otra compra
                if (seguir.equals("si")) {
                    System.out.print(" ____Desea Volver al menu____  en minusculas* (si/no) : ");
                    seguir = scanner.next();
                    if (seguir.equals("no")) {
                        System.out.println("GRACIAS POR COMPRAR EN TEATRO MORO quinta edicion NOS VEMOS!:");
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

