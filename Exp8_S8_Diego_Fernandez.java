package exp8_s8_diego_fernandez;

import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class Exp8_S8_Diego_Fernandez {
    // Sólo filas A, B, C 
    private static final char[] FILAS = {'A','B','C'};
    private static final int ASIENTOS_POR_FILA = 10;
    private static final int CAPACIDAD = FILAS.length * ASIENTOS_POR_FILA;

    //  Estado de los asientos
    private boolean[][] asientosDisponibles = new boolean[FILAS.length][ASIENTOS_POR_FILA];

    // Datos de transacciones en ArrayLists
    private List<Integer> idsVenta = new ArrayList<>();
    private List<String> etiquetasAsiento = new ArrayList<>();
    private List<Integer> clienteIds = new ArrayList<>();
    private List<String> clienteNombres = new ArrayList<>();
    private List<Double> preciosFinales = new ArrayList<>();
    private List<Boolean> esReserva = new ArrayList<>();

    private double totalIngresos = 0;

    // Promociones
    private static final List<Promocion> promociones = new ArrayList<>();

    public static void main(String[] args) {
        promociones.add(new Promocion("Estudiante", 0.10));
        promociones.add(new Promocion("Tercera Edad", 0.15));
        new Exp8_S8_Diego_Fernandez().ejecutar();
    }

    private void ejecutar() {
        Scanner sc = new Scanner(System.in);
        inicializarAsientos();

        int opcion;
        do {
            System.out.println("\n//////===== Teatro Moro =====//////");
            System.out.println("1. Informacion de entradas y descuentos");
            System.out.println("2. Comprar o Reservar Entrada");
            System.out.println("3. Ver Resumen de Ventas");
            System.out.println("4. Ver Reservas/Comprar Reservas");
            System.out.println("5. Mostrar ingresos totales");
            System.out.println("6. Cancelar Reserva");
            System.out.println("7. Salir");
            System.out.print("Ingresa opcion: ");
            opcion = entradaEnteroSegura(sc);

            switch(opcion) {
                case 1 -> mostrarPromociones();
                case 2 -> gestionarEntrada(sc);
                case 3 -> resumenVentas();
                case 4 -> gestionarReservas(sc);
                case 5 -> mostrarIngresosTotales();
                case 6 -> gestionarCancelacion(sc);
                case 7 -> System.out.println("Gracias por su visita.");
                default -> System.out.println("Opción inválida.");
            }
        } while(opcion != 7);
        sc.close();
    }

    private void inicializarAsientos() {
        for(int i=0; i<FILAS.length; i++) {
            Arrays.fill(asientosDisponibles[i], true);
        }
    }

    private void mostrarPromociones() {
        System.out.println("--- Promociones Disponibles ---");
        for(char fila: FILAS) {
            double base = determinarPrecioBase(fila);
            System.out.printf("Fila %c: Precio base $%.0f%n", fila, base);
        }
        for(Promocion promo: promociones) {
            System.out.printf("\n%s (%.0f%%):%n", promo.getNombre(), promo.getTasa()*100);
            for(char fila: FILAS) {
                double precio = determinarPrecioBase(fila) * (1 - promo.getTasa());
                System.out.printf("  Fila %c -> $%.0f%n", fila, precio);
            }
        }
    }

    private void mostrarMapaAsientos() {
        System.out.println("\nMapa de Asientos (disponible=[ ], ocupado=[X]):");
        System.out.printf("%4s","");
        for(int n=1; n<=ASIENTOS_POR_FILA; n++) System.out.printf("%4d", n);
        System.out.println();
        for(int i=0; i<FILAS.length; i++) {
            System.out.printf("%-4s", FILAS[i]+":");
            for(int j=0; j<ASIENTOS_POR_FILA; j++) {
                System.out.print(asientosDisponibles[i][j]?" [ ]":" [X]");
            }
            System.out.println();
        }
    }

    private void gestionarEntrada(Scanner sc) {
        if(idsVenta.size() >= CAPACIDAD) {
            System.out.println("No quedan asientos disponibles.");
            return;
        }

        int modo;
        do{
            System.out.print("Desea 1=Comprar o 2=Reservar? ");
            modo = entradaEnteroSegura(sc);
        } while(modo!=1 && modo!=2);
        boolean reserva = (modo==2);

        mostrarMapaAsientos();
        sc.nextLine(); // limpiar buffer

        String nombre;
        while(true) {
            System.out.print("Ingrese nombre del cliente: ");
            nombre = sc.nextLine().trim();
            if(nombre.matches("[A-Za-zÑñáéíóúÁÉÍÓÚ ]+")) break;
            System.out.println("Nombre inválido. Use solo letras y espacios.");
        }

        int idCliente;
        while(true) {
            System.out.print("Ingrese ID de cliente (número): ");
            String in = sc.nextLine();
            if(in.matches("\\d+")) {
                idCliente = Integer.parseInt(in);
                break;
            }
            System.out.println("ID inválido. Use solo números.");
        }

        int filaIdx, asientoIdx;
        String cod;
        while(true) {
            System.out.print("Seleccione asiento (A1-C10): ");
            cod = sc.nextLine().toUpperCase();
            if(!cod.matches("[A-C]([1-9]|10)")) {
                System.out.println("Formato inválido.");
                continue;
            }
            filaIdx = cod.charAt(0)-'A';
            asientoIdx = Integer.parseInt(cod.substring(1)) - 1;
            if(!asientosDisponibles[filaIdx][asientoIdx]) {
                System.out.println("Asiento no disponible.");
                continue;
            }
            asientosDisponibles[filaIdx][asientoIdx] = false;
            break;
        }

        double base = determinarPrecioBase(cod.charAt(0));
        int idVenta = ThreadLocalRandom.current().nextInt(10000,100000);

        idsVenta.add(idVenta);
        etiquetasAsiento.add(cod);
        clienteIds.add(idCliente);
        clienteNombres.add(nombre);
        esReserva.add(reserva);

        if(!reserva) {
            System.out.print("Promoción 0=Ninguna,1=Estudiante,2=Tercera Edad: ");
            int p = entradaEnteroSegura(sc);
            double tasa = p==1?promociones.get(0).getTasa():p==2?promociones.get(1).getTasa():0;
            double precioFinal = base * (1-tasa);
            preciosFinales.add(precioFinal);
            totalIngresos += precioFinal;
            System.out.printf("Entrada vendida! ID Venta: %d, Cliente: %s, Asiento: %s, Pago: $%.0f%n",
                              idVenta, nombre, cod, precioFinal);
            System.out.println("Compra realizada con éxito.");
        } else {
            preciosFinales.add(0.0);
            System.out.printf("Entrada reservada! ID Venta: %d, Cliente: %s, Asiento: %s%n",
                              idVenta, nombre, cod);
            System.out.println("Reserva realizada con éxito.");
        }
    }

    private void resumenVentas() {
        System.out.println("\n--- Resumen de Ventas ---");
        for(int i=0; i<idsVenta.size(); i++) {
            if(!esReserva.get(i)) {
                double base = determinarPrecioBase(etiquetasAsiento.get(i).charAt(0));
                System.out.printf("ID Venta %d: Cliente %s, Asiento %s, Base $%.0f, Final $%.0f%n",
                    idsVenta.get(i), clienteNombres.get(i), etiquetasAsiento.get(i),
                    base, preciosFinales.get(i));
            }
        }
    }

    private void gestionarReservas(Scanner sc) {
        System.out.println("\n--- Reservas Actuales ---");
        boolean hay=false;
        for(int i=0; i<idsVenta.size(); i++) {
            if(esReserva.get(i)) {
                System.out.printf("Reserva ID %d: Cliente %d, Asiento %s%n",
                    idsVenta.get(i), clienteIds.get(i), etiquetasAsiento.get(i));
                hay = true;
            }
        }
        if(!hay) { System.out.println("No hay reservas."); return; }

        System.out.print("¿Desea comprar una reserva? 1=Sí, 2=No: ");
        if(entradaEnteroSegura(sc) != 1) return;
        System.out.print("Ingrese ID Venda de la reserva: ");
        int id = entradaEnteroSegura(sc);

        for(int i=0; i<idsVenta.size(); i++) {
            if(idsVenta.get(i)==id && esReserva.get(i)) {
                System.out.print("Promoción 0=Ninguna,1=Estudiante,2=Tercera Edad: ");
                int p = entradaEnteroSegura(sc);
                double tasa = p==1?promociones.get(0).getTasa():p==2?promociones.get(1).getTasa():0;
                double basePrecio = determinarPrecioBase(etiquetasAsiento.get(i).charAt(0));
                double finalP = basePrecio * (1-tasa);
                preciosFinales.set(i, finalP);
                totalIngresos += finalP;
                esReserva.set(i, false);
                System.out.printf("Reserva ID %d comprada con éxito! Pago: $%.0f%n", id, finalP);
                return;
            }
        }
        System.out.println("No se encontró reserva con ese ID.");
    }

    private void gestionarCancelacion(Scanner sc) {
        System.out.print("Ingrese ID Venta de la reserva a cancelar: ");
        int id = entradaEnteroSegura(sc);
        for(int i=0; i<idsVenta.size(); i++) {
            if(idsVenta.get(i)==id && esReserva.get(i)) {
                char fila = etiquetasAsiento.get(i).charAt(0);
                int fIdx = fila - 'A';
                int aIdx = Integer.parseInt(etiquetasAsiento.get(i).substring(1)) - 1;
                asientosDisponibles[fIdx][aIdx] = true;
                esReserva.set(i, false);
                System.out.printf("Reserva ID %d cancelada exitosamente.%n", id);
                return;
            }
        }
        System.out.println("No se encontró reserva con ese ID.");
    }

    private void mostrarIngresosTotales() {
        System.out.printf("\nIngresos Totales: $%.0f%n", totalIngresos);
    }

    private int entradaEnteroSegura(Scanner sc) {
        while(!sc.hasNextInt()) {
            System.out.print("Número inválido: ");
            sc.next();
        }
        return sc.nextInt();
    }

    private double determinarPrecioBase(char fila) {
        return switch(fila) {
            case 'A' -> 23200;
            case 'B' -> 16400;
            default  -> 9600;
        };
    }

    // Clase Promoción
    private static class Promocion {
        private final String nombre;
        private final double tasa;
        public Promocion(String nombre, double tasa) {
            this.nombre = nombre;
            this.tasa = tasa;
        }
        public String getNombre() { return nombre; }
        public double getTasa() { return tasa; }
    }
}
