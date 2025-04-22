import java.util.ArrayList;
import java.util.Scanner;
import java.util.Timer;
import java.util.TimerTask;

public class Exp2_S6_Diego_Fernandez {

    static final String NOMBRE_TEATRO = "Teatro Moro";
    static final int CAPACIDAD_SALA = 100;
    static final int PRECIO_UNITARIO = 6500;
    static int totalEntradasVendidas = 0;
    static int totalReservas = 0;
    static int totalIngresos = 0;

    static ArrayList<Entrada> entradas = new ArrayList<>();

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        int opcion;

        do {
            System.out.println("=== (MENU) - TEATRO MORO ====");
            System.out.println("________________________________________________");
            System.out.println("1. Reservar entradas /asiento");
            System.out.println("2. Comprar entradas Reservadas/NoReservadas");
            System.out.println("3. Modificar un asiento reservado existente");
            System.out.println("4. Imprimir compras realizadas (boletas)");
            System.out.println("5. Salir de la tienda ");
            System.out.println("________________________________________________");
            System.out.print("Seleccione una opcion: ");
            opcion = scanner.nextInt(); 
            System.out.println("");// debug aqui veo el menu menu principal

            switch (opcion) {
                case 1 -> reservarEntradas(scanner);
                case 2 -> comprarEntradas(scanner);
                case 3 -> modificarVenta(scanner);
                case 4 -> imprimirBoletas();
                case 5 -> System.out.println(" Gracias por Visitar  Teatro Moro.");
                default -> System.out.println("Opcion invalida.");
            }
        } while (opcion != 5);
    }

    static void reservarEntradas(Scanner scanner) {
        int disponibles = CAPACIDAD_SALA - entradas.size();
        System.out.println("_________//////________________________________");
        System.out.println("Solo  hay (" + disponibles + ") cupos disponibles para reservar.");
        System.out.println("_________//////________________________________");
        if (disponibles == 0) {
            System.out.println("No quedan cupos disponibles para  reservar.");
            return;
        }

        System.out.print("Cuantos cupos/entradas desea reservar?: ");
        int cantidad = scanner.nextInt();

        if (cantidad > disponibles) {
            System.out.println("Solo hay   " + disponibles + " entradas disponibles. Reduzca su cantidad.");
            return;
        }

        for (int i = 0; i < cantidad; i++) {
            System.out.print("Ingrese numero del asiento que desea reservar: ");
            int asiento = scanner.nextInt();
            System.out.println();// debug de usuario  ingresando numero de asiento que quiere reservar
            if (asientoOcupado(asiento) || asientoFueraDeRango(asiento)) {
                System.out.println("asiento no disponible o fuera de cupo.");
            } else {
                Entrada nueva = new Entrada(asiento, "reservada", PRECIO_UNITARIO);
                entradas.add(nueva);
                totalReservas++;
                System.out.println("[DEBUG] La Reserva ha sido creada."); // debug de reserva agregada al sistema

                Timer timer = new Timer();
                TimerTask tareaExpiracion = new TimerTask() {
                    @Override
                    public void run() {
                        if (nueva.getEstado().equals("reservada")) {
                            entradas.remove(nueva);
                            totalReservas--;
                            System.out.println("[DEBUG] La reserva del asiento " + nueva.getAsiento() + " ha expirado despues de 2 minutos."); // debug Expiracion de time
                        }
                    }
                };
                timer.schedule(tareaExpiracion, 2 * 60 * 1000);
                System.out.println("Tiene 2 minutos para comprar su reserva, de lo contrario sera cancelada.");
            }
        }
    }

    static void comprarEntradas(Scanner scanner) {
        System.out.print("Desea comprar desde una reserva existente? *escribir la letra * (s/n): ");
        char resp = scanner.next().charAt(0);

        if (resp == 's' || resp == 'S') {
            System.out.print("Ingrese el numero de asiento que ya ha reservado: ");
            int asiento = scanner.nextInt();
            for (Entrada e : entradas) {
                if (e.getAsiento() == asiento && e.getEstado().equals("reservada")) {
                    System.out.println("");// debug de encontrar nuev reserva para convertir en compra
                    e.setEstado("vendida");
                    totalEntradasVendidas++;
                    totalReservas--;
                    totalIngresos += e.getPrecio();
                    System.out.println("[DEBUG] La Reserva se ha convertido en compra :)"); // debug de  reserva convertida en compra
                    return;
                }
            }
            System.out.println("La Reserva no se ha encontrado.");
        } else {
            int disponibles = CAPACIDAD_SALA - entradas.size();
            if (disponibles == 0) {
                System.out.println("No hay cupos disponibles para comprar.");
                return;
            }
            System.out.println("________________________________________________");
            System.out.println("Actualmente hay " + disponibles + " cupos/asientos disponibles para comprar.");
            System.out.println("________________________________________________");
            System.out.print("Cuantas entradas desea comprar?: ");
            int cantidad = scanner.nextInt();

            if (cantidad > disponibles) {
                System.out.println("Solo hay " + disponibles + " entradas disponibles. Reduzca la cantidad.");
                return;
            }

            for (int i = 0; i < cantidad; i++) {
                System.out.print("Ingrese numero de asiento: ");
                int asiento = scanner.nextInt();
                System.out.println("");// debug de  usuario ingresando numero de asiento para compra directa
                if (asientoOcupado(asiento) || asientoFueraDeRango(asiento)) {
                    System.out.println("Asiento no disponible o fuera de rango.");
                } else {
                    entradas.add(new Entrada(asiento, "vendida", PRECIO_UNITARIO));
                    totalEntradasVendidas++;
                    totalIngresos += PRECIO_UNITARIO;
                    System.out.println("[DEBUG] Compra  directa registrada.");
                    System.out.println("");// debug de compra realizada
                }
            }
        }
    }

    static void modificarVenta(Scanner scanner) {
        System.out.print("Ingrese numero del asiento reservado que desea modificar: ");
        int asiento = scanner.nextInt();
        for (Entrada e : entradas) {
            if (e.getAsiento() == asiento && e.getEstado().equals("reservada")) {
                System.out.println("");// debug  Modificando una reserva existente
                System.out.print("Ingrese nuevo numero de asiento: ");
                int nuevoAsiento = scanner.nextInt();
                if (asientoOcupado(nuevoAsiento) || asientoFueraDeRango(nuevoAsiento)) {
                    System.out.println("Error El nuevo asiento no esta disponible.");
                } else {
                    e.setAsiento(nuevoAsiento);
                    System.out.println("[DEBUG] Asiento reservado modificado.");
                }
                return;
            }
        }
        System.out.println("Error No se encontro una reserva con ese asiento.");
    }

    static void imprimirBoletas() {
        System.out.println("///////////////////////////////////////////////////////");
        System.out.println("///// BOLETA/////");
        for (Entrada e : entradas) {
            if (e.getEstado().equals("vendida")) {
                System.out.println("");// debug  Generando boleta
                System.out.println("==============================================");
                System.out.println("==============================================");
                System.out.println("Teatro: " + NOMBRE_TEATRO);
                System.out.println("Entrada numero: " + entradas.indexOf(e));
                System.out.println("Asiento/s: " + e.getAsiento());
                System.out.println("Precio:  $" + e.getPrecio());
                System.out.println("--------------------");
                System.out.println("[DEBUG] Boleta generada para el Asiento: " + e.getAsiento());
            }
        }
        System.out.println("___________________________________________________");
        System.out.println("Total entradas vendidas: " + totalEntradasVendidas);
        System.out.println("Costo Total: $" + totalIngresos);
        System.out.println("///////////////////////////////////////////////////////");
    }

    static boolean asientoOcupado(int asiento) {
        System.out.println("");// debug Verificando si el asiento ya esta ocupado
        for (Entrada e : entradas) {
            if (e.getAsiento() == asiento) {
                return true;
            }
        }
        return false;
    }

    static boolean asientoFueraDeRango(int asiento) {
        System.out.println("");// debug validando rango de asiento
        return asiento < 1 || asiento > CAPACIDAD_SALA;
    }

    static class Entrada {
        private int asiento;
        private String estado;
        private final int precio;

        public Entrada(int asiento, String estado, int precio) {
            this.asiento = asiento;
            this.estado = estado;
            this.precio = precio;
            System.out.println("");// debug Constructor de Entrada llamado
        }

        public int getAsiento() {
            return asiento;
        }

        public void setAsiento(int asiento) {
            this.asiento = asiento;
        }

        public String getEstado() {
            return estado;
        }

        public void setEstado(String estado) {
            this.estado = estado;
        }

        public int getPrecio() {
            return precio;
        }
    }
}
