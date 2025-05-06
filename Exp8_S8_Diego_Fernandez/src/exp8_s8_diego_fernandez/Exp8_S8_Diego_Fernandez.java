package exp8_s8_diego_fernandez;
//ho
import java.util.*;
import java.util.concurrent.ThreadLocalRandom;

public class Exp8_S8_Diego_Fernandez {
    // Sólo filas A, B, C 
    private static final char[] FILAS = {'A','B','C'};
    private static final int ASIENTOS_POR_FILA = 10;
    private static final int CAPACIDAD = FILAS.length * ASIENTOS_POR_FILA;

    // Estado de asientos
    private boolean[][] asientosDisponibles = new boolean[FILAS.length][ASIENTOS_POR_FILA];

    // Datos de transacciones
    private int[] idsVenta = new int[CAPACIDAD];
    private String[] etiquetasAsiento = new String[CAPACIDAD];
    private int[] clienteIds = new int[CAPACIDAD];
    private String[] clienteNombres = new String[CAPACIDAD];
    private double[] preciosFinales = new double[CAPACIDAD];
    private boolean[] esReserva = new boolean[CAPACIDAD];
    private int contadorVentas = 0;
    private double totalIngresos = 0;

    //  Promociones
    private static final String[] promoNombres = {"Estudiante","Tercera Edad"};
    private static final double[] promoTasas = {0.10,0.15};

