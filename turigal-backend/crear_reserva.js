// turigal-backend/crear_reserva.js

const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

async function main() {
  const EMAIL_USUARIO = "test@turigal.com"; // Asegúrate que este es tu email de login
  
  console.log(`Buscando al usuario ${EMAIL_USUARIO}...`);

  // 1. BUSCAMOS TU USUARIO REAL EN LA DB
  const usuario = await prisma.user.findUnique({
    where: { email: EMAIL_USUARIO }
  });

  if (!usuario) {
    console.error("ERROR: No existe el usuario en la base de datos.");
    console.error("   Primero regístrate en la App o haz Login.");
    return;
  }

  console.log(`Usuario encontrado (ID: ${usuario.id}). Conectando reserva...`);

  // 2. BORRAR DATOS ANTIGUOS (Orden Importante)
    console.log("Limpiando datos anteriores...");
    
    // Primero borramos el Checkin asociado (si existe)
    try {
        await prisma.checkin.delete({
            where: { reservationId: "TURISGAL-TEST" }
        });
    } catch (e) { /* Ignoramos si no existe */ }
    
  // 2. BORRAR LA RESERVA ANTIGUA (Limpieza)
  try {
    await prisma.reservation.delete({
      where: { reservationId: "TURISGAL-TEST" }
    });
    console.log("Reserva anterior eliminada.");
  } catch (e) {
    console.log("ℹCreando nueva reserva...");
  }

  // 3. CREAR LA RESERVA VINCULADA AL USUARIO
  try {
    const nuevaReserva = await prisma.reservation.create({
      data: {
        reservationId: "TURISGAL-TEST",
        propertyName: "Apartamento Vistas al Mar", 
        guestName: usuario.name || "Cliente Turisgal", // Usamos tu nombre real
        bookingEmail: usuario.email, 
        
        checkInDate: new Date(), 
        checkOutDate: new Date(new Date().setDate(new Date().getDate() + 3)),
        
        status: "PENDIENTE", 
        guests: 4,
        totalPrice: 450.00,

        // 👇 ¡ESTA ES LA CLAVE! 👇
        // Conectamos la reserva con tu ID de usuario.
        // Ahora la App sabrá que es TUYA.
        user: {
            connect: { id: usuario.id }
        }
      }
    });

    console.log("---------------------------------------");
    console.log("¡RESERVA VINCULADA CON ÉXITO!");
    console.log("Dueño:", usuario.email);
    console.log("Alojamiento:", nuevaReserva.propertyName);
    console.log("Código QR:", nuevaReserva.reservationId);
    console.log("---------------------------------------");

  } catch (error) {
    console.error("Error al crear:", error);
  } finally {
    await prisma.$disconnect();
  }
}

main();