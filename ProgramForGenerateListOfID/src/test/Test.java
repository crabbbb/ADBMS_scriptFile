/*
 * Click nbfs://nbhost/SystemFileSystem/Templates/Licenses/license-default.txt to change this license
 * Click nbfs://nbhost/SystemFileSystem/Templates/Classes/Main.java to edit this template
 */
package test;

/**
 *
 * @author LENOVO
 */
public class Test {

    /**
     * @param args the command line arguments
     */
    public static void main(String[] args) {
        int countTtlLoop = 0;
        // generate ID use
        for (int i = 181; i <= 244; i++) {
            System.out.print(String.format("FS%04d", i) + ", ");
            countTtlLoop += 1;

            // break down
            if (countTtlLoop == 50) {
                System.out.println("\n");
            }
        }

        System.out.println("\n" + countTtlLoop);
    }

}
