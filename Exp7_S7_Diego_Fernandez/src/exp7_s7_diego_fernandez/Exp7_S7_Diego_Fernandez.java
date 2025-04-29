package exp7_s7_diego_fernandez;

import java.util.ArrayList;
import java.util.Scanner;

public class Exp7_S7_Diego_Fernandez {
    
    private final ArrayList<String> ubicaciones = new ArrayList<>();
    private final ArrayList<Double> preciosBase = new ArrayList<>();
    private final ArrayList<Double> preciosFinales = new ArrayList<>();
    private final ArrayList<Double> descuentos = new ArrayList<>();

    
    private static double totalIngresos = 0;
    private static int cantEntradas = 0;
    private static final int CAPACIDAD = 100;

    public static void main(String[] args) {
        Scanner sc = new Scanner(System.in);
        Exp7_S7_Diego_Fernandez app = new Exp7_S7_Diego_Fernandez();
        int opcion;

        do {
            System.out.println("\n                //////===== Teatro Moro =====//////");
            System.out.println("1. Informacion. Precios/Descuentos");
            System.out.println("2. Comprar Entrada");
            System.out.println("3. Ver Resumen");
            System.out.println("4. Imprimir TODAS las boletas compradas");
            System.out.println("5. Mostrar ingresos totales");
            System.out.println("6. Salir");
            System.out.print("Ingresa opcion: ");
            opcion = sc.nextInt();

            switch (opcion) {
                case 1 -> app.mostrarTipos();
                case 2 -> app.vender(sc);
                case 3 -> app.resumen();
                case 4 -> app.boletas();
                case 5 -> app.ingresos();
                case 6 -> System.out.println("Gracias por su compra");
                default -> System.out.println("Opcion invalida, intenta otra vez.");
            }
        } while (opcion != 6);
        sc.close();
    }

    private void mostrarTipos() {
        System.out.println("--- Tipos de entradas ---");
        int baseVIP = 23200, basePlatea = 16400, baseBalcon = 9600;
        int vipEst = (int)(baseVIP * 0.9);
        int vipAnc = (int)(baseVIP * 0.85);
        int plEst = (int)(basePlatea * 0.9);
        int plAnc = (int)(basePlatea * 0.85);
        int baEst = (int)(baseBalcon * 0.9);
        int baAnc = (int)(baseBalcon * 0.85);
        System.out.println("\nATENCION: Solo se aplicara un descuento a la vez.");
        System.out.println("VIP    - Precio Base: $" + baseVIP + ", estudiante 10%: $" + vipEst + ", tercera edad 15%: $" + vipAnc);
        System.out.println("Platea - Precio Base: $" + basePlatea + ", estudiante 10%: $" + plEst + ", tercera edad 15%: $" + plAnc);
        System.out.println("Balcon - Precio Base: $" + baseBalcon + ", estudiante 10%: $" + baEst + ", tercera edad 15%: $" + baAnc);
    }

    private void vender(Scanner sc) {
        if (cantEntradas >= CAPACIDAD) {
            System.out.println("Ya no quedan espacios disponibles.");
            return;
        }

        System.out.print("Elige ubicacion (1=VIP, 2=Platea, 3=Balcon): ");
        int tipo = sc.nextInt();
        sc.nextLine();

        double precioBase;
        String zona;
        switch (tipo) {
            case 1 -> {
                precioBase = 23200;
                zona = "VIP";
            }
            case 2 -> {
                precioBase = 16400;
                zona = "Platea";
            }
            case 3 -> {
                precioBase = 9600;
                zona = "Balcon";
            }
            default -> {
                System.out.println("Numero de zona invalido.");
                return;
            }
        }

        boolean esEst = false;
        boolean esAnc = false;
        System.out.print("Es estudiante? (s/n): ");
        char respuesta = sc.next().toLowerCase().charAt(0);
        if (respuesta == 's') {
            esEst = true;
        } else if (respuesta != 'n') {
            System.out.println("Error: ingresa 's' o 'n'. Asumo que la respuesta es negativa no es estudiante.");
        }

        
        if (!esEst) {
            System.out.print("Es tercera edad? (s/n): ");
            respuesta = sc.next().toLowerCase().charAt(0);
            if (respuesta == 's') {
                esAnc = true;
            } else if (respuesta != 'n') {
                System.out.println("Error: ingresa 's' o 'n'. Asumo que la respuesta es negativa no es tercera edad.");
            }
        }

        double descRatio = esEst ? 0.1 : esAnc ? 0.15 : 0;
        double montoDesc = precioBase * descRatio;
        double finalPago = precioBase - montoDesc;

        
        ubicaciones.add(zona);
        preciosBase.add(precioBase);
        preciosFinales.add(finalPago);
        descuentos.add(montoDesc);

        cantEntradas++;
        totalIngresos += finalPago;

        System.out.println("\nEntrada vendida! Pago: $" + String.format("%.0f", finalPago));
    }

    private void resumen() {
        if (ubicaciones.isEmpty()) {
            System.out.println("No hay ventas aun.");
            return;
        }
        System.out.println("\n--- Resumen de las ventas ---");
        for (int i = 0; i < ubicaciones.size(); i++) {
            System.out.println((i + 1) + ". " + ubicaciones.get(i)
                + ": $" + String.format("%.0f", preciosFinales.get(i))
                + " (desc: $" + String.format("%.0f", descuentos.get(i)) + ")");
        }
    }

    private void boletas() {
        if (ubicaciones.isEmpty()) {
            System.out.println("No hay nada que imprimir.");
            return;
        }
        System.out.println("--- BOLETAS DE LA SESION ---");
        for (int i = 0; i < ubicaciones.size(); i++) {
            System.out.println("Boleta N " + (i + 1));
            System.out.println("Ubicacion: " + ubicaciones.get(i));
            System.out.println("Costo Base: $" + String.format("%.0f", preciosBase.get(i)));
            System.out.println("Descuento aplicado: $" + String.format("%.0f", descuentos.get(i)));
            System.out.println("Costo Final: $" + String.format("%.0f", preciosFinales.get(i)));
            System.out.println("-----------------------------");
        }
        System.out.println("Gracias por su compra");
    }

    private void ingresos() {
        System.out.println("\nIngresos Totales: $" + String.format("%.0f", totalIngresos));
    }
}