    public static void main(String[] args) {
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
            System.out.println("6. Cancelar Reserva (ID de Venta)");
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
                default -> System.out.println("Opcion invalida.");
            }
        } while(opcion!=7);
        sc.close();
    }

    private void inicializarAsientos() {
        for(int i=0;i<FILAS.length;i++)
            Arrays.fill(asientosDisponibles[i], true);
    }

    private void mostrarPromociones() {
        System.out.println("--- Promociones Disponibles ---");
        for(char fila: FILAS) {
            double base = determinarPrecioBase(fila);
            System.out.printf("Fila %c: Precio base $%.0f%n", fila, base);
        }
        for(int i=0;i<promoNombres.length;i++){
            System.out.printf("%n%s (%.0f%%):%n",promoNombres[i],promoTasas[i]*100);
            for(char fila:FILAS){
                double precio = determinarPrecioBase(fila)*(1-promoTasas[i]);
                System.out.printf("  Fila %c -> $%.0f%n", fila, precio);
            }
        }
    }

    private void mostrarMapaAsientos() {
        System.out.println("\nMapa de Asientos (disponible=[ ], ocupado=[X]):");
        System.out.printf("%4s", "");
        for(int n=1;n<=ASIENTOS_POR_FILA;n++) System.out.printf("%4d",n);
        System.out.println();
        for(int i=0;i<FILAS.length;i++){
            System.out.printf("%-4s",FILAS[i]+":");
            for(int j=0;j<ASIENTOS_POR_FILA;j++){
                System.out.print(asientosDisponibles[i][j]?" [ ]":" [X]");
            }
            System.out.println();
        }
    }

    private void gestionarEntrada(Scanner sc) {
        if(contadorVentas>=CAPACIDAD){
            System.out.println("No quedan asientos disponibles."); return;
        }
        int modo;
        do{
            System.out.print("Desea 1=Comprar o 2=Reservar? ");
            modo=entradaEnteroSegura(sc);
        }while(modo!=1 && modo!=2);
        boolean reserva=(modo==2);

        mostrarMapaAsientos();
        sc.nextLine();

        String nombre;
        while(true){
            System.out.print("Ingrese nombre del cliente: ");
            nombre=sc.nextLine().trim();
            if(nombre.matches("[A-Za-zÑñáéíóúÁÉÍÓÚ ]+")) break;
            System.out.println("Nombre invalido. Use solo letras y espacios.");
        }

        int idCliente;
        while(true){
            System.out.print("Ingrese ID de cliente (numero): ");
            String in=sc.nextLine();
            if(in.matches("\\d+")){idCliente=Integer.parseInt(in);break;}
            System.out.println("ID invalido. Use solo numeros.");
        }
        clienteNombres[contadorVentas]=nombre;
        clienteIds[contadorVentas]=idCliente;

        int fIdx,aIdx;
        while(true){
            System.out.print("Seleccione asiento (A1-C10): ");
            String cod=sc.nextLine().toUpperCase();
            if(!cod.matches("[A-C]([1-9]|10)")){System.out.println("Formato invalido.");continue;}
            char f=cod.charAt(0); int num=Integer.parseInt(cod.substring(1));
            fIdx=f-'A'; aIdx=num-1;
            if(!asientosDisponibles[fIdx][aIdx]){System.out.println("Asiento no disponible.");continue;}
            asientosDisponibles[fIdx][aIdx]=false;
            etiquetasAsiento[contadorVentas]=cod;
            break;
        }

        double base=determinarPrecioBase(etiquetasAsiento[contadorVentas].charAt(0));
        int idVenta=ThreadLocalRandom.current().nextInt(10000,100000);
        idsVenta[contadorVentas]=idVenta;
        esReserva[contadorVentas]=reserva;

        if(!reserva){
            System.out.print("Promocion 0=Ninguna,1=Estudiante,2=Tercera Edad: ");
            int p=entradaEnteroSegura(sc);
            double t=p==1?promoTasas[0]:p==2?promoTasas[1]:0;
            double finalP=base*(1-t);
            preciosFinales[contadorVentas]=finalP;
            totalIngresos+=finalP;
            System.out.printf("Entrada vendida! ID Venta: %d, Cliente: %s, Asiento: %s, Pago: $%.0f%n",
                idVenta,nombre,etiquetasAsiento[contadorVentas],finalP);
            System.out.println("Compra  realizada con  exito.");
        } else {
            preciosFinales[contadorVentas]=0;
            System.out.printf("Entrada reservada! ID Venta: %d, Cliente: %s, Asiento: %s%n",
                idVenta,nombre,etiquetasAsiento[contadorVentas]);
            System.out.println("Reserva realizada con exito.");
        }
        contadorVentas++;
    }

    private void resumenVentas(){
        System.out.println("\n--- Resumen de Ventas ---");
        for(int i=0;i<contadorVentas;i++){
            if(!esReserva[i]){
                double b=determinarPrecioBase(etiquetasAsiento[i].charAt(0));
                System.out.printf("ID Venta %d: Cliente %s, Asiento %s, Base $%.0f, Final $%.0f%n",
                    idsVenta[i],clienteNombres[i],etiquetasAsiento[i],b,preciosFinales[i]);
            }
        }
    }

    private void gestionarReservas(Scanner sc){
        System.out.println("\n--- Reservas Actuales ---");
        boolean hay=false;
        for(int i=0;i<contadorVentas;i++) if(esReserva[i]){
            System.out.printf("Reserva ID %d: Cliente %d, Asiento %s%n",
                idsVenta[i],clienteIds[i],etiquetasAsiento[i]); hay=true;
        }
        if(!hay){ System.out.println("No hay reservas."); return; }
        System.out.print("Desea comprar una reserva? 1=Si, 2=No: ");
        if(entradaEnteroSegura(sc)!=1) return;
        System.out.print("Ingrese ID Venta de la reserva: ");
        int id=entradaEnteroSegura(sc);
        for(int i=0;i<contadorVentas;i++) if(idsVenta[i]==id && esReserva[i]){
            System.out.print("Promocion 0=Ninguna,1=Estudiante,2=Tercera Edad: "); int p=entradaEnteroSegura(sc);
            double t=p==1?promoTasas[0]:p==2?promoTasas[1]:0;
            double b=determinarPrecioBase(etiquetasAsiento[i].charAt(0));
            double f=b*(1-t); preciosFinales[i]=f; totalIngresos+=f; esReserva[i]=false;
            System.out.printf("Reserva ID %d comprada con éxito! Pago: $%.0f%n",id,f);
            return;
        }
        System.out.println("No se encontró reserva con ese ID.");
    }

    private void gestionarCancelacion(Scanner sc){
        System.out.print("Ingrese ID Venta de la reserva a cancelar: ");
        int id = entradaEnteroSegura(sc);
        for(int i=0;i<contadorVentas;i++) if(idsVenta[i]==id && esReserva[i]){
            char f=etiquetasAsiento[i].charAt(0); int r=f-'A';
            int a=Integer.parseInt(etiquetasAsiento[i].substring(1))-1;
            asientosDisponibles[r][a]=true; esReserva[i]=false;
            System.out.printf("Reserva ID %d cancelada exitosamente.%n",id);
            return;
        }
        System.out.println("No se encontró reserva con ese ID.");
    }

    private void mostrarIngresosTotales(){
        System.out.printf("\nIngresos Totales: $%.0f%n",totalIngresos);
    }

    private int entradaEnteroSegura(Scanner sc){
        while(!sc.hasNextInt()){ System.out.print("Numero invalido: "); sc.next(); }
        return sc.nextInt();
    }

    private double determinarPrecioBase(char fila){
        return switch(fila){ case 'A'->23200; case 'B'->16400; default->9600; };
    }
}