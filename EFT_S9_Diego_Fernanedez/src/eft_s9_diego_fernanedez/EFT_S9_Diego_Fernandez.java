package eft_s9_diego_fernanedez;

import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class EFT_S9_Diego_Fernandez {
    // filass  A, B, C, D,  E
    private static final char[] FILAS = {'A','B','C','D','E'};
    private static final int ASIENTOS_POR_FILA = 10;
    private static final int CAPACIDAD = FILAS.length * ASIENTOS_POR_FILA;

    //  Estado de los asientos
    private boolean[][] asientosDisponibles = new boolean[FILAS.length][ASIENTOS_POR_FILA];

    // Datos 
    private List<Integer> idsVenta = new ArrayList<>();
    private List<String> etiquetasAsiento = new ArrayList<>();
    private List<Integer> clienteIds = new ArrayList<>();
    private List<String> clienteNombres = new ArrayList<>();
    private List<Double> preciosFinales = new ArrayList<>();
    private List<Boolean> esReserva = new ArrayList<>();
    private List<Double> descuentoEdadList = new ArrayList<>();
    private List<Double> descuentoGeneroList = new ArrayList<>();

    private double totalIngresos = 0;

    public static void main(String[] args) {
        System.out.println("[DEBUG] Los puntos de debug que puse son simulados");
        System.out.println("[DEBUG] Iniciando aplicacion Teatro Moro");
        new EFT_S9_Diego_Fernandez().ejecutar();
    }

    private void ejecutar() {
        try (Scanner sc = new Scanner(System.in)) {
            System.out.println("[DEBUG] Inicializando asientos");
            inicializarAsientos();
            
            int opcion;
            do {
                System.out.println("\n ///Menu///=====  Teatro Moro 2025 =====//////");
                System.out.println();
                System.out.println("1. Informacion de entradas y descuentos");
                System.out.println("2. Comprar o Reservar Entrada");
                System.out.println("3. Imprimir Boletas");
                System.out.println("4. Ver Reservas/Comprar Reservas");
                System.out.println("5. Mostrar ingresos totales");
                System.out.println("6. Cancelar Reserva");
                System.out.println("7. Salir");
                System.out.println();
                System.out.print("Ingresa opcion: ");
                opcion = entradaEnteroSegura(sc);
                System.out.println("[DEBUG] Opcion seleccionada: " + opcion);
                
                switch(opcion) {
                    case 1 -> mostrarPromociones();
                    case 2 -> gestionarEntrada(sc);
                    case 3 -> mostrarBoletas();
                    case 4 -> gestionarReservas(sc);
                    case 5 -> mostrarIngresosTotales();
                    case 6 -> gestionarCancelacion(sc);
                    case 7 -> System.out.println("Gracias por su visita al Teatro moro 2025 Trabajo final s9 :)");
                    default -> System.out.println("ERROR Opcion invalida (Solo opciones del menu 1-7).");
                }
            } while(opcion != 7);
        }
        System.out.println("[DEBUG] Aplicacion finalizada");
    }

    private void inicializarAsientos() {
        for(int i = 0; i < FILAS.length; i++) {
            Arrays.fill(asientosDisponibles[i], true);
        }
        System.out.println("[DEBUG] Asientos inicializados:  todos estan disponibles");
    }

    private void mostrarPromociones() {
        System.out.println("--- Promociones Disponibles ---");
        System.out.println();
        System.out.println("Ninos (<=12 edad):        10% descuento");
        System.out.println("Mujeres:                  20% descuento");
        System.out.println("Estudiantes (13-25 edad): 15% descuento");
        System.out.println("Tercera Edad (>=60 edad): 25% descuento");
        System.out.println("Precios Base: (A)VIP=$23200, (B)Palco=$16400, (C)Platea Baja=$9600, (D)Platea Alta=$9000, (E)Galeria=$8000");
    }

    private void mostrarMapaAsientos() {
        System.out.println("\n Mapa de Asientos (disponible=[ ], ocupado=[X]):");
        System.out.printf("%4s", "");
        for(int n = 1; n <= ASIENTOS_POR_FILA; n++) System.out.printf("%4d", n);
        System.out.println();
        for(int i = 0; i < FILAS.length; i++) {
            System.out.printf("%-4s", FILAS[i] + ":");
            for(int j = 0; j < ASIENTOS_POR_FILA; j++) {
                System.out.print(asientosDisponibles[i][j] ? " [ ]" : " [X]");
            }
            System.out.println();
        }
    }

    private void gestionarEntrada(Scanner sc) {
        System.out.println("[DEBUG] Iniciando gestionarEntrada");
        if(idsVenta.size() >= CAPACIDAD) {
            System.out.println("No quedan asientos disponibles.");
            return;
        }
        int modo;
        do {
            System.out.print("Desea 1=Comprar o 2=Reservar? ");
            modo = entradaEnteroSegura(sc);
        } while(modo != 1 && modo != 2);
        boolean reserva = (modo == 2);

        System.out.println();
        System.out.println("///Tipos///(A=VIP)     (B=Palco)     (C=Platea Baja)    (D=Platea Alta)    (E=Galeria)");
        System.out.println();
        System.out.println("Precios Base: VIP=$23200, Palco=$16400, Platea Baja=$9600, Platea Alta=$9000, Galeria=$8000");
        mostrarMapaAsientos();
        sc.nextLine();

        //   Validacion de los  nombres
        String nombre;
        do {
            System.out.println();
            System.out.print("Ingrese NOMBRE del cliente (solo letras): ");
            nombre = sc.nextLine().trim();
            if (!nombre.matches("[A-Za-z\\s]+")) {
                System.out.println("Nombre invalido. Solo se permiten letras.");
            }
        } while (!nombre.matches("[A-Za-z\\s]+"));
        System.out.println("[DEBUG] Nombre valido: " + nombre);
        System.out.println();
          int idCliente;
        do {
            System.out.print("Ingrese ID de cliente (solo numeros): ");
            idCliente = entradaEnteroSegura(sc);
            sc.nextLine(); // limpiar buffer
            if (clienteIds.contains(idCliente)) {
                System.out.println("Error:  ID ya registrado. Solo nombre puede ser igual.");
            }
        } while (clienteIds.contains(idCliente));
        System.out.println("[DEBUG] ID De Cliente unico: " + idCliente);
       

        int filaIdx, asientoIdx;
        String cod;
        while(true) {
            System.out.println();
            System.out.print("Seleccione asiento (A1-E10): ");
            cod = sc.nextLine().toUpperCase();
            System.out.println("[DEBUG] Asiento: " + cod);
            if(!cod.matches("[A-E]([1-9]|10)")) {
                System.out.println("Formato invalido."); continue;
            }
            filaIdx = Arrays.binarySearch(FILAS, cod.charAt(0));
            asientoIdx = Integer.parseInt(cod.substring(1)) - 1;
            if(filaIdx < 0 || !asientosDisponibles[filaIdx][asientoIdx]) {
                System.out.println("Asiento no disponible."); continue;
            }
            asientosDisponibles[filaIdx][asientoIdx] = false;
            break;
        }

        double base = determinarPrecioBase(cod.charAt(0));
        int idVenta = ThreadLocalRandom.current().nextInt(10000, 100000);
        double descuentoEdad = 0, descuentoGenero = 0;

        idsVenta.add(idVenta);
        etiquetasAsiento.add(cod);
        clienteIds.add(idCliente);
        clienteNombres.add(nombre);
        esReserva.add(reserva);

        if(!reserva) {
            System.out.println();
            System.out.print("Es mujer? 1=Si,  2=No: ");
            boolean esMujer = entradaEnteroSegura(sc) == 1;
            int edad;
            System.out.println("[DEBUG] Es mujer?: " + esMujer);
            do {
                
                System.out.println();
                System.out.print("Ingrese edad del cliente (1-120): ");
    edad = entradaEnteroSegura(sc);
    if (edad < 1) {
        System.out.println("Edad demasiado baja. Debe ser al menos de edad 1.");
    } else if (edad > 120) {
        System.out.println("Edad demasiado alta. Maximo permitido es 120.");
    }
            } while(edad < 1 || edad > 120);

            if(edad <= 12) descuentoEdad = 0.10;
            else if(edad >= 60) descuentoEdad = 0.25;
            else if(edad <= 25) descuentoEdad = 0.15;
            if(esMujer) descuentoGenero = 0.20;
            System.out.println("[DEBUG] Edad: " + edad);

            double descuentoTotal = descuentoEdad + descuentoGenero;
            double precioFinal = base * (1 - descuentoTotal);
            preciosFinales.add(precioFinal);
            descuentoEdadList.add(descuentoEdad);
            descuentoGeneroList.add(descuentoGenero);
            totalIngresos += precioFinal;

            System.out.println();
            System.out.println("--- BOLETA ---");
            System.out.printf("ID Venta: %d    ID Cliente: %d%n", idVenta, idCliente);
            System.out.printf("Cliente: %s%n", nombre);
            System.out.printf("Asiento: %s    Tipo: %s    Base: $%.0f%n", cod, tipoAsiento(cod.charAt(0)), base);
            System.out.printf("Desc. Edad: %.0f%%    Desc. Genero: %.0f%% %n", descuentoEdad*100, descuentoGenero*100);
            System.out.printf("Total a Pagar: $%.0f%n", precioFinal);
            System.out.println("Gracias por VISITAR EL Teatro Moro 2025");
        } else {
            preciosFinales.add(0.0);
            descuentoEdadList.add(0.0);
            descuentoGeneroList.add(0.0);
            System.out.println();
            System.out.println("--- RESERVA REGISTRADA ---");
            System.out.printf("ID Reserva: %d    ID Cliente: %d%n", idVenta, idCliente);
            System.out.printf("Cliente: %s%n", nombre);
            System.out.printf("Asiento: %s    Tipo: %s    Base: $%.0f%n", cod, tipoAsiento(cod.charAt(0)), base);
            System.out.println("Nota: La reserva no incluye descuentos ni pago hasta ser confirmada.");
        }
    }

    // metodos que use (mostrarBoletas,   gestionarReservas,  gestionarCancelacion,:
    private void mostrarBoletas() {
        System.out.println("[DEBUG] Iniciando mostrarBoletas");
        System.out.println();
        System.out.println("--- Boletas de Compras ---");
        boolean hayCompras = false;
        for(int i = 0; i < idsVenta.size(); i++) {
            if(esReserva.get(i)) continue;
            hayCompras = true;
            System.out.println("------------------------------");
            System.out.printf("ID Venta: %d    ID Cliente: %d%n", idsVenta.get(i), clienteIds.get(i));
            System.out.printf("Cliente: %s%n", clienteNombres.get(i));
            char fila = etiquetasAsiento.get(i).charAt(0);
            System.out.printf("Asiento: %s    Tipo: %s    Base: $%.0f%n", etiquetasAsiento.get(i), tipoAsiento(fila), determinarPrecioBase(fila));
            System.out.printf("Desc. Edad: %.0f%%    Desc. Genero: %.0f%% %n", descuentoEdadList.get(i)*100, descuentoGeneroList.get(i)*100);
            System.out.printf("Total a Pagar: $%.0f%n", preciosFinales.get(i));
            System.out.println("Gracias por VISITAR EL Teatro Moro 2025");
        }
        if(!hayCompras) {
            System.out.println("No hay compras registradas.  si reservaste pero aun no compras no se vera reflejada su boleta.");
        }
    }

    private void gestionarReservas(Scanner sc) {
        System.out.println("[DEBUG] Iniciando gestionarReservas");
        System.out.println();
        System.out.println("--- Reservas Actuales ---");
        boolean hayReservas = false;
        for(int i = 0; i < idsVenta.size(); i++) {
            if(!esReserva.get(i)) continue;
            hayReservas = true;
            System.out.println("------------------------------");
            System.out.printf("ID Reserva: %d    ID Cliente: %d%n", idsVenta.get(i), clienteIds.get(i));
            System.out.printf("Cliente: %s%n", clienteNombres.get(i));
            char fila = etiquetasAsiento.get(i).charAt(0);
            System.out.printf("Asiento: %s    Tipo: %s    Base: $%.0f%n", etiquetasAsiento.get(i), tipoAsiento(fila), determinarPrecioBase(fila));
            System.out.println("------------------------------");
        }
        if(!hayReservas) {
            System.out.println("No hay reservas a ctivas registradas. Debes Resevar en la opcion menu 2");
            return;
        }
        System.out.println();
        System.out.print("Desea confirmar una reserva? 1=Si, 2=No: ");
        int opcion = entradaEnteroSegura(sc);
        System.out.println("[DEBUG] Confirmar Reserva: " + opcion);
        if(opcion != 1) return;
        System.out.print("Ingrese ID de reserva a confirmar: ");
        int id = entradaEnteroSegura(sc);
        System.out.println("[DEBUG] ID de la reserva " + id);
        for(int i = 0; i < idsVenta.size(); i++) {
            if(idsVenta.get(i) == id && esReserva.get(i)) {
                esReserva.set(i, false);
                System.out.println();
                System.out.print("Es mujer? 1=Si, 2=No: ");
                boolean esMujer = entradaEnteroSegura(sc) == 1;
                System.out.println("[DEBUG] Es mujer?: " + esMujer);
                int edad;
                do {
                  System.out.println();
                  System.out.print("Ingrese edad del cliente (1-120): ");
    edad = entradaEnteroSegura(sc);
    System.out.println("[DEBUG] Edad: " + edad);
    if (edad < 1) {
        System.out.println("Edad demasiado baja. Debe ser al menos 1");
    } else if (edad > 120) {
        System.out.println("Edad muy alta. Maximo permitido es de 120.");
    }  
                } while(edad < 1 || edad > 120);
                double base = determinarPrecioBase(etiquetasAsiento.get(i).charAt(0));
                double descuentoEdad = 0, descuentoGenero = 0;
                if(edad <= 12) descuentoEdad = 0.10;
                else if(edad >= 60) descuentoEdad = 0.25;
                else if(edad <= 25) descuentoEdad = 0.15;
                if(esMujer) descuentoGenero = 0.20;
                double precioFinal = base * (1 - (descuentoEdad + descuentoGenero));
                preciosFinales.set(i, precioFinal);
                descuentoEdadList.set(i, descuentoEdad);
                descuentoGeneroList.set(i, descuentoGenero);
                totalIngresos += precioFinal;
                System.out.println();
                System.out.println("--- BOLETA CONFIRMADA ---");
                System.out.printf("ID Venta: %d    ID Cliente: %d%n", idsVenta.get(i), clienteIds.get(i));
                System.out.printf("Cliente: %s%n", clienteNombres.get(i));
                System.out.printf("Asiento: %s    Tipo: %s    Base: $%.0f%n", etiquetasAsiento.get(i), tipoAsiento(etiquetasAsiento.get(i).charAt(0)), base);
                System.out.printf("Desc. Edad: %.0f%%    Desc. Genero: %.0f%% %n", descuentoEdad*100, descuentoGenero*100);
                System.out.printf("Total a Pagar: $%.0f%n", precioFinal);
                System.out.println("---------------------------");
                return;
            }
        }
        System.out.println("Reserva no encontrada o ya confirmada.");
    }

  private void gestionarCancelacion(Scanner sc) {
    System.out.println("[DEBUG] Iniciando gestionarCancelacion\n");

    // 1. Mostrar reservas activas
    System.out.println("--- Reservas Activas ---");
    boolean hayReservas = false;
    for (int i = 0; i < idsVenta.size(); i++) {
        if (esReserva.get(i)) {
            hayReservas = true;
            System.out.printf("ID Reserva: %d    Cliente: %s    Asiento: %s%n",
                              idsVenta.get(i),
                              clienteNombres.get(i),
                              etiquetasAsiento.get(i));
        }
    }
    if (!hayReservas) {
        System.out.println("No hay reservas activas registradas. Debes Reservar en la  opcion numero 2 del menu");
        return;
    }
        
        
        System.out.print("Ingrese ID de reserva a cancelar: ");
        int id = entradaEnteroSegura(sc);
        for(int i = 0; i < idsVenta.size(); i++) {
            if(idsVenta.get(i) == id && esReserva.get(i)) {
                int fila = Arrays.binarySearch(FILAS, etiquetasAsiento.get(i).charAt(0));
                int asiento = Integer.parseInt(etiquetasAsiento.get(i).substring(1)) - 1;
                asientosDisponibles[fila][asiento] = true;
                idsVenta.remove(i);
                etiquetasAsiento.remove(i);
                clienteIds.remove(i);
                clienteNombres.remove(i);
                preciosFinales.remove(i);
                esReserva.remove(i);
                descuentoEdadList.remove(i);
                descuentoGeneroList.remove(i);
                System.out.println("Reserva cancelada exitosamente.");
                return;
            }
        }
        System.out.println("Reserva no encontrada o ya confirmada.");
    }

    private void mostrarIngresosTotales() {
        System.out.println("[DEBUG] Iniciando mostrarIngresosTotales");
        System.out.printf("\n Ingresos Totales: $%.0f%n", totalIngresos);
    }

    private int entradaEnteroSegura(Scanner sc) {
        while(!sc.hasNextInt()) { sc.next(); System.out.print("ERROR Numero invalido (No letras, solo numeros disponibles): "); }
        return sc.nextInt();
    }

    private double determinarPrecioBase(char fila) {
        return switch(fila) {
            case 'A' -> 23200;
            case 'B' -> 16400;
            case 'C' -> 9600;
            case 'D' -> 9000;
            case 'E' -> 8000;
            default -> 0;
        };
    }

    private String tipoAsiento(char fila) {
        return switch(fila) {
            case 'A' -> "VIP";
            case 'B' -> "Palco";
            case 'C' -> "Platea Baja";
            case 'D' -> "Platea Alta";
            case 'E' -> "Galeria";
            default -> "Desconocido";
        };
    }
}

